using FindYourClinic.Domain.Common;

namespace FindYourClinic.Domain.Entities;

public class DoctorReview : AuditableEntity
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid DoctorProfileId { get; set; }
    public Guid PatientId { get; set; }
    public int Rating { get; set; }
    public string? Comment { get; set; }
    public DoctorProfile DoctorProfile { get; set; } = default!;
    public ApplicationUser Patient { get; set; } = default!;
}
