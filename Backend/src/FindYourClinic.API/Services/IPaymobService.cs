namespace FindYourClinic.API.Services;

public interface IPaymobService
{
    Task<string> AuthenticateAsync();
    Task<string> CreateOrderAsync(string authToken, int amountCents, string merchantOrderId);
    Task<string> GeneratePaymentKeyAsync(string authToken, string orderId, int amountCents, int integrationId, PaymobBillingData billingData);
    /// <summary>Calls Paymob's wallet pay endpoint and returns the redirect_url the user must visit to complete OTP.</summary>
    Task<string> InitiateWalletPayAsync(string paymentKey, string walletPhone);
    bool VerifyHmac(Dictionary<string, string> transactionData, string receivedHmac);
}

public record PaymobBillingData(
    string FirstName,
    string LastName,
    string Email,
    string Phone);
