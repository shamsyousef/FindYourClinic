using FindYourClinic.Domain.Common;

namespace FindYourClinic.Domain.Entities;

public class Specialty : AuditableEntity
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string Name { get; set; } = string.Empty;
    public string? IconUrl { get; set; }
    public bool IsActive { get; set; } = true;

    public ICollection<DoctorProfile> DoctorProfiles { get; set; } = new List<DoctorProfile>();
}
