# Figure 1 — Entity Relationship Diagram (ERD)

ERD of the SQL Server schema used by the Find Your Clinic backend. Every box is a real
EF Core entity / DbSet in `FindYourClinic.Infrastructure/Persistence/ApplicationDbContext.cs`.
Audit columns (`CreatedAt`, `UpdatedAt`, soft-delete flags) and Identity-internal columns
are omitted for readability.

```mermaid
erDiagram
    ApplicationUser ||--o| DoctorProfile           : "is a (if Doctor)"
    ApplicationUser ||--o{ HealthRecord            : owns
    ApplicationUser ||--o{ Notification            : receives
    ApplicationUser ||--o{ AiChatMessage           : authors
    ApplicationUser ||--o{ RefreshToken            : has
    ApplicationUser ||--o{ PasswordResetToken      : has
    ApplicationUser ||--o{ Appointment             : "books (as Patient)"
    ApplicationUser ||--o{ Conversation            : "participates (as Patient)"

    DoctorProfile   }o--|| Specialty               : "belongs to"
    DoctorProfile   ||--o{ DoctorDocument          : uploads
    DoctorProfile   ||--o{ DoctorAvailability      : publishes
    DoctorProfile   ||--o{ Appointment             : "receives (as Doctor)"
    DoctorProfile   ||--|| DoctorWallet            : owns
    DoctorProfile   ||--o| DoctorPaymentInfo       : "has payout method"
    DoctorProfile   ||--o{ Conversation            : "participates (as Doctor)"
    DoctorProfile   ||--o{ DoctorReview            : "is reviewed in"

    Appointment     ||--o| PendingBookingIntent    : "has pending intent"
    Appointment     ||--o| Transaction             : "paid by"
    Appointment     ||--o| DoctorReview            : "reviewed in"
    Appointment     ||--o| Conversation            : "unlocks"

    Conversation    ||--o{ ChatMessage             : contains
    ChatMessage     ||--o{ MessageReaction         : has

    DoctorWallet    ||--o{ Transaction             : "tracks"

    ApplicationUser {
        guid   Id PK
        string Email
        string PasswordHash
        string FirstName
        string LastName
        string Gender
        date   DateOfBirth
        string BloodType
        string Address
        string EmergencyContact
        string ProfileImageUrl
        string PreferredLanguage
        bool   IsActive
        enum   Role "Patient | Doctor | Admin"
    }

    DoctorProfile {
        guid   Id PK
        guid   UserId FK
        guid   SpecialtyId FK
        text   Biography
        money  ConsultationFee
        string ClinicAddress
        float  ClinicLatitude
        float  ClinicLongitude
        string Languages
        int    YearsOfExperience
        enum   ApprovalStatus "Pending | Approved | Rejected"
        string RejectionReason
        float  AverageRating
    }

    Specialty {
        guid   Id PK
        string Name
        string IconUrl
        string Description
    }

    DoctorDocument {
        guid   Id PK
        guid   DoctorProfileId FK
        enum   DocumentType "Identity | License | Practice"
        string Url
        enum   Status "Pending | Approved | Rejected"
        string Comments
    }

    DoctorAvailability {
        guid   Id PK
        guid   DoctorProfileId FK
        enum   DayOfWeek
        time   StartTime
        time   EndTime
        int    SlotDurationMinutes
    }

    Appointment {
        guid   Id PK
        guid   PatientId FK
        guid   DoctorProfileId FK
        datetime ScheduledStart
        datetime ScheduledEnd
        enum   Status "Pending | Confirmed | Completed | Cancelled | Rescheduled"
        text   Notes
    }

    PendingBookingIntent {
        guid   Id PK
        guid   AppointmentId FK
        string PaymentSessionId
        datetime ExpiresAt
    }

    Transaction {
        guid   Id PK
        guid   AppointmentId FK
        guid   DoctorWalletId FK
        money  GrossAmount
        money  PlatformFee
        money  NetAmount
        enum   Type "Payment | Refund | Payout"
        enum   Status "Pending | Succeeded | Failed"
        string GatewayReference
    }

    DoctorWallet {
        guid   Id PK
        guid   DoctorProfileId FK
        money  AvailableBalance
        money  PendingBalance
        money  LifetimeEarnings
    }

    DoctorPaymentInfo {
        guid   Id PK
        guid   DoctorProfileId FK
        string BankName
        string AccountNumber
        string MobileWalletNumber
    }

    Conversation {
        guid   Id PK
        guid   PatientId FK
        guid   DoctorProfileId FK
        datetime LastMessageAt
    }

    ChatMessage {
        guid   Id PK
        guid   ConversationId FK
        guid   SenderId FK
        text   Content
        enum   MessageType "Text | Voice | Image"
        string AttachmentUrl
        enum   Status "Sent | Delivered | Read"
        datetime SentAt
    }

    MessageReaction {
        guid   Id PK
        guid   ChatMessageId FK
        guid   UserId FK
        string Emoji
    }

    HealthRecord {
        guid   Id PK
        guid   PatientId FK
        guid   DoctorId FK "nullable"
        enum   Category "Medication | Allergy | Diagnosis | LabResult | Vaccination | Surgery | FamilyHistory | Note"
        string Title
        text   Description
        string AttachmentUrl
        datetime RecordedAt
    }

    DoctorReview {
        guid   Id PK
        guid   AppointmentId FK
        guid   PatientId FK
        guid   DoctorProfileId FK
        int    Rating "1..5"
        text   Comment
        enum   ModerationStatus "Pending | Approved | Flagged | Removed"
    }

    Notification {
        guid   Id PK
        guid   UserId FK
        string Title
        text   Body
        string DataPayload
        bool   IsRead
        datetime CreatedAt
    }

    AiChatMessage {
        guid   Id PK
        guid   UserId FK
        enum   Role "User | Assistant"
        text   Content
        datetime CreatedAt
    }

    RefreshToken {
        guid   Id PK
        guid   UserId FK
        string Token
        datetime ExpiresAt
        bool   Revoked
    }

    PasswordResetToken {
        guid   Id PK
        guid   UserId FK
        string Token
        datetime ExpiresAt
        bool   Used
    }
```
