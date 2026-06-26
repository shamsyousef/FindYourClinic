using FindYourClinic.Domain.Common;

namespace FindYourClinic.Domain.Entities;

public class DoctorAvailability : AuditableEntity
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid DoctorProfileId { get; set; }
    public DayOfWeek DayOfWeek { get; set; }
    public TimeSpan StartTime { get; set; }
    public TimeSpan EndTime { get; set; }
    public bool IsActive { get; set; } = true;

    public DoctorProfile DoctorProfile { get; set; } = default!;
}
