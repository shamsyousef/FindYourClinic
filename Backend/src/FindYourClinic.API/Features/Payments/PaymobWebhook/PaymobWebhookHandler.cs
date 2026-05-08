using System.Text.Json.Serialization;
using FindYourClinic.API.Services;
using FindYourClinic.Domain.Constants;
using FindYourClinic.Domain.Entities;
using FindYourClinic.Domain.Enums;
using FindYourClinic.Domain.Exceptions;
using FindYourClinic.Domain.Services;
using FindYourClinic.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace FindYourClinic.API.Features.Payments.PaymobWebhook;

public class PaymobWebhookHandler
{
    private readonly ApplicationDbContext _dbContext;
    private readonly IPaymobService _paymobService;
    private readonly INotificationService _notificationService;
    private readonly IConfiguration _configuration;
    private readonly ILogger<PaymobWebhookHandler> _logger;

    public PaymobWebhookHandler(
        ApplicationDbContext dbContext,
        IPaymobService paymobService,
        INotificationService notificationService,
        IConfiguration configuration,
        ILogger<PaymobWebhookHandler> logger)
    {
        _dbContext = dbContext;
        _paymobService = paymobService;
        _notificationService = notificationService;
        _configuration = configuration;
        _logger = logger;
    }

    public async Task HandleAsync(PaymobCallbackData data, string hmac, CancellationToken cancellationToken)
    {
        // Verify HMAC — skip if HmacSecret is not configured (dev/test only).
        var hmacSecret = _configuration["Paymob:HmacSecret"];
        if (!string.IsNullOrEmpty(hmacSecret))
        {
            if (!_paymobService.VerifyHmac(data.ToHmacDictionary(), hmac))
            {
                _logger.LogWarning("Invalid HMAC for Paymob webhook. Order: {OrderId}", data.OrderId);
                throw new UnauthorizedException("Invalid HMAC signature.");
            }
        }
        else
        {
            _logger.LogWarning("Paymob:HmacSecret is not configured — skipping HMAC verification (dev/test only).");
        }

        var paymobOrderId = data.OrderId;

        // Idempotency — already finalized
        var alreadyPaid = await _dbContext.Transactions
            .AsNoTracking()
            .AnyAsync(x => x.PaymobOrderId == paymobOrderId && x.Status == PaymentStatus.Paid, cancellationToken);
        if (alreadyPaid)
        {
            _logger.LogInformation("Paymob webhook already processed for order {OrderId}. Skipping.", paymobOrderId);
            return;
        }

        if (!data.Success)
        {
            _logger.LogWarning("Paymob payment failed for order {OrderId}.", paymobOrderId);
            return;
        }

        // Look up the pending intent persisted at InitiatePayment time.
        var intent = await _dbContext.PendingBookingIntents
            .FirstOrDefaultAsync(x => x.PaymobOrderId == paymobOrderId, cancellationToken);
        if (intent is null)
        {
            _logger.LogWarning("Paymob webhook received for unknown order {OrderId}. Skipping.", paymobOrderId);
            return;
        }
        if (intent.IsConsumed)
        {
            _logger.LogInformation("Pending intent {OrderId} already consumed.", paymobOrderId);
            return;
        }

        // If the slot was taken in the meantime, mark intent consumed but log loudly —
        // a refund is owed to the patient.
        var slotTaken = await _dbContext.Appointments.AnyAsync(
            x => x.DoctorProfileId == intent.DoctorProfileId &&
                 x.ScheduledAt == intent.ScheduledAt &&
                 x.Status != AppointmentStatus.Cancelled,
            cancellationToken);
        if (slotTaken)
        {
            _logger.LogError(
                "Paymob payment succeeded for order {OrderId} but slot is no longer available. Refund required for patient {PatientId}.",
                paymobOrderId, intent.PatientId);
            intent.IsConsumed = true;
            intent.ConsumedAt = DateTime.UtcNow;
            await _dbContext.SaveChangesAsync(cancellationToken);
            return;
        }

        var appointment = new Appointment
        {
            PatientId = intent.PatientId,
            DoctorProfileId = intent.DoctorProfileId,
            ScheduledAt = intent.ScheduledAt,
            LocationName = intent.LocationName,
            Status = AppointmentStatus.Confirmed,
            PaymentStatus = PaymentStatus.Paid,
            PaymentMethod = intent.PaymentMethod,
            PaymobOrderId = paymobOrderId,
            PaymobTransactionId = data.TransactionId,
            AmountPaid = intent.Amount
        };
        _dbContext.Appointments.Add(appointment);

        var transaction = new Transaction
        {
            AppointmentId = appointment.Id,
            PatientId = intent.PatientId,
            DoctorProfileId = intent.DoctorProfileId,
            Amount = intent.Amount,
            PlatformFee = intent.PlatformFee,
            DoctorEarnings = intent.DoctorEarnings,
            PaymobOrderId = paymobOrderId,
            PaymobTransactionId = data.TransactionId,
            PaymentMethod = intent.PaymentMethod,
            Status = PaymentStatus.Paid,
            CompletedAt = DateTime.UtcNow
        };
        _dbContext.Transactions.Add(transaction);

        var wallet = await _dbContext.DoctorWallets
            .FirstOrDefaultAsync(x => x.DoctorProfileId == intent.DoctorProfileId, cancellationToken);
        if (wallet is null)
        {
            wallet = new DoctorWallet
            {
                DoctorProfileId = intent.DoctorProfileId,
                TotalEarnings = intent.DoctorEarnings,
                PendingBalance = intent.DoctorEarnings
            };
            _dbContext.DoctorWallets.Add(wallet);
        }
        else
        {
            wallet.TotalEarnings += intent.DoctorEarnings;
            wallet.PendingBalance += intent.DoctorEarnings;
        }

        intent.IsConsumed = true;
        intent.ConsumedAt = DateTime.UtcNow;

        await _dbContext.SaveChangesAsync(cancellationToken);

        _logger.LogInformation(
            "Paymob webhook finalized appointment {AppointmentId} for order {OrderId}.",
            appointment.Id, paymobOrderId);

        // Notify doctor — same shape as ConfirmPayment.
        var doctorProfile = await _dbContext.DoctorProfiles
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.Id == intent.DoctorProfileId, cancellationToken);
        if (doctorProfile is not null)
        {
            await _notificationService.SendToUserAsync(
                doctorProfile.UserId,
                "New paid appointment",
                $"A patient booked and paid for an appointment on {appointment.ScheduledAt:MMM dd 'at' hh:mm tt}.",
                new Dictionary<string, string>
                {
                    ["type"] = NotificationTypes.AppointmentBooked,
                    ["referenceId"] = appointment.Id.ToString()
                },
                cancellationToken);
        }
    }
}

