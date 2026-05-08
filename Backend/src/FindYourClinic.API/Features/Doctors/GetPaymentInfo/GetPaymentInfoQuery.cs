using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Enums;
using MediatR;

namespace FindYourClinic.API.Features.Doctors.GetPaymentInfo;

public class GetPaymentInfoQuery : IRequest<ApiResponse<DoctorPaymentInfoDto>>
{
    public Guid UserId { get; set; }
    public UserRole Role { get; set; }
}

public sealed record DoctorPaymentInfoDto(
    string PayoutMethod,
    string? WalletProvider,
    string? WalletPhoneNumber,
    string? BankName,
    string? AccountHolderName,
    string? AccountNumber,
    string? IBAN);
