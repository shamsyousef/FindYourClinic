using Ardalis.Result;
using FindYourClinic.Domain.Enums;
using MediatR;

namespace FindYourClinic.API.Features.Doctors.SavePaymentInfo;

public class SavePaymentInfoCommand : IRequest<Result>
{
    public Guid UserId { get; set; }
    public UserRole Role { get; set; }

    public PayoutMethod PayoutMethod { get; set; }

    // Wallet
    public WalletProvider? WalletProvider { get; set; }
    public string? WalletPhoneNumber { get; set; }

    // Bank
    public string? BankName { get; set; }
    public string? AccountHolderName { get; set; }
    public string? AccountNumber { get; set; }
    public string? IBAN { get; set; }
}
