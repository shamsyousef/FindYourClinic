using Ardalis.Result;
using FindYourClinic.API.Features.Appointments.Shared;
using FindYourClinic.Domain.Enums;
using MediatR;

namespace FindYourClinic.API.Features.Payments.ConfirmPayment;

public class ConfirmPaymentCommand : IRequest<Result<AppointmentDto>>
{
    public Guid UserId { get; set; }
    public UserRole Role { get; set; }
    public Guid DoctorProfileId { get; set; }
    public DateTime ScheduledAt { get; set; }
    public string? LocationName { get; set; }
    public string PaymobOrderId { get; set; } = string.Empty;
    public string PaymobTransactionId { get; set; } = string.Empty;
    public PaymentMethod PaymentMethod { get; set; }
}
