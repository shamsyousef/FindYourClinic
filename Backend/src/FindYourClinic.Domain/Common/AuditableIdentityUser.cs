using Microsoft.AspNetCore.Identity;

namespace FindYourClinic.Domain.Common;

public abstract class AuditableIdentityUser : IdentityUser<Guid>, IAuditableEntity
{
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public Guid? CreatedBy { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public Guid? UpdatedBy { get; set; }
}
