using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Enums;

namespace FindYourClinic.Domain.Entities;

public class DoctorProfile : AuditableEntity
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; }
    public Guid SpecialtyId { get; set; }
    public string? ClinicName { get; set; }
    public string? ClinicAddress { get; set; }
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }
    public decimal ConsultationFee { get; set; }
    public int ExperienceYears { get; set; }
    public string? Bio { get; set; }
    public DoctorStatus Status { get; set; } = DoctorStatus.PendingReview;
    public DateTime? ReviewedAt { get; set; }
    public Guid? ReviewedByAdminId { get; set; }
    public string? RejectionReason { get; set; }

    public ApplicationUser User { get; set; } = default!;
    public Specialty Specialty { get; set; } = default!;
    public ICollection<DoctorDocument> Documents { get; set; } = new List<DoctorDocument>();
    public ICollection<DoctorAvailability> Availabilities { get; set; } = new List<DoctorAvailability>();
    public ICollection<Appointment> Appointments { get; set; } = new List<Appointment>();
    public ICollection<DoctorReview> Reviews { get; set; } = new List<DoctorReview>();
}
