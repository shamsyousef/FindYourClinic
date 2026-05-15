const {
  chapterTitle, h2, h3, h4, p, lead, bullet, numbered, pageBreak, note,
} = require("./helpers");

const chapter3 = () => [
  chapterTitle("Chapter 3: Project Features"),

  // ----------------------------------------------------------------------- //
  h2("3.1  Introduction"),
  lead("This chapter presents the complete catalogue of features delivered by Find Your Clinic. Each feature is described from a user perspective, then linked to the relevant technical components inside the platform. Together, these features form a coherent product capable of supporting the full journey of a patient, a doctor, and an administrator — from sign-up through consultation, payment, and follow-up."),

  // ----------------------------------------------------------------------- //
  h2("3.2  Patient-Facing Features"),

  h3("3.2.1  Authentication and Account Management"),
  p("Find Your Clinic supports two ways to create an account: email-and-password sign-up with a verification email, or one-tap sign-in with Google through the Google Sign-In SDK. Both flows lead to the same Identity-backed user record on the server, with the user’s role (Patient, Doctor, or Admin) decided during onboarding. The system supports password recovery through a time-limited token sent by email and enforces a modern password policy (minimum eight characters, at least one digit, one uppercase letter, and one non-alphanumeric character)."),

  bullet("Email-and-password sign-up with email verification."),
  bullet("Google OAuth sign-in for fast, account-less onboarding."),
  bullet("Password reset via tokenised email link."),
  bullet("Persistent secure session using JWT access tokens and refresh tokens stored in flutter_secure_storage."),
  bullet("Automatic token refresh on 401 responses through a Dio interceptor."),
  bullet("Account profile editing for name, profile picture, gender, blood type, address, emergency contact, and language preference."),

  h3("3.2.2  Doctor Discovery and Search"),
  p("The discovery experience is the heart of the patient-side application. Patients can browse a fully indexed catalogue of verified doctors, filtered by specialty, geographic distance, fee range, language, gender, and rating. Results are returned through paginated REST endpoints and ranked by a configurable combination of patient distance, rating, and recent activity."),

  bullet("Specialty taxonomy curated by administrators and exposed as a filterable chip set."),
  bullet("Nearby clinics view, powered by Geolocator and the open-source Flutter Map, that shows doctors on an interactive map centred on the patient's location."),
  bullet("Free-text search by doctor name or clinic name."),
  bullet("Doctor cards showing photo, name, specialty, fee, rating, and next available slot."),
  bullet("Detail view with biography, qualifications, working hours, languages, fee, full review list, and a prominent Book Appointment call to action."),

  h3("3.2.3  Real-Time Appointment Booking"),
  p("Patients can view a doctor's published time slots in real time and book one in seconds. The booking flow validates that the chosen slot is still available on the server, creates an Appointment record with a Pending status, sends a Firebase Cloud Messaging notification to the doctor, and (for paid consultations) immediately opens the Paymob checkout WebView."),

  bullet("Slot-based availability with automatic conflict detection."),
  bullet("Server-side validation to prevent double-booking even under concurrent load."),
  bullet("Status workflow: Pending → Confirmed → Completed (or Cancelled / Rescheduled at any stage)."),
  bullet("Push notifications to both patient and doctor at every state transition."),
  bullet("In-app appointment list with filters for upcoming, past, and cancelled appointments."),
  bullet("Easy rescheduling and cancellation with confirmation dialogs."),

  h3("3.2.4  Integrated Online Payment"),
  p("Payment is integrated through the Paymob payment gateway, the most widely used online payment provider in Egypt. Patients can pay for consultations using a credit or debit card, with the entire transaction handled in a secure WebView. The backend acts as the source of truth: it generates a payment intent, receives a webhook from Paymob when the transaction is confirmed, and only then promotes the appointment from Pending to Confirmed."),

  bullet("Credit and debit card support via Paymob."),
  bullet("Server-side payment intent creation in an ASP.NET Core controller."),
  bullet("Idempotent webhook handler that confirms the appointment and credits the doctor's wallet."),
  bullet("Full transaction history visible inside the app."),
  bullet("Automatic refund pathway when an appointment is cancelled before the cut-off."),
  bullet("Doctor-side wallet tracking confirmed earnings minus platform fee."),

  h3("3.2.5  Secure Real-Time Chat"),
  p("After an appointment is confirmed, patient and doctor unlock a private chat channel powered by SignalR. The channel supports text messages, voice notes, image attachments, and message reactions. Messages are persisted in the database, and unread counts are surfaced through push notifications."),

  bullet("WebSocket-based real-time chat over SignalR with JWT authentication."),
  bullet("Optimistic UI: messages appear immediately on the sender side and are reconciled with the server response."),
  bullet("Voice notes recorded with the device microphone (the just_audio and record packages) and played back with waveform indicators."),
  bullet("Image attachments uploaded directly to Cloudinary with a secure delivery URL stored in the message record."),
  bullet("Message reactions (emoji-style) for quick acknowledgement."),
  bullet("Unread badge on the conversation list and push notification on incoming messages."),
  bullet("Strict authorisation: only the patient and doctor of a confirmed appointment can read or write to the conversation."),

  h3("3.2.6  Digital Health Records"),
  p("Find Your Clinic provides every patient with a private digital health vault. The vault stores medications, allergies, lab results, chronic conditions, vaccinations, and family history. Each record is structured so that it can be displayed cleanly, searched, and selectively shared with doctors during consultations."),

  bullet("Multiple record categories: Medication, Allergy, Diagnosis, Lab Result, Vaccination, Surgery, Family History, Note."),
  bullet("Attach images or PDF lab reports to records (uploaded to Cloudinary)."),
  bullet("Timeline view showing the patient's health history at a glance."),
  bullet("Selective sharing: doctors only see records the patient chooses to share for that consultation."),
  bullet("Backend audit trail of every read and write to a record, used for compliance and admin support."),

  h3("3.2.7  AI Health Assistant"),
  p("The AI assistant — branded internally as the “Find Your Clinic Voice & Chat AI” — is built on top of the Google Gemini API. It allows patients to describe their symptoms in natural language (or by voice), and receive an empathetic, medically aware response that helps them understand possible causes and choose the right specialty to consult. The assistant is intentionally cautious: it never provides a diagnosis, refuses to recommend prescription drugs, and always reminds the patient to consult a real doctor for anything serious."),

  bullet("Multi-turn conversation with history, persisted in the AiChatMessages table."),
  bullet("Both text and voice input/output (Speech-to-Text for input, Flutter TTS for output)."),
  bullet("Specialty recommendation tied to the in-app doctor search — one tap from a suggestion to a list of relevant doctors."),
  bullet("A custom medical system prompt that enforces tone, scope, and safety rules."),
  bullet("Retry-and-fallback logic in the backend GeminiService: if the primary Gemini model is rate-limited, the service falls back to a configured secondary model."),
  bullet("Conversation history available for review later inside the assistant tab."),

  h3("3.2.8  Doctor Reviews and Ratings"),
  p("After a completed appointment, the patient is prompted to leave a star rating and an optional written review. Reviews are tied to the appointment to prevent fake ratings, and are subject to admin moderation. The aggregate rating is recomputed on the server and displayed prominently on the doctor's profile."),

  bullet("One-to-one binding between an appointment and a review (no review without a completed appointment)."),
  bullet("Five-star scale with optional written feedback."),
  bullet("Admin moderation queue for reported or suspicious reviews."),
  bullet("Recomputed aggregate rating visible on doctor cards and profiles."),

  h3("3.2.9  Push Notifications"),
  p("All time-sensitive events in the platform are delivered as push notifications through Firebase Cloud Messaging. Every device registers an FCM token at login, and the backend NotificationService dispatches targeted messages by user, by role, or by topic."),

  bullet("Appointment created, confirmed, rescheduled, cancelled, completed."),
  bullet("Payment succeeded, refunded, or failed."),
  bullet("New chat message or voice note."),
  bullet("Doctor verification approved or rejected (for doctors)."),
  bullet("Admin announcements (broadcast to all users or by role)."),
  bullet("In-app notification list with read / unread state."),

  h3("3.2.10  Accessibility and Personalisation"),
  p("Find Your Clinic places a strong emphasis on accessibility. The app fully supports Arabic with right-to-left layouts, ships with dark and light themes that share the same colour tokens, exposes a voice command FAB on every screen, and follows the Material 3 contrast guidelines."),

  bullet("Arabic and English with full RTL support."),
  bullet("Dark and light themes with shared Material 3 token sets."),
  bullet("Voice command floating action button driven by Speech-to-Text."),
  bullet("Voice responses via Flutter TTS for the AI assistant and key confirmations."),
  bullet("Scalable typography honouring the user's system font scale."),
  bullet("Large tap targets and clear focus states for keyboard or accessibility-tool navigation."),

  // ----------------------------------------------------------------------- //
  h2("3.3  Doctor-Facing Features"),

  h3("3.3.1  Doctor Onboarding and Verification"),
  p("A new doctor signs up with the same authentication flow as a patient, but selects the Doctor role during onboarding. They are then guided through a multi-step verification flow where they upload identity documents (national ID), a copy of their medical license, and proof of practice (clinic permit or hospital affiliation letter). All documents are uploaded to Cloudinary with secure access, and the doctor's account remains in a Pending state until an administrator reviews and approves the application."),

  bullet("Step-by-step onboarding wizard with progress indicator."),
  bullet("Required fields: specialty, biography, clinic address (with map pin), languages, consultation fee."),
  bullet("Document uploads stored in the DoctorDocuments table and surfaced to the admin dashboard."),
  bullet("Status screen showing Pending Approval, Approved, or Rejected with reason."),
  bullet("Re-submission flow if the admin rejects a particular document with a specific reason."),

  h3("3.3.2  Doctor Dashboard"),
  p("Once approved, doctors access a personalised dashboard that gives them a complete overview of their practice. The dashboard shows upcoming appointments, recent chat messages, recent reviews, and an at-a-glance summary of earnings."),

  bullet("Today's appointments with patient name, time, and status."),
  bullet("Unread chat counter and quick links to active conversations."),
  bullet("Recent reviews and average rating."),
  bullet("Earnings card showing this month's confirmed earnings and pending payouts."),
  bullet("Shortcuts to the availability planner, profile editor, and earnings page."),

  h3("3.3.3  Availability Planner"),
  p("Doctors define their weekly availability through a structured planner. They choose the days and hours they work, the duration of each slot (typically 15, 20, or 30 minutes), and any breaks. The system generates the slot list automatically and exposes it to the search and booking layer."),

  bullet("Weekly recurring schedule with per-day toggles."),
  bullet("Configurable slot duration."),
  bullet("Manual overrides for vacations, conferences, or sick days."),
  bullet("Automatic slot regeneration when the schedule changes, with safe handling of already-booked appointments."),

  h3("3.3.4  Appointment Management"),
  p("Doctors see every appointment in a unified inbox. They can confirm pending appointments (if confirmation is required), mark completed appointments, cancel with a reason, or contact the patient through chat. Each state transition is mirrored in real time on the patient side via push notifications."),

  bullet("Inbox with filters: Pending, Confirmed, Completed, Cancelled."),
  bullet("Quick actions: confirm, complete, cancel, message."),
  bullet("Calendar view aggregating all confirmed appointments."),
  bullet("Search by patient name or date."),

  h3("3.3.5  Patient Chat and Voice Notes"),
  p("From their side of the conversation, doctors enjoy the same real-time chat experience as patients. They can send text, voice notes, and image attachments, react to messages, and inspect the patient's shared health records during the consultation."),

  h3("3.3.6  Earnings and Wallet"),
  p("Every confirmed payment credits the doctor's in-app wallet, minus the platform fee. Doctors can inspect a complete transaction ledger, request a payout, and provide their bank details for processing. The admin dashboard handles the actual payout execution."),

  bullet("Wallet balance: available, pending, and lifetime earnings."),
  bullet("Per-transaction ledger with patient name, date, gross, fee, net."),
  bullet("Payout request form with bank or mobile-wallet details."),
  bullet("Payout history with status (Requested, Processing, Paid)."),

  // ----------------------------------------------------------------------- //
  h2("3.4  Administrator-Facing Features"),

  h3("3.4.1  Admin Authentication and Role Guard"),
  p("The administrative dashboard is a Next.js web application protected by a role guard. Only users with the Admin role can log in; all other roles are redirected to the login page. Authentication uses the same backend JWT identity as the mobile app, ensuring a single source of truth for users and roles."),

  h3("3.4.2  Doctor Approval Workflow"),
  p("New doctor applications appear in a queue inside the Approvals page. Administrators see the doctor's profile, every uploaded document, and a side panel with approval and rejection actions. Rejecting an application requires a textual reason, which is delivered to the doctor and visible inside their app."),

  bullet("Pending application queue sorted by submission date."),
  bullet("Document viewer with zoom and download."),
  bullet("Approve / Reject actions with mandatory rejection reason."),
  bullet("Automatic email and in-app notification to the doctor on decision."),

  h3("3.4.3  User Management"),
  p("Administrators can search for any user (patient or doctor) by name or email, view their profile, and toggle their account status. Deactivated users lose access until they are reactivated. The same page surfaces sign-up date, role, last activity, and a link to relevant audit logs."),

  h3("3.4.4  Specialty Management"),
  p("Specialties are managed centrally rather than entered as free text. Administrators can add, rename, or remove specialties through a simple CRUD interface. Doctors choose from this curated list during onboarding, which keeps the search experience clean."),

  h3("3.4.5  Review Moderation"),
  p("All reviews flow through a moderation queue. Administrators can approve, flag, or delete reviews that violate platform rules. Deleted reviews remain in the audit trail for accountability."),

  h3("3.4.6  Financial Oversight and Payouts"),
  p("The Financial page presents a complete view of the platform's economy. Administrators can see total revenue, doctor wallets, pending payouts, completed payouts, and refunds. Charts (Recharts) provide an at-a-glance view of trends. Individual transactions are searchable and exportable."),

  bullet("Revenue dashboard with monthly and weekly charts."),
  bullet("Doctor wallet inspection."),
  bullet("Payout queue with bulk processing."),
  bullet("Refund handling for cancelled or disputed appointments."),

  h3("3.4.7  Health Record Lookup (Compliance Support)"),
  p("For support and compliance scenarios — for example, when a patient cannot access their records — administrators can search for records by patient email and inspect them. All such accesses are logged in the audit trail and visible to the patient on demand."),

  // ----------------------------------------------------------------------- //
  h2("3.5  Cross-Cutting Capabilities"),

  h3("3.5.1  Integration and Synchronization"),
  p("All major features in Find Your Clinic are wired together so that data flows seamlessly across them. A new appointment automatically unlocks the chat. A confirmed payment automatically credits the doctor's wallet. A new review automatically updates the doctor's aggregate rating. A new chat message automatically triggers a push notification. This tight integration is implemented through clear backend boundaries (each feature has its own MediatR handler) and well-defined data ownership (each feature owns its own tables but reads from others through repositories)."),

  h3("3.5.2  Security and Privacy"),
  bullet("HTTPS-only communication."),
  bullet("JWT-based authentication with refresh tokens stored in the database."),
  bullet("Role-based authorisation policies."),
  bullet("Cloudinary signed URLs for sensitive uploads."),
  bullet("Password hashing through ASP.NET Identity."),
  bullet("Audit logs for sensitive admin actions."),

  h3("3.5.3  Performance and Scalability"),
  bullet("Stateless API instances that can scale horizontally behind a load balancer."),
  bullet("Database indexed on commonly queried columns (specialty, location, status)."),
  bullet("Pagination on all list endpoints."),
  bullet("Cached aggregates (doctor ratings, wallet balances) recomputed asynchronously."),
  bullet("Image delivery offloaded to Cloudinary's CDN."),

  // ----------------------------------------------------------------------- //
  h2("3.6  Conclusion"),
  p("Find Your Clinic ships with a deliberately broad feature set, because solving healthcare access requires more than a single screen. Patients need to discover doctors, schedule appointments, pay, communicate, store their records, and ask informed questions. Doctors need to manage their schedule, their patients, and their earnings. Administrators need to verify trust, moderate behaviour, and oversee finance. The next chapter explains the methodology and engineering process that allowed our team to deliver this complete feature set within the time and resource constraints of a graduation project."),

  pageBreak(),
];

module.exports = { chapter3 };
