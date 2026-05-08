using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Enums;

namespace FindYourClinic.Domain.Entities;

public class DoctorPaymentInfo : AuditableEntity
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid DoctorProfileId { get; set; }
    public PayoutMethod PayoutMethod { get; set; }

    // Wallet fields (populated when PayoutMethod == Wallet)
    public WalletProvider? WalletProvider { get; set; }
    public string? WalletPhoneNumber { get; set; }

    // Bank fields (populated when PayoutMethod == Bank)
    public string? BankName { get; set; }
    public string? AccountHolderName { get; set; }
    public string? AccountNumber { get; set; }
    public string? IBAN { get; set; }

    public DoctorProfile DoctorProfile { get; set; } = default!;
}
