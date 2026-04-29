using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Enums;

namespace FindYourClinic.Domain.Entities;

public class HealthRecord : AuditableEntity
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid PatientId { get; set; }
    public string Title { get; set; } = string.Empty;
    public HealthRecordType Type { get; set; }
    public string? Value { get; set; }
    public string? Unit { get; set; }
    public DateTime RecordedAt { get; set; }
    public string? Notes { get; set; }

    public ApplicationUser Patient { get; set; } = default!;
}
