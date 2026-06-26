using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Enums;

namespace FindYourClinic.Domain.Entities;

/// <summary>
/// Captures everything needed to create an Appointment + Transaction once Paymob
/// confirms a payment. Persisted at InitiatePayment time so that the webhook can
/// finalize the booking even if the mobile client never reaches ConfirmPayment.
/// </summary>
public class PendingBookingIntent : AuditableEntity
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string PaymobOrderId { get; set; } = string.Empty;
    public string MerchantOrderId { get; set; } = string.Empty;
    public Guid PatientId { get; set; }
    public Guid DoctorProfileId { get; set; }
    public DateTime ScheduledAt { get; set; }
    public string? LocationName { get; set; }
    public decimal Amount { get; set; }
    public decimal PlatformFee { get; set; }
    public decimal DoctorEarnings { get; set; }
    public PaymentMethod PaymentMethod { get; set; }
    public DateTime ExpiresAt { get; set; }
    public bool IsConsumed { get; set; }
    public DateTime? ConsumedAt { get; set; }
}
