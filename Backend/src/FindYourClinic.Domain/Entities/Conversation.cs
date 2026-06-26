using FindYourClinic.Domain.Common;

namespace FindYourClinic.Domain.Entities;

public class Conversation : AuditableEntity
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid PatientId { get; set; }
    public Guid DoctorId { get; set; }
    public DateTime LastMessageAt { get; set; } = DateTime.UtcNow;

    public ApplicationUser Patient { get; set; } = default!;
    public ApplicationUser Doctor { get; set; } = default!;
    public ICollection<ChatMessage> Messages { get; set; } = new List<ChatMessage>();
}
