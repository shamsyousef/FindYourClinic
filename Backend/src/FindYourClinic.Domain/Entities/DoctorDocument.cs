using FindYourClinic.Domain.Common;

namespace FindYourClinic.Domain.Entities;

public class DoctorDocument : AuditableEntity
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid DoctorProfileId { get; set; }
    public string DocumentType { get; set; } = string.Empty;
    public string FileUrl { get; set; } = string.Empty;
    public string CloudinaryPublicId { get; set; } = string.Empty;
    public DateTime UploadedAt { get; set; } = DateTime.UtcNow;

    public DoctorProfile DoctorProfile { get; set; } = default!;
}
