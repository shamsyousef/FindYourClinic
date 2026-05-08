using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Enums;
using MediatR;

namespace FindYourClinic.API.Controllers;

public class GetDoctorEarningsQuery : IRequest<ApiResponse<DoctorEarningsDto>>
{
    public Guid UserId { get; set; }
    public UserRole Role { get; set; }
}

public record DoctorEarningsDto(
    decimal TotalEarnings,
    decimal PendingBalance,
    decimal WithdrawnAmount,
    int TotalTransactions);
