using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Enums;

namespace FindYourClinic.Domain.Entities;

public class Appointment : AuditableEntity
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid PatientId { get; set; }
    public Guid DoctorProfileId { get; set; }
    public DateTime ScheduledAt { get; set; }
    public string? LocationName { get; set; }
    public AppointmentStatus Status { get; set; } = AppointmentStatus.Scheduled;
    public bool ReminderSent { get; set; }

    // Payment
    public PaymentStatus PaymentStatus { get; set; } = PaymentStatus.Unpaid;
    public PaymentMethod? PaymentMethod { get; set; }
    public string? PaymobOrderId { get; set; }
    public string? PaymobTransactionId { get; set; }
    public decimal? AmountPaid { get; set; }

    public ApplicationUser Patient { get; set; } = default!;
    public DoctorProfile DoctorProfile { get; set; } = default!;
    public Transaction? Transaction { get; set; }
}

