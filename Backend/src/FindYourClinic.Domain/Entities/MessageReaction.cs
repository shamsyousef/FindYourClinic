using FindYourClinic.Domain.Common;

namespace FindYourClinic.Domain.Entities;

public class MessageReaction : AuditableEntity
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid MessageId { get; set; }
    public Guid UserId { get; set; }
    public string Emoji { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public ChatMessage Message { get; set; } = default!;
    public ApplicationUser User { get; set; } = default!;
}
