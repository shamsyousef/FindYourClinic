using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Enums;
using MediatR;

namespace FindYourClinic.API.Features.Payments.InitiatePayment;

public class InitiatePaymentCommand : IRequest<ApiResponse<InitiatePaymentResult>>
{
    public Guid UserId { get; set; }
    public UserRole Role { get; set; }
    public Guid DoctorProfileId { get; set; }
    public DateTime ScheduledAt { get; set; }
    public string? LocationName { get; set; }
    public PaymentMethod PaymentMethod { get; set; }
    /// <summary>Required when PaymentMethod == Wallet. The customer's mobile wallet phone number.</summary>
    public string? WalletPhone { get; set; }
}

public record InitiatePaymentResult(
    Guid? AppointmentId,
    string? PaymentKey,
    string? PaymobOrderId,
    int? IframeId,
    decimal Amount,
    decimal PlatformFee,
    decimal Total,
    bool RequiresPayment,
    string? RedirectUrl = null);
