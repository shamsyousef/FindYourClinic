using FindYourClinic.Domain.Common;

namespace FindYourClinic.Domain.Entities;

public class DoctorWallet : AuditableEntity
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid DoctorProfileId { get; set; }
    public decimal TotalEarnings { get; set; }
    public decimal PendingBalance { get; set; }
    public decimal WithdrawnAmount { get; set; }

    public DoctorProfile DoctorProfile { get; set; } = default!;
}
