const {
  chapterTitle, h2, h3, h4, p, lead, bullet, numbered, pageBreak, note, kvTable, imagePlaceholder,
} = require("./helpers");

const chapter5 = () => [
  chapterTitle("Chapter 5: Design"),

  // ----------------------------------------------------------------------- //
  h2("5.1  Introduction"),
  lead("This chapter presents the design artefacts that anchored the implementation of Find Your Clinic. It begins with the database design (Entity Relationship Diagram and the structure of every major table), continues with the UML class diagram of the domain model, follows with the Use Case diagram of the three primary actors, then moves to the workflow diagrams of the most important journeys, and concludes with a tour of the UI/UX design of the mobile app."),

  // ----------------------------------------------------------------------- //
  h2("5.2  Database Design"),
  p("Find Your Clinic uses Microsoft SQL Server as the primary relational store, accessed from the .NET 10 backend through Entity Framework Core 10. The database design follows the patterns of clean relational modelling: every table has a single-column primary key (UUID), foreign keys are explicit, and many-to-many relations are expressed through join tables when needed. The DbContext that materialises this schema is ApplicationDbContext, located in the Infrastructure project and registered through the dependency-injection container."),

  h3("5.2.1  Entity Relationship Diagram"),
  p("The ERD below visualises the most important entities and their relationships. The diagram has been simplified for readability — auxiliary fields (timestamps, soft-delete flags, audit fields) are omitted, but they exist on every table."),

  ...imagePlaceholder("1", "Entity Relationship Diagram (ERD) of the Find Your Clinic domain", "≈ 12 cm tall — full-page diagram"),

  h3("5.2.2  Tables and Documents"),
  p("The major tables in the database are listed below. Each one corresponds to a C# entity in the Domain project and is exposed through a typed DbSet on ApplicationDbContext."),

  h4("ApplicationUsers"),
  p("Extends the ASP.NET Identity user table with healthcare-specific fields. Columns of interest include FirstName, LastName, Gender, DateOfBirth, BloodType, Address, EmergencyContact, ProfileImageUrl, PreferredLanguage, IsActive, and Role. Authentication-related columns (NormalizedEmail, PasswordHash, SecurityStamp) are managed by ASP.NET Identity."),

  h4("DoctorProfiles"),
  p("Stores the public profile of a doctor. Key columns include UserId (FK to ApplicationUsers), SpecialtyId (FK to Specialties), Biography, ConsultationFee, ClinicAddress, ClinicLatitude, ClinicLongitude, Languages, YearsOfExperience, ApprovalStatus, RejectionReason, and AverageRating."),

  h4("Specialties"),
  p("A curated catalogue of medical specialties (Cardiology, Pediatrics, Dermatology, …). Owned by administrators."),

  h4("DoctorDocuments"),
  p("Identity, license, and proof-of-practice documents uploaded by doctors during onboarding. Each row stores a DocumentType, Url, Status (Pending / Approved / Rejected), and Comments."),

  h4("DoctorAvailabilities"),
  p("Doctor-defined weekly availability windows. Each row stores DayOfWeek, StartTime, EndTime, and SlotDurationMinutes."),

  h4("Appointments"),
  p("The central booking entity. Stores PatientId, DoctorId, ScheduledStart, ScheduledEnd, Status (Pending / Confirmed / Completed / Cancelled / Rescheduled), Notes, and references to the payment record."),

  h4("Conversations and ChatMessages"),
  p("Each Conversation row binds a patient and a doctor and represents the chat between them after their first confirmed appointment. ChatMessages stores individual messages with ConversationId, SenderId, Content, MessageType (Text / Voice / Image), AttachmentUrl, and Status (Sent / Delivered / Read). A small MessageReactions table records emoji-style reactions per message."),

  h4("HealthRecords"),
  p("Patient health records by category. Stores PatientId, Category (Medication, Allergy, Diagnosis, …), Title, Description, AttachmentUrl, RecordedAt, and an optional DoctorId for entries written by treating doctors."),

  h4("DoctorReviews"),
  p("One review per completed appointment. Stores AppointmentId, PatientId, DoctorId, Rating, Comment, and ModerationStatus."),

  h4("Notifications"),
  p("In-app notification inbox. Stores UserId, Title, Body, DataPayload, IsRead, CreatedAt. Push delivery is performed through Firebase Cloud Messaging."),

  h4("AiChatMessages"),
  p("Per-user conversation history with the AI assistant. Stores UserId, Role (User / Assistant), Content, CreatedAt."),

  h4("Transactions, DoctorWallets, DoctorPaymentInfos, PendingBookingIntents"),
  p("The financial tables that together implement the payment workflow. Transactions records every payment, refund, and payout. DoctorWallets tracks per-doctor balances. DoctorPaymentInfos stores bank or mobile-wallet details used for payouts. PendingBookingIntents records short-lived booking intents waiting for payment confirmation."),

  h4("RefreshTokens and PasswordResetTokens"),
  p("Authentication support tables. RefreshTokens persist long-lived refresh tokens used to obtain new access tokens; PasswordResetTokens store one-time tokens for the password recovery flow."),

  // ----------------------------------------------------------------------- //
  h2("5.3  UML Class Diagram"),
  p("The UML class diagram complements the ERD by showing the domain model from the C# code perspective. Where the ERD focuses on data, the class diagram focuses on behaviour: entities, value objects, enums, and the relationships between them. All domain classes live in the FindYourClinic.Domain project and have no dependencies on Entity Framework, ASP.NET, or any other framework. This is the cornerstone of the clean-architecture approach: the domain is pure."),

  ...imagePlaceholder("2", "UML Class Diagram of the Find Your Clinic domain model", "≈ 12 cm tall — full-page diagram"),

  p("The diagram highlights the following core classes:"),

  bullet("ApplicationUser — the Identity-extended user with healthcare-specific properties."),
  bullet("DoctorProfile — the verified, public-facing profile of a doctor."),
  bullet("Specialty — a single medical specialty value object."),
  bullet("Appointment — a booking instance with status, schedule, and payment references."),
  bullet("DoctorAvailability — a weekly availability window."),
  bullet("Conversation and ChatMessage — chat entities."),
  bullet("HealthRecord — a patient health record entry."),
  bullet("DoctorReview — a rating + comment tied to a completed appointment."),
  bullet("Notification — an inbox entry."),
  bullet("Transaction, DoctorWallet, and DoctorPaymentInfo — financial entities."),
  bullet("AiChatMessage — a single turn in the AI conversation."),

  // ----------------------------------------------------------------------- //
  h2("5.4  Use Case Diagram"),
  p("The Use Case diagram captures the main interactions between the three actors of the system (Patient, Doctor, Administrator) and the platform. Each ellipse represents a top-level capability, and the lines connect actors to the capabilities they can perform. Some capabilities are shared by multiple actors (for example, both patients and doctors can chat), while others are exclusive (only admins can verify doctors, only patients can leave reviews)."),

  ...imagePlaceholder("3", "Use Case Diagram for Patient, Doctor, and Admin actors", "≈ 12 cm tall"),

  h3("5.4.1  Patient Use Cases"),
  bullet("Register / Sign in / Sign out."),
  bullet("Edit profile and preferences."),
  bullet("Search doctors by specialty, location, and rating."),
  bullet("View doctor profile and reviews."),
  bullet("Book / Reschedule / Cancel appointment."),
  bullet("Pay for consultation."),
  bullet("Chat with doctor."),
  bullet("Manage health records (create, update, delete, share)."),
  bullet("Use AI Health Assistant."),
  bullet("Leave a review after a completed appointment."),
  bullet("Receive and read notifications."),

  h3("5.4.2  Doctor Use Cases"),
  bullet("Register / Sign in / Sign out."),
  bullet("Upload identity, license, and proof-of-practice documents."),
  bullet("Edit profile, specialty, fee, biography, and clinic location."),
  bullet("Manage weekly availability."),
  bullet("View and manage appointments."),
  bullet("Chat with patients."),
  bullet("Create or update patient health records (with permission)."),
  bullet("View earnings and request payouts."),
  bullet("Receive and read notifications."),

  h3("5.4.3  Administrator Use Cases"),
  bullet("Sign in to the admin dashboard."),
  bullet("Review and approve / reject doctor applications."),
  bullet("Activate / deactivate user accounts."),
  bullet("Manage medical specialties (CRUD)."),
  bullet("Moderate doctor reviews."),
  bullet("Monitor financial dashboard and process payouts."),
  bullet("Look up health records for support and compliance scenarios."),

  // ----------------------------------------------------------------------- //
  h2("5.5  Workflow Diagrams"),
  p("Workflow diagrams describe the temporal flow of the most important user journeys. Each diagram shows how a user progresses through the system, when state changes happen, and what notifications are dispatched at each step. The four diagrams below cover the patient journey, the doctor journey, the admin journey, and the booking + payment sequence in detail."),

  h3("5.5.1  Patient Workflow"),
  ...imagePlaceholder("4", "Patient Workflow Diagram — discovery, booking, payment, chat, and follow-up"),

  p("The patient journey begins at the splash and onboarding screens, continues through sign-up or sign-in, and lands on the patient home screen. From there, the patient can either (a) start a doctor search, optionally consulting the AI assistant first to pick a specialty, or (b) jump directly to a known doctor through a bookmark or a deep link. After viewing the doctor's profile, the patient picks a time slot, confirms the booking, and is forwarded to the Paymob WebView for payment. Upon a successful webhook, the backend promotes the appointment from Pending to Confirmed, opens a chat conversation between the patient and the doctor, and dispatches a push notification to both sides. After the appointment is marked Completed by the doctor, the patient is invited to leave a review."),

  h3("5.5.2  Doctor Workflow"),
  ...imagePlaceholder("5", "Doctor Workflow Diagram — onboarding, availability, appointments, chat, payouts"),

  p("The doctor journey begins with sign-up and the onboarding wizard, including the upload of identity and licence documents. The doctor's account stays in the Pending Approval state until an administrator approves it. Once approved, the doctor lands on the doctor dashboard and configures their weekly availability. Incoming appointments appear in the inbox; the doctor confirms, completes, or cancels them. After a confirmed appointment, the chat opens automatically. The doctor's wallet accrues earnings from completed appointments and can be paid out on request."),

  h3("5.5.3  Admin Workflow"),
  ...imagePlaceholder("6", "Admin Workflow Diagram — verification, moderation, finance, support"),

  p("The administrator workflow is driven by a queue of pending tasks: doctor approvals to review, reviews to moderate, payouts to process, and support tickets to investigate. From the admin dashboard, the administrator works through each queue, taking action and logging the result in the audit trail."),

  h3("5.5.4  Booking and Payment Sequence"),
  ...imagePlaceholder("7", "Booking and Payment Sequence Diagram — patient → API → Paymob → webhook → chat unlocked"),

  p("This sequence diagram zooms into the most complex flow in the platform: the end-to-end booking, payment, confirmation, and chat unlock. Each step is annotated with the participating component and the message exchanged. The diagram emphasises the idempotent nature of the payment webhook and the strict requirement that the appointment is only Confirmed after the backend independently verifies the payment with Paymob."),

  // ----------------------------------------------------------------------- //
  h2("5.6  UI/UX Design"),
  p("The user interface of the Find Your Clinic mobile app is built on Material 3 with a custom palette that emphasises calm, trustworthy blues and accent greens. The design system supports both light and dark modes, full Arabic right-to-left layout, and Material 3 typography that scales gracefully with the system font size. The Next.js admin dashboard adopts a similar palette but in a denser, table-oriented layout suited to office workflows."),

  h3("5.6.1  Design System Overview"),
  bullet("Primary palette — deep clinical blue (#1F4E79), bright accent blue (#2E75B6), success green, warning amber, danger red."),
  bullet("Typography — Calibri / Inter for Latin scripts, Cairo / Tajawal for Arabic, with consistent type scales across the entire app."),
  bullet("Components — buttons, text fields, cards, chips, list tiles, dialogs, snackbars, and form fields all share a single token set."),
  bullet("Iconography — Material Icons throughout the mobile app, Lucide React in the admin dashboard."),
  bullet("Motion — short fade and slide transitions on navigation, subtle elevation lifts on press, and 200 ms loading skeletons for perceived performance."),

  h3("5.6.2  Patient-Side Screens"),
  ...imagePlaceholder("8", "Splash and Onboarding Screens"),
  p("The app opens with a minimalist splash showing the Find Your Clinic logo, followed by a three-page onboarding sequence that introduces the platform's value: find verified doctors, book in seconds, talk anywhere."),

  ...imagePlaceholder("9", "Authentication Screens — Login, Sign-up, Password Reset"),
  p("The authentication screens are intentionally simple. The login screen offers email, password, and a prominent Google Sign-In button. The sign-up screen collects the same fields plus role selection (Patient or Doctor). The password reset flow uses a tokenised email link."),

  ...imagePlaceholder("10", "Patient Home and Search Screens"),
  p("The patient home is organised into three vertical sections: a personalised greeting with a search bar, a horizontal carousel of recommended specialties, and a list of nearby and top-rated doctors. The search screen exposes filters as chips and offers both a list view and a map view."),

  ...imagePlaceholder("11", "Doctor Profile and Availability Screens"),
  p("The doctor profile shows the photo, name, specialty, average rating, fee, biography, languages, clinic location on a map, and a list of reviews. A sticky Book Appointment button is always visible at the bottom of the screen."),

  ...imagePlaceholder("12", "Appointment Booking and Payment Screens"),
  p("The booking flow takes the patient through three steps: pick a slot, confirm details, and pay. The Paymob WebView is opened in a modal, and the patient returns to the app with a success screen and the new appointment in the list."),

  ...imagePlaceholder("13", "Chat and Voice Note Screens"),
  p("The chat screen mirrors the patterns of modern messaging apps: bubbles, timestamps, reactions, and a microphone button that records voice notes. Sent messages animate in, and incoming messages trigger a subtle bounce."),

  ...imagePlaceholder("14", "AI Assistant Chat Screen"),
  p("The AI assistant uses the same chat metaphor but with a clear visual distinction: a violet header colour, a different avatar, and a persistent disclaimer at the top reminding the user that the assistant does not replace a real doctor."),

  ...imagePlaceholder("15", "Health Records Screens"),
  p("The Health Records section is organised by category (Medications, Allergies, Diagnoses, …). Each category opens a list of entries with quick add and share actions."),

  h3("5.6.3  Doctor-Side Screens"),
  ...imagePlaceholder("16", "Doctor Dashboard and Earnings Screens"),
  p("The doctor dashboard surfaces today's appointments, unread messages, recent reviews, and a glance at this month's earnings. A bottom navigation bar exposes the main sections: Dashboard, Appointments, Chat, Earnings, Profile."),

  h3("5.6.4  Admin Dashboard Screens"),
  ...imagePlaceholder("17", "Admin Dashboard Overview"),
  p("The admin dashboard opens with KPI cards (active patients, active doctors, today's appointments, today's revenue) and Recharts-based charts. The left sidebar exposes Approvals, Users, Specialties, Reviews, Financial, and Health Records."),

  ...imagePlaceholder("18", "Admin Doctor Approval and Moderation Screens"),
  p("The Approvals page lists pending doctors with thumbnails of their documents. Clicking a row opens a side drawer with the full document set and approve/reject buttons. Rejection requires a textual reason."),

  // ----------------------------------------------------------------------- //
  h2("5.7  Conclusion"),
  p("The design phase produced a complete blueprint of Find Your Clinic: a relational schema that captures every important entity, a UML class diagram that reflects the corresponding domain code, a use-case diagram that enumerates what each actor can do, four workflow diagrams that describe the most important journeys end-to-end, and a Material 3 design system that gives the mobile and web clients their visual identity. The next chapter explains the technological foundations that turn this design into a working system."),

  pageBreak(),
];

module.exports = { chapter5 };
