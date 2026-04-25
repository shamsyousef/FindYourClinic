using FindYourClinic.Domain.Common;
using FindYourClinic.Domain.Enums;

namespace FindYourClinic.Domain.Entities;

public class ApplicationUser : AuditableIdentityUser
{
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public UserRole Role { get; set; }
    public string? ProfileImageUrl { get; set; }
    public string? CloudinaryPublicId { get; set; }
    public string? FcmToken { get; set; }
    public DateTime? FcmTokenUpdatedAt { get; set; }
    public bool IsActive { get; set; } = true;

    public DoctorProfile? DoctorProfile { get; set; }
    public ICollection<RefreshToken> RefreshTokens { get; set; } = new List<RefreshToken>();
    public ICollection<Appointment> PatientAppointments { get; set; } = new List<Appointment>();
    public ICollection<HealthRecord> HealthRecords { get; set; } = new List<HealthRecord>();
    public ICollection<Conversation> PatientConversations { get; set; } = new List<Conversation>();
    public ICollection<Conversation> DoctorConversations { get; set; } = new List<Conversation>();
    public ICollection<ChatMessage> SentMessages { get; set; } = new List<ChatMessage>();
    public ICollection<DoctorReview> DoctorReviews { get; set; } = new List<DoctorReview>();
    public ICollection<Notification> Notifications { get; set; } = new List<Notification>();
}
