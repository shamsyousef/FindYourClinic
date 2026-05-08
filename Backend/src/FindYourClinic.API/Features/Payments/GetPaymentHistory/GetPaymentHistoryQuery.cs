using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Enums;
using MediatR;

namespace FindYourClinic.API.Controllers;

public class GetPaymentHistoryQuery : IRequest<ApiResponse<List<TransactionDto>>>
{
    public Guid UserId { get; set; }
    public UserRole Role { get; set; }
}

public record TransactionDto(
    Guid Id,
    Guid AppointmentId,
    decimal Amount,
    decimal PlatformFee,
    decimal DoctorEarnings,
    string PaymentMethod,
    string Status,
    DateTime CreatedAt,
    DateTime? CompletedAt,
    string? DoctorName,
    string? PatientName);
