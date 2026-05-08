using System.Security.Cryptography;
using System.Text;
using System.Text.Json;

namespace FindYourClinic.API.Services;

public class PaymobService : IPaymobService
{
    private const string BaseUrl = "https://accept.paymob.com/api";

    // HMAC concatenation order per Paymob docs
    private static readonly string[] HmacFields =
    [
        "amount_cents", "created_at", "currency", "error_occured",
        "has_parent_transaction", "id", "integration_id",
        "is_3d_secure", "is_auth", "is_capture", "is_refunded",
        "is_standalone_payment", "is_voided", "order.id",
        "owner", "pending", "source_data.pan", "source_data.sub_type",
        "source_data.type", "success"
    ];

    private readonly IHttpClientFactory _httpClientFactory;
    private readonly IConfiguration _configuration;
    private readonly ILogger<PaymobService> _logger;

    // Auth tokens are valid for 1 hour per Paymob docs; we cache for 50 minutes
    // to leave a safety margin and avoid the ~1-20 second auth round-trip on every
    // payment initiation.
    private static readonly SemaphoreSlim _authLock = new(1, 1);
    private static string? _cachedToken;
    private static DateTime _cachedTokenExpiresAt = DateTime.MinValue;
    private static readonly TimeSpan _tokenLifetime = TimeSpan.FromMinutes(50);

    public PaymobService(IHttpClientFactory httpClientFactory, IConfiguration configuration, ILogger<PaymobService> logger)
    {
        _httpClientFactory = httpClientFactory;
        _configuration = configuration;
        _logger = logger;
    }

    public async Task<string> AuthenticateAsync()
    {
        // Fast path: token still valid.
        if (_cachedToken is not null && DateTime.UtcNow < _cachedTokenExpiresAt)
        {
            return _cachedToken;
        }

        await _authLock.WaitAsync();
        try
        {
            // Re-check after acquiring lock (another caller may have refreshed it).
            if (_cachedToken is not null && DateTime.UtcNow < _cachedTokenExpiresAt)
            {
                return _cachedToken;
            }

            var apiKey = _configuration["Paymob:ApiKey"]
                ?? throw new InvalidOperationException("Paymob:ApiKey is not configured.");

            var client = _httpClientFactory.CreateClient();
            var body = new { api_key = apiKey };
            var json = JsonSerializer.Serialize(body);
            using var content = new StringContent(json, Encoding.UTF8, "application/json");

            var response = await client.PostAsync($"{BaseUrl}/auth/tokens", content);
            response.EnsureSuccessStatusCode();

            using var stream = await response.Content.ReadAsStreamAsync();
            using var doc = await JsonDocument.ParseAsync(stream);

            var token = doc.RootElement.GetProperty("token").GetString()
                ?? throw new InvalidOperationException("Paymob auth returned null token.");

            _cachedToken = token;
            _cachedTokenExpiresAt = DateTime.UtcNow.Add(_tokenLifetime);

            _logger.LogInformation("Paymob authentication successful (token cached until {ExpiresAt:o}).", _cachedTokenExpiresAt);
            return token;
        }
        finally
        {
            _authLock.Release();
        }
    }

    public async Task<string> CreateOrderAsync(string authToken, int amountCents, string merchantOrderId)
    {
        var client = _httpClientFactory.CreateClient();
        var body = new
        {
            auth_token = authToken,
            delivery_needed = false,
            amount_cents = amountCents,
            currency = "EGP",
            merchant_order_id = merchantOrderId,
            items = Array.Empty<object>()
        };

        var json = JsonSerializer.Serialize(body);
        using var content = new StringContent(json, Encoding.UTF8, "application/json");

        var response = await client.PostAsync($"{BaseUrl}/ecommerce/orders", content);
        response.EnsureSuccessStatusCode();

        using var stream = await response.Content.ReadAsStreamAsync();
        using var doc = await JsonDocument.ParseAsync(stream);

        var orderId = doc.RootElement.GetProperty("id").GetInt64().ToString();
        _logger.LogInformation("Paymob order created: {OrderId}", orderId);
        return orderId;
    }

    public async Task<string> GeneratePaymentKeyAsync(string authToken, string orderId, int amountCents, int integrationId, PaymobBillingData billingData)
    {
        var client = _httpClientFactory.CreateClient();
        var body = new
        {
            auth_token = authToken,
            amount_cents = amountCents,
            expiration = 3600,
            order_id = orderId,
            currency = "EGP",
            integration_id = integrationId,
            billing_data = new
            {
                first_name = billingData.FirstName,
                last_name = billingData.LastName,
                email = billingData.Email,
                phone_number = billingData.Phone,
                apartment = "NA",
                floor = "NA",
                street = "NA",
                building = "NA",
                shipping_method = "NA",
                postal_code = "NA",
                city = "NA",
                country = "EG",
                state = "NA"
            }
        };

        var json = JsonSerializer.Serialize(body);
        using var content = new StringContent(json, Encoding.UTF8, "application/json");

        var response = await client.PostAsync($"{BaseUrl}/acceptance/payment_keys", content);
        response.EnsureSuccessStatusCode();

        using var stream = await response.Content.ReadAsStreamAsync();
        using var doc = await JsonDocument.ParseAsync(stream);

        var paymentKey = doc.RootElement.GetProperty("token").GetString()
            ?? throw new InvalidOperationException("Paymob returned null payment key.");

        _logger.LogInformation("Paymob payment key generated for order {OrderId}", orderId);
        return paymentKey;
    }

    public async Task<string> InitiateWalletPayAsync(string paymentKey, string walletPhone)
    {
        var client = _httpClientFactory.CreateClient();
        var body = new
        {
            source = new { identifier = walletPhone, subtype = "WALLET" },
            payment_token = paymentKey
        };
        var json = JsonSerializer.Serialize(body);
        using var content = new StringContent(json, Encoding.UTF8, "application/json");

        var response = await client.PostAsync($"{BaseUrl}/acceptance/payments/pay", content);
        response.EnsureSuccessStatusCode();

        using var stream = await response.Content.ReadAsStreamAsync();
        using var doc = await JsonDocument.ParseAsync(stream);

        var redirectUrl = doc.RootElement.GetProperty("redirect_url").GetString()
            ?? throw new InvalidOperationException("Paymob wallet pay returned no redirect_url.");

        _logger.LogInformation("Paymob wallet pay initiated, redirect: {Url}", redirectUrl);
        return redirectUrl;
    }

    public bool VerifyHmac(Dictionary<string, string> transactionData, string receivedHmac)
    {
        var hmacSecret = _configuration["Paymob:HmacSecret"]
            ?? throw new InvalidOperationException("Paymob:HmacSecret is not configured.");

        var concatenated = new StringBuilder();
        foreach (var field in HmacFields)
        {
            if (transactionData.TryGetValue(field, out var value))
            {
                concatenated.Append(value);
            }
        }

        using var hmac = new HMACSHA512(Encoding.UTF8.GetBytes(hmacSecret));
        var hash = hmac.ComputeHash(Encoding.UTF8.GetBytes(concatenated.ToString()));
        var computed = BitConverter.ToString(hash).Replace("-", "").ToLowerInvariant();

        return string.Equals(computed, receivedHmac, StringComparison.OrdinalIgnoreCase);
    }
}
