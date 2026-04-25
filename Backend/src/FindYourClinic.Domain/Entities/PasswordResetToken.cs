using FindYourClinic.Domain.Common;

namespace FindYourClinic.Domain.Entities;

public class PasswordResetToken : AuditableEntity
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; }
    public string Token { get; set; } = string.Empty;
    public DateTime ExpiresAt { get; set; }
    public bool IsUsed { get; set; }
    public ApplicationUser User { get; set; } = default!;
}
