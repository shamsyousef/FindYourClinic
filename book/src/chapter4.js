const {
  chapterTitle, h2, h3, h4, p, lead, bullet, numbered, pageBreak, note, kvTable,
} = require("./helpers");

const chapter4 = () => [
  chapterTitle("Chapter 4: Methodology"),

  // ----------------------------------------------------------------------- //
  h2("4.1  Introduction"),
  lead("This chapter describes the methodology used to design and build Find Your Clinic. It enumerates the functional requirements that define what the system must do, the non-functional requirements that define the quality attributes the system must satisfy, and the development methodology and timeline that the team followed throughout the academic year."),

  p("The chapter is organised into four main parts:"),
  bullet("Section 4.2 lists the functional requirements grouped by feature area."),
  bullet("Section 4.3 lists the non-functional requirements covering performance, scalability, security, usability, availability, maintainability, and interoperability."),
  bullet("Section 4.4 presents the development methodology — the engineering principles, branching strategy, code-review process, and testing discipline that shaped daily work."),
  bullet("Section 4.5 presents the project timeline as a sequence of two-week sprints with concrete deliverables."),

  // ----------------------------------------------------------------------- //
  h2("4.2  Functional Requirements"),
  p("Functional requirements describe the behaviour that the system must deliver — what the user can do and how the system responds. They are mandatory and form the contract between the product team and the implementation. The functional requirements for Find Your Clinic are grouped by feature area below."),

  h3("4.2.1  Authentication and Account Management"),
  bullet("The system shall allow new users to register with email and password, receiving an email verification link before the account becomes active."),
  bullet("The system shall allow users to sign in with a verified Google account through OAuth 2.0."),
  bullet("The system shall issue a short-lived JWT access token and a longer-lived refresh token at successful login."),
  bullet("The system shall allow users to reset their password through a one-time tokenised email link."),
  bullet("The system shall enforce a strong password policy (minimum 8 characters, at least one digit, one uppercase letter, and one non-alphanumeric character)."),
  bullet("The system shall support three roles — Patient, Doctor, Admin — and use role-based authorisation policies to gate sensitive endpoints."),
  bullet("The system shall allow users to update their profile (name, picture, phone, address, language preference)."),
  bullet("The system shall allow administrators to activate or deactivate any user account."),

  h3("4.2.2  Doctor Onboarding and Verification"),
  bullet("The system shall guide doctors through a multi-step onboarding wizard collecting profile, specialty, fee, clinic address, and supported languages."),
  bullet("The system shall require doctors to upload identity, medical license, and proof of practice documents (PDF or image)."),
  bullet("The system shall keep new doctors in a Pending state until an administrator reviews and approves the application."),
  bullet("The system shall notify the doctor by email and push notification when their application is approved or rejected."),
  bullet("The system shall allow rejected doctors to resubmit specific documents based on the admin's reason."),

  h3("4.2.3  Doctor Discovery and Search"),
  bullet("The system shall allow patients to search doctors by specialty, free text, location, fee range, rating, and language."),
  bullet("The system shall return paginated search results with photo, specialty, fee, rating, and next available slot."),
  bullet("The system shall expose a detailed doctor profile including biography, qualifications, working hours, clinic address with map pin, fee, and review list."),
  bullet("The system shall provide a nearby-clinics map view centred on the patient's current location."),
  bullet("The system shall expose only approved, active doctors in search results."),

  h3("4.2.4  Appointment Management"),
  bullet("The system shall allow doctors to define recurring weekly availability with configurable slot duration."),
  bullet("The system shall expose the doctor's available slots to patients in real time."),
  bullet("The system shall allow patients to book a specific slot, validating availability on the server to prevent double-booking."),
  bullet("The system shall support appointment states: Pending, Confirmed, Completed, Cancelled, Rescheduled."),
  bullet("The system shall send push notifications to both parties at every state transition."),
  bullet("The system shall allow patients and doctors to view a unified appointment list filtered by status."),

  h3("4.2.5  Payments and Financial Operations"),
  bullet("The system shall integrate with the Paymob payment gateway to accept credit and debit card payments."),
  bullet("The system shall create a payment intent on the server, never trusting client-side amounts."),
  bullet("The system shall confirm the appointment only after receiving a verified webhook from the payment gateway."),
  bullet("The system shall maintain a Transaction ledger recording every successful or failed payment."),
  bullet("The system shall maintain a DoctorWallet record per doctor tracking gross earnings, platform fee, and available balance."),
  bullet("The system shall allow doctors to submit payout requests with bank or mobile-wallet details."),
  bullet("The system shall allow administrators to process payouts and mark them as Paid in the system."),
  bullet("The system shall support refunds for cancelled appointments within a configurable cut-off window."),

  h3("4.2.6  Real-Time Chat"),
  bullet("The system shall expose a SignalR hub at /hubs/chat that requires JWT authentication."),
  bullet("The system shall allow a patient and a doctor to chat only after a confirmed appointment between them."),
  bullet("The system shall support text messages, image attachments, voice notes, and message reactions."),
  bullet("The system shall persist every message in the database and surface it to the client through a paginated history endpoint."),
  bullet("The system shall send a push notification on every incoming message when the recipient app is not in the foreground."),
  bullet("The system shall mark messages as Sent, Delivered, and Read with status timestamps."),

  h3("4.2.7  Health Records"),
  bullet("The system shall allow patients to create, update, and delete health record entries across multiple categories (Medication, Allergy, Diagnosis, Lab Result, Vaccination, Surgery, Family History, Note)."),
  bullet("The system shall allow patients to attach images or PDF documents to records."),
  bullet("The system shall allow patients to selectively share records with specific doctors for specific appointments."),
  bullet("The system shall maintain an audit trail of every read and write on a health record."),

  h3("4.2.8  Reviews and Ratings"),
  bullet("The system shall allow a patient to leave exactly one review per completed appointment."),
  bullet("The system shall require a star rating (1–5) and accept an optional written comment."),
  bullet("The system shall recompute the doctor's aggregate rating on each new or moderated review."),
  bullet("The system shall allow administrators to approve, flag, or delete reviews."),

  h3("4.2.9  AI Health Assistant"),
  bullet("The system shall provide an AI assistant powered by the Google Gemini API, accessible from a dedicated tab in the patient app."),
  bullet("The system shall support both text and voice input, and both text and voice output."),
  bullet("The system shall persist conversation history per user."),
  bullet("The system shall apply a medical system prompt that constrains the assistant to safe, empathetic, non-diagnostic responses."),
  bullet("The system shall recommend an appropriate medical specialty when sufficient context is available."),
  bullet("The system shall fall back to a configured secondary model on rate-limit or transient error from the primary model."),

  h3("4.2.10  Notifications"),
  bullet("The system shall register every device's FCM token at login."),
  bullet("The system shall send targeted push notifications by user, by role, or by topic."),
  bullet("The system shall maintain an in-app notification inbox with read/unread state."),

  h3("4.2.11  Administrative Operations"),
  bullet("The system shall allow administrators to authenticate via the same identity store used for patients and doctors."),
  bullet("The system shall expose pages for doctor approval, user management, specialty management, review moderation, financial dashboard, payout processing, and health record support lookup."),
  bullet("The system shall log every sensitive administrative action."),

  // ----------------------------------------------------------------------- //
  h2("4.3  Non-Functional Requirements"),
  p("Non-functional requirements capture the qualities that the system must exhibit independently of any particular feature. They are essential because they shape how the architecture, the operations, and the user experience feel in practice."),

  h3("4.3.1  Performance"),
  bullet("API endpoints shall return a response within 800 ms at the 95th percentile under normal load (≤ 100 concurrent users)."),
  bullet("Doctor search results shall be rendered within 1.5 seconds end-to-end on a 4G mobile network."),
  bullet("Chat messages shall be delivered within 500 ms one-way through SignalR on a healthy connection."),
  bullet("Push notifications shall be delivered within 2 seconds of the originating server event."),

  h3("4.3.2  Scalability"),
  bullet("The backend API shall be stateless so that it can scale horizontally behind a load balancer."),
  bullet("The database schema shall include indexes on every column used for filtering or sorting."),
  bullet("Heavy computations (aggregate ratings, wallet snapshots) shall be designed to run asynchronously where feasible."),
  bullet("File uploads shall be offloaded to Cloudinary's CDN rather than served from the API process."),

  h3("4.3.3  Security"),
  bullet("All client–server traffic shall use HTTPS exclusively."),
  bullet("User passwords shall be hashed with PBKDF2 (the default ASP.NET Identity hasher) and never stored in plaintext."),
  bullet("JWT access tokens shall have a short lifetime (e.g. 30 minutes) and shall be refreshed using rotated refresh tokens stored in the database."),
  bullet("Role-based authorisation policies shall guard every sensitive endpoint."),
  bullet("Sensitive uploads (medical documents, health records) shall be served through signed Cloudinary URLs."),
  bullet("All admin actions shall be logged with actor, target, timestamp, and outcome."),

  h3("4.3.4  Usability"),
  bullet("The mobile app shall follow Material 3 typography, colour, and spacing conventions."),
  bullet("Critical actions (book, pay, send) shall be reachable within three taps from any screen."),
  bullet("The app shall display loading, success, empty, and error states explicitly — no silent failures."),
  bullet("All text inputs shall validate inline and offer corrective hints."),
  bullet("The app shall be fully usable in both Arabic and English with correct RTL layouts."),

  h3("4.3.5  Availability"),
  bullet("The platform shall target 99.5% monthly availability for core user-facing endpoints."),
  bullet("Background jobs (notifications, webhooks) shall be retried on transient failure with exponential backoff."),
  bullet("Critical state transitions (payment confirmation, appointment confirmation) shall be idempotent so that retries are safe."),

  h3("4.3.6  Maintainability"),
  bullet("The codebase shall follow clean-architecture layering, with strict boundaries between Domain, Infrastructure, and API."),
  bullet("Each backend feature shall be implemented as a vertical slice (command/query + handler + validator) to keep growth linear."),
  bullet("Each mobile feature shall live in its own folder with its own data, domain, and presentation layers."),
  bullet("Code review shall be required on every pull request before merge."),
  bullet("Unit and integration tests shall accompany new business logic."),

  h3("4.3.7  Interoperability"),
  bullet("The system shall expose a documented REST API to allow future integration with third-party tools (e.g., insurance providers, lab partners)."),
  bullet("The chat hub shall accept standard SignalR clients (JavaScript, Dart, .NET)."),
  bullet("The data model shall use ISO standards for dates (ISO-8601 in UTC) and currencies (ISO-4217 codes)."),

  h3("4.3.8  Privacy"),
  bullet("Health record access shall be limited to the owning patient and explicitly authorised doctors."),
  bullet("Reviews shall be moderated to remove personal data leaks."),
  bullet("Users shall be able to export and delete their data on request, in compliance with applicable privacy norms."),

  h3("4.3.9  Localisation and Accessibility"),
  bullet("All user-facing strings shall live in a single translation table to support adding new languages later."),
  bullet("The app shall honour the system font-scale setting and shall not break layout at 130% scaling."),
  bullet("Voice commands shall be available for the most common patient flows (search, book, message)."),

  // ----------------------------------------------------------------------- //
  h2("4.4  Development Methodology"),
  p("The team adopted an iterative, Agile-inspired methodology adapted to the constraints of a graduation project. The methodology blends elements of Scrum (two-week sprints, regular reviews), Lean UX (small experiments, rapid feedback), and clean-architecture engineering discipline."),

  h3("4.4.1  Roles and Responsibilities"),
  p("The team consisted of six members with overlapping but specialised roles:"),

  bullet("Backend Engineers — designed and implemented the .NET 10 API, SQL Server schema, SignalR hub, and external integrations (Paymob, Cloudinary, FCM, Gemini)."),
  bullet("Mobile Engineers — built the Flutter mobile application with feature-based architecture, Cubit/Bloc state management, and platform integrations (location, notifications, voice)."),
  bullet("Admin Engineer — built the Next.js admin dashboard."),
  bullet("UI/UX Designer — produced the design system, the high-fidelity Figma mockups, and the accessibility guidelines."),
  bullet("AI/Data Engineer — designed the Gemini prompt, integrated the API, tuned the retry/fallback logic, and evaluated answer quality."),
  bullet("Project Lead — coordinated the team, owned the timeline, and represented the project to supervisors."),

  h3("4.4.2  Branching and Code Review"),
  p("All work happened on a single Git repository hosted on GitHub. The main branch represented the deployable state of the project. Every feature was developed on a topic branch named after the feature (for example, feature/appointment-booking). Pull requests targeted main and required at least one peer code review and a green build before they could be merged. The CLAUDE.md project guidelines (atomic commits, conventional commit messages, no force-push to main) were followed strictly."),

  h3("4.4.3  Testing Discipline"),
  bullet("Unit tests for backend command/query handlers using xUnit and an in-memory database provider."),
  bullet("Widget tests for important Flutter screens using the standard flutter_test framework."),
  bullet("Manual exploratory testing on real Android devices at the end of every sprint."),
  bullet("Smoke tests covering the critical paths (login, search, book, pay, chat) before any release build."),

  h3("4.4.4  Definition of Done"),
  p("A feature was considered \"done\" only when it satisfied all of the following criteria:"),

  bullet("All acceptance criteria of the feature were observable in the running app."),
  bullet("Unit tests for new business logic were written and passing."),
  bullet("The feature was reviewed and approved by at least one peer."),
  bullet("The feature was tested manually on at least one Android device."),
  bullet("Documentation (in CLAUDE.md or feature-specific files) was updated if relevant."),

  // ----------------------------------------------------------------------- //
  h2("4.5  Project Timeline"),
  p("The project was structured into twelve two-week sprints across the academic year. Each sprint targeted a small set of vertical slices, ending with a runnable build that we could demonstrate. The following table summarises the timeline."),

  kvTable(
    [
      ["Sprint 1–2 (Weeks 1–4)", "Discovery and requirements. User interviews, competitive analysis, persona definition, initial backlog, technology selection."],
      ["Sprint 3 (Weeks 5–6)", "System and database design. ERD, UML class diagram, use-case diagram, workflow diagrams; SQL Server schema; initial .NET 10 project scaffold."],
      ["Sprint 4 (Weeks 7–8)", "UI/UX design. Figma component library, design tokens, screen mockups for both light and dark themes; Arabic RTL adaptation."],
      ["Sprint 5 (Weeks 9–10)", "Authentication and onboarding. ASP.NET Identity, JWT, refresh tokens, Google OAuth, password reset, email verification; matching Flutter screens."],
      ["Sprint 6 (Weeks 11–12)", "Doctor profiles and specialty management. Doctor onboarding, document upload, admin verification queue; specialty CRUD in admin dashboard."],
      ["Sprint 7 (Weeks 13–14)", "Doctor discovery. Search and filtering endpoints, Flutter search UI, doctor profile screen, nearby clinics map view."],
      ["Sprint 8 (Weeks 15–16)", "Appointment booking. Availability planner, slot generation, booking endpoint, conflict detection, status workflow, push notifications."],
      ["Sprint 9 (Weeks 17–18)", "Payments. Paymob integration, payment intent flow, webhook handler, transaction ledger, doctor wallet, basic payout flow."],
      ["Sprint 10 (Weeks 19–20)", "Real-time chat. SignalR hub, conversation tables, Flutter chat UI with text, voice notes, image attachments, and reactions."],
      ["Sprint 11 (Weeks 21–22)", "Health records and AI assistant. Health record CRUD, attachments, sharing rules; Gemini integration, AI chat history, voice I/O."],
      ["Sprint 12 (Weeks 23–24)", "Polish, testing, and deployment readiness. Bug fixes, performance tuning, accessibility audit, release builds for Android and iOS, admin dashboard polish, final documentation."],
    ],
    ["Period", "Deliverable"]
  ),

  // ----------------------------------------------------------------------- //
  h2("4.6  Conclusion"),
  p("The methodology described in this chapter is what allowed a six-person student team to build, in one academic year, a healthcare platform with a wide product surface and a production-grade architecture. By combining clear functional and non-functional requirements with an iterative development process, strict code review, and disciplined testing, the team converted a long backlog into a working product without sacrificing quality. The next chapter zooms into the design artefacts — the database, the class model, the use-case diagram, and the workflow diagrams — that anchored every implementation decision."),

  pageBreak(),
];

module.exports = { chapter4 };
