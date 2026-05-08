using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Enums;

namespace FindYourClinic.Domain.Entities;

public class Transaction : AuditableEntity
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid AppointmentId { get; set; }
    public Guid PatientId { get; set; }
    public Guid DoctorProfileId { get; set; }
    public decimal Amount { get; set; }
    public decimal PlatformFee { get; set; }
    public decimal DoctorEarnings { get; set; }
    public string? PaymobOrderId { get; set; }
    public string? PaymobTransactionId { get; set; }
    public PaymentMethod PaymentMethod { get; set; }
    public PaymentStatus Status { get; set; } = PaymentStatus.Pending;
    public DateTime? CompletedAt { get; set; }

    public Appointment Appointment { get; set; } = default!;
    public ApplicationUser Patient { get; set; } = default!;
    public DoctorProfile DoctorProfile { get; set; } = default!;
}