/// <summary>
/// Paymob sends webhook as POST JSON: { "type": "TRANSACTION", "obj": { ... } }
/// HMAC is sent as ?hmac= query parameter.
/// </summary>
public class PaymobCallbackData
{
    [JsonPropertyName("type")]
    public string Type { get; set; } = string.Empty;

    [JsonPropertyName("obj")]
    public PaymobTransactionObj Obj { get; set; } = new();

    // Convenience accessors used by the handler
    public string OrderId => Obj.Order?.Id.ToString() ?? string.Empty;
    public string TransactionId => Obj.Id.ToString();
    public bool Success => Obj.Success;

    public Dictionary<string, string> ToHmacDictionary() => new()
    {
        ["amount_cents"] = Obj.AmountCents.ToString(),
        ["created_at"] = Obj.CreatedAt,
        ["currency"] = Obj.Currency,
        ["error_occured"] = Obj.ErrorOccurred.ToString().ToLowerInvariant(),
        ["has_parent_transaction"] = Obj.HasParentTransaction.ToString().ToLowerInvariant(),
        ["id"] = Obj.Id.ToString(),
        ["integration_id"] = Obj.IntegrationId.ToString(),
        ["is_3d_secure"] = Obj.Is3DSecure.ToString().ToLowerInvariant(),
        ["is_auth"] = Obj.IsAuth.ToString().ToLowerInvariant(),
        ["is_capture"] = Obj.IsCapture.ToString().ToLowerInvariant(),
        ["is_refunded"] = Obj.IsRefunded.ToString().ToLowerInvariant(),
        ["is_standalone_payment"] = Obj.IsStandalonePayment.ToString().ToLowerInvariant(),
        ["is_voided"] = Obj.IsVoided.ToString().ToLowerInvariant(),
        ["order.id"] = Obj.Order?.Id.ToString() ?? string.Empty,
        ["owner"] = Obj.Owner.ToString(),
        ["pending"] = Obj.Pending.ToString().ToLowerInvariant(),
        ["source_data.pan"] = Obj.SourceData?.Pan ?? string.Empty,
        ["source_data.sub_type"] = Obj.SourceData?.SubType ?? string.Empty,
        ["source_data.type"] = Obj.SourceData?.Type ?? string.Empty,
        ["success"] = Obj.Success.ToString().ToLowerInvariant()
    };
}

public class PaymobTransactionObj
{
    [JsonPropertyName("id")]
    public long Id { get; set; }

    [JsonPropertyName("success")]
    public bool Success { get; set; }

    [JsonPropertyName("pending")]
    public bool Pending { get; set; }

    [JsonPropertyName("amount_cents")]
    public int AmountCents { get; set; }

    [JsonPropertyName("currency")]
    public string Currency { get; set; } = "EGP";

    [JsonPropertyName("created_at")]
    public string CreatedAt { get; set; } = string.Empty;

    [JsonPropertyName("error_occured")]
    public bool ErrorOccurred { get; set; }

    [JsonPropertyName("has_parent_transaction")]
    public bool HasParentTransaction { get; set; }

    [JsonPropertyName("is_3d_secure")]
    public bool Is3DSecure { get; set; }

    [JsonPropertyName("is_auth")]
    public bool IsAuth { get; set; }

    [JsonPropertyName("is_capture")]
    public bool IsCapture { get; set; }

    [JsonPropertyName("is_refunded")]
    public bool IsRefunded { get; set; }

    [JsonPropertyName("is_standalone_payment")]
    public bool IsStandalonePayment { get; set; }

    [JsonPropertyName("is_voided")]
    public bool IsVoided { get; set; }

    [JsonPropertyName("integration_id")]
    public long IntegrationId { get; set; }

    [JsonPropertyName("owner")]
    public long Owner { get; set; }

    [JsonPropertyName("order")]
    public PaymobOrderRef? Order { get; set; }

    [JsonPropertyName("source_data")]
    public PaymobSourceData? SourceData { get; set; }
}

public class PaymobOrderRef
{
    [JsonPropertyName("id")]
    public long Id { get; set; }
}

public class PaymobSourceData
{
    [JsonPropertyName("type")]
    public string Type { get; set; } = string.Empty;

    [JsonPropertyName("sub_type")]
    public string SubType { get; set; } = string.Empty;

    [JsonPropertyName("pan")]
    public string Pan { get; set; } = string.Empty;
}
