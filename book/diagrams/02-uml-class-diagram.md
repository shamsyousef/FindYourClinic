# Figure 2 — UML Class Diagram

UML class diagram of the core domain model under
`Backend/src/FindYourClinic.Domain/Entities/`. The diagram emphasises the relationships
and a small subset of methods relevant to the domain rules (status transitions, wallet
operations). Identity infrastructure types and EF-Core internals are intentionally hidden.

```mermaid
classDiagram
    direction LR

    class ApplicationUser {
        +Guid Id
        +string Email
        +string FirstName
        +string LastName
        +UserRole Role
        +string PreferredLanguage
        +bool IsActive
        +ChangeProfile()
        +Deactivate()
    }

    class DoctorProfile {
        +Guid Id
        +Guid UserId
        +Guid SpecialtyId
        +string Biography
        +decimal ConsultationFee
        +ApprovalStatus ApprovalStatus
        +float AverageRating
        +Approve()
        +Reject(reason)
        +UpdateRating(newAvg)
    }

    class Specialty {
        +Guid Id
        +string Name
        +string IconUrl
    }

    class DoctorDocument {
        +Guid Id
        +DocumentType DocumentType
        +string Url
        +DocumentStatus Status
        +Review(status, comment)
    }

    class DoctorAvailability {
        +Guid Id
        +DayOfWeek DayOfWeek
        +TimeSpan StartTime
        +TimeSpan EndTime
        +int SlotDurationMinutes
        +GenerateSlots(date) Slot[]
    }

    class Appointment {
        +Guid Id
        +Guid PatientId
        +Guid DoctorProfileId
        +DateTime ScheduledStart
        +DateTime ScheduledEnd
        +AppointmentStatus Status
        +Confirm()
        +Complete()
        +Cancel(reason)
        +Reschedule(newStart)
    }

    class PendingBookingIntent {
        +Guid Id
        +Guid AppointmentId
        +string PaymentSessionId
        +DateTime ExpiresAt
        +bool IsExpired()
    }

    class Transaction {
        +Guid Id
        +decimal GrossAmount
        +decimal PlatformFee
        +decimal NetAmount
        +TransactionType Type
        +TransactionStatus Status
        +MarkSucceeded()
        +MarkFailed()
    }

    class DoctorWallet {
        +Guid Id
        +decimal AvailableBalance
        +decimal PendingBalance
        +decimal LifetimeEarnings
        +Credit(amount)
        +Debit(amount)
        +RequestPayout(amount)
    }

    class DoctorPaymentInfo {
        +Guid Id
        +string BankName
        +string AccountNumber
        +string MobileWalletNumber
    }

    class Conversation {
        +Guid Id
        +Guid PatientId
        +Guid DoctorProfileId
        +DateTime LastMessageAt
        +AddMessage(msg)
    }

    class ChatMessage {
        +Guid Id
        +Guid SenderId
        +string Content
        +MessageType MessageType
        +string AttachmentUrl
        +MessageStatus Status
        +MarkRead()
        +AddReaction(emoji)
    }

    class MessageReaction {
        +Guid Id
        +Guid UserId
        +string Emoji
    }

    class HealthRecord {
        +Guid Id
        +Guid PatientId
        +HealthRecordCategory Category
        +string Title
        +string Description
        +string AttachmentUrl
        +ShareWith(doctorId)
    }

    class DoctorReview {
        +Guid Id
        +int Rating
        +string Comment
        +ModerationStatus ModerationStatus
        +Approve()
        +Flag()
        +Remove()
    }

    class Notification {
        +Guid Id
        +Guid UserId
        +string Title
        +string Body
        +bool IsRead
        +MarkRead()
    }

    class AiChatMessage {
        +Guid Id
        +Guid UserId
        +AiMessageRole Role
        +string Content
        +DateTime CreatedAt
    }

    %% Enumerations
    class UserRole {
        <<enumeration>>
        Patient
        Doctor
        Admin
    }
    class ApprovalStatus {
        <<enumeration>>
        Pending
        Approved
        Rejected
    }
    class AppointmentStatus {
        <<enumeration>>
        Pending
        Confirmed
        Completed
        Cancelled
        Rescheduled
    }
    class MessageType {
        <<enumeration>>
        Text
        Voice
        Image
    }
    class HealthRecordCategory {
        <<enumeration>>
        Medication
        Allergy
        Diagnosis
        LabResult
        Vaccination
        Surgery
        FamilyHistory
        Note
    }

    %% Relationships
    ApplicationUser "1" --> "0..1" DoctorProfile : isA (Doctor)
    DoctorProfile   "1" --> "1"    Specialty
    DoctorProfile   "1" --> "*"    DoctorDocument
    DoctorProfile   "1" --> "*"    DoctorAvailability
    DoctorProfile   "1" --> "1"    DoctorWallet
    DoctorProfile   "1" --> "0..1" DoctorPaymentInfo

    ApplicationUser "1" --> "*"    Appointment        : asPatient
    DoctorProfile   "1" --> "*"    Appointment        : asDoctor
    Appointment     "1" --> "0..1" PendingBookingIntent
    Appointment     "1" --> "0..1" Transaction
    Appointment     "1" --> "0..1" DoctorReview
    Appointment     "1" --> "0..1" Conversation

    Conversation    "1" --> "*"    ChatMessage
    ChatMessage     "1" --> "*"    MessageReaction

    DoctorWallet    "1" --> "*"    Transaction

    ApplicationUser "1" --> "*"    HealthRecord
    ApplicationUser "1" --> "*"    Notification
    ApplicationUser "1" --> "*"    AiChatMessage
```
