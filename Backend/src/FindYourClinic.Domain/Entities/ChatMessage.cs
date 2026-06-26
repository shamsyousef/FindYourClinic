using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Enums;

namespace FindYourClinic.Domain.Entities;

public class ChatMessage : AuditableEntity
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid ConversationId { get; set; }
    public Guid SenderId { get; set; }
    public string Content { get; set; } = string.Empty;
    public DateTime SentAt { get; set; } = DateTime.UtcNow;
    public bool IsRead { get; set; }

    public ChatMessageType Type { get; set; } = ChatMessageType.Text;
    public string? MediaUrl { get; set; }
    public string? MediaThumbnailUrl { get; set; }
    public int? MediaDurationSeconds { get; set; }

    public Guid? ReplyToMessageId { get; set; }
    public ChatMessage? ReplyToMessage { get; set; }

    public Conversation Conversation { get; set; } = default!;
    public ApplicationUser Sender { get; set; } = default!;
    public ICollection<MessageReaction> Reactions { get; set; } = new List<MessageReaction>();
}
