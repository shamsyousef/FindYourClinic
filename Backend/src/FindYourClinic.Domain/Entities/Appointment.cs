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
    public ApplicationUser Patient { get; set; } = default!;
    public DoctorProfile DoctorProfile { get; set; } = default!;
}
