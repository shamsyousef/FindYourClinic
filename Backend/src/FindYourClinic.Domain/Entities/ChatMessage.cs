using FindYourClinic.Domain.Common;

namespace FindYourClinic.Domain.Entities;

public class ChatMessage : AuditableEntity
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid ConversationId { get; set; }
    public Guid SenderId { get; set; }
    public string Content { get; set; } = string.Empty;
    public DateTime SentAt { get; set; } = DateTime.UtcNow;
    public bool IsRead { get; set; }

    public Conversation Conversation { get; set; } = default!;
    public ApplicationUser Sender { get; set; } = default!;
}
