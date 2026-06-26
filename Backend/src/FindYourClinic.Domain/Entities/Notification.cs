using FindYourClinic.Domain.Common;

namespace FindYourClinic.Domain.Entities;

public class Notification : AuditableEntity
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Body { get; set; } = string.Empty;
    public string? Type { get; set; }
    public string? ReferenceId { get; set; }
    public bool IsRead { get; set; }

    public ApplicationUser User { get; set; } = default!;
}
