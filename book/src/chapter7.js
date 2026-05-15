const {
  chapterTitle, h2, h3, h4, p, lead, bullet, numbered, pageBreak, note, kvTable, imagePlaceholder,
} = require("./helpers");

const chapter7 = () => [
  chapterTitle("Chapter 7: Implementation and Test"),

  // ----------------------------------------------------------------------- //
  h2("7.1  Introduction"),
  lead("This chapter describes the implementation of Find Your Clinic from a hands-on, engineering perspective. It walks through the system architecture, the implementation details of each layer, the integration points between them, and the test strategy that ensured correctness and reliability. Where the previous chapter focused on what technologies were chosen and why, this chapter focuses on how the system was actually built."),

  // ----------------------------------------------------------------------- //
  h2("7.2  System Architecture in Practice"),
  p("Find Your Clinic is composed of three clients (Flutter mobile, Next.js admin dashboard, future web client), one shared backend API (ASP.NET Core .NET 10 + SignalR), and one shared SQL Server database. External integrations (Cloudinary, FCM, Paymob, Gemini, Google OAuth, SMTP) sit alongside the backend and are accessed through dedicated service abstractions."),

  ...imagePlaceholder("20", "End-to-end deployment topology — clients, API, database, external integrations"),

  p("Each client communicates with the backend exclusively over HTTPS REST endpoints and, for the chat, an authenticated WebSocket connection. There is no direct client-to-database access and no client-to-third-party access (with the single exception of Cloudinary uploads, which use a signed upload preset for performance)."),

  // ----------------------------------------------------------------------- //
  h2("7.3  Backend Implementation"),

  h3("7.3.1  Project Structure"),
  p("The backend follows the clean-architecture layering described in Chapter 6. The implementation lives under the Backend/ directory of the repository, with the following layout:"),

  bullet("Backend/FindYourClinic.sln — the Visual Studio solution."),
  bullet("Backend/src/FindYourClinic.Domain — entities and pure interfaces."),
  bullet("Backend/src/FindYourClinic.Infrastructure — EF Core, Identity, integrations."),
  bullet("Backend/src/FindYourClinic.API — controllers, hubs, features, middleware, Program.cs."),
  bullet("Backend/tests — unit and integration tests (one project per layer)."),

  h3("7.3.2  Identity and Authentication"),
  p("The Identity setup is configured in Infrastructure/IdentityConfiguration.cs. It wires up ApplicationUser, the role enumeration (UserRole), and the password policy. The JwtService — registered as a singleton — handles token generation. The default access-token lifetime is 30 minutes; refresh tokens last 30 days, are stored in the database, and are rotated on every refresh."),

  h3("7.3.3  Vertical Slices in Action"),
  p("To illustrate how vertical slices work in practice, consider the appointment booking flow. Booking an appointment is implemented as a CreateAppointmentCommand routed through MediatR. The command carries the doctor ID, the slot identifier, and any notes. The CreateAppointmentCommandHandler performs the following steps:"),

  numbered("Validates input through CreateAppointmentCommandValidator (FluentValidation)."),
  numbered("Loads the doctor and verifies they are active and approved."),
  numbered("Loads the chosen slot and verifies that it is still available."),
  numbered("Creates the Appointment entity with status Pending."),
  numbered("Creates a PendingBookingIntent linking the appointment to the upcoming payment."),
  numbered("Persists everything inside a transaction."),
  numbered("Returns the new appointment ID to the controller, which sends a 201 Created response with the payment intent URL."),

  p("A separate webhook handler (PaymobWebhookController) listens for Paymob notifications. When a payment is confirmed, it loads the matching pending intent, promotes the appointment to Confirmed, credits the doctor's wallet, sends notifications, and opens the chat conversation. The two flows are deliberately decoupled so that the booking remains intact even if the patient closes the app during payment."),

  h3("7.3.4  EF Core and the DbContext"),
  p("ApplicationDbContext extends IdentityDbContext<ApplicationUser, IdentityRole<Guid>, Guid> and adds DbSets for every domain entity. Entity configurations live in dedicated files inside Infrastructure/Persistence/Configurations and are applied through reflection in OnModelCreating. We use Fluent API extensively to set up indexes, constraints, and many-to-many relations. Migrations are generated with dotnet ef migrations add and applied with dotnet ef database update."),

  h3("7.3.5  Real-Time Hub"),
  p("ChatHub lives in Backend/src/FindYourClinic.API/Hubs/ChatHub.cs. It uses Authorize attributes to require an authenticated user, joins the user to per-conversation groups upon connection, and exposes the following methods to clients:"),

  bullet("JoinConversation(conversationId) — adds the connection to the SignalR group of that conversation."),
  bullet("SendMessage(conversationId, message) — persists the message and broadcasts it to all participants in the group."),
  bullet("MarkAsRead(conversationId, messageId) — updates the message status and notifies the sender."),
  bullet("ReactToMessage(messageId, emoji) — persists the reaction and broadcasts it."),

  h3("7.3.6  AI Integration"),
  p("GeminiService is the backend's entry point into the Google Gemini API. It accepts a conversation history (a list of turns with role and content) and returns the model's next reply. The service applies the medical system prompt, the retry-and-fallback logic, and the conversation-history truncation needed to fit the model's token budget. The AI controller persists every turn into AiChatMessages, so the conversation history is preserved across sessions."),

  h3("7.3.7  Payments and Wallet"),
  p("PaymentsController exposes endpoints to create a payment intent (returning a Paymob hosted-checkout URL) and to receive webhooks. The DoctorWalletService implements wallet operations idempotently: every transaction has a unique transaction ID, and re-processing the same ID is a no-op. The wallet balance is recomputed from the transaction ledger to ensure consistency."),

  h3("7.3.8  Notifications"),
  p("NotificationService composes a payload, persists an in-app Notification record, and (when an FCM token is available) submits the payload to Firebase. Failures are logged but do not block the originating request — notifications are eventually consistent."),

  // ----------------------------------------------------------------------- //
  h2("7.4  Mobile Application Implementation"),

  h3("7.4.1  Project Structure"),
  p("The Flutter project lives at Mobile/ in the repository. The Mobile/lib folder follows the feature-based layout introduced in Chapter 6, with shared infrastructure under core/ and one folder per feature under features/."),

  h3("7.4.2  Dependency Injection"),
  p("service_locator.dart in core/di registers every dependency in a single function called setupServiceLocator(). This function is invoked from main() before runApp() so that all services are ready by the time the first widget is built. The locator registers the API client, the secure token storage, every repository, every use case, every cubit, the FCM plug-in, the SignalR client, the speech-to-text plug-in, and the Flutter TTS plug-in."),

  h3("7.4.3  Routing"),
  p("Navigation uses GoRouter and follows a shell-based pattern. There are three top-level shells: AuthShell, PatientShell, and DoctorShell. The router examines the user's authentication state and role at every navigation and redirects when necessary. Deep links (for appointments, chats, notifications) are handled by named routes with parameters."),

  h3("7.4.4  Networking and Token Refresh"),
  p("The Dio client in core/network has two interceptors. The AuthInterceptor injects the JWT access token in the Authorization header. The RefreshInterceptor detects 401 responses, calls the refresh-token endpoint with the stored refresh token, persists the new access token, and retries the original request. Failures during refresh log the user out and redirect them to the sign-in screen."),

  h3("7.4.5  Chat Implementation"),
  p("The chat feature uses a single ChatCubit that owns the connection to the SignalR hub. The cubit exposes a stream of messages that the chat screen subscribes to. Sending a message is optimistic: the message is added to the local state with a Pending marker, then reconciled with the server response. Failure paths are explicit and recoverable."),

  h3("7.4.6  Voice and AI"),
  p("The AI assistant feature uses the AiChatCubit, which loads the user's conversation history from the backend, sends new user messages through the AI API, and persists responses. Voice input is handled by speech_to_text, which streams partial transcripts to the cubit; voice output is performed by Flutter TTS, which is initialised with a localised voice (English or Arabic depending on the user's language preference)."),

  // ----------------------------------------------------------------------- //
  h2("7.5  Admin Dashboard Implementation"),

  h3("7.5.1  Authentication and Route Guard"),
  p("The admin dashboard uses the same JWT identity as the mobile app. On login, the access token is stored in an httpOnly cookie. A middleware reads the cookie on every request and redirects unauthenticated users to /login. The admin login page rejects users whose role claim is not Admin, ensuring that doctors and patients cannot accidentally log into the dashboard."),

  h3("7.5.2  Server Components and Data Fetching"),
  p("Data fetching for the admin dashboard happens primarily in server components. For example, the Approvals page fetches the list of pending doctors directly on the server using the backend's REST endpoints. Only forms and dialogs are client components."),

  h3("7.5.3  Charts and Financial Views"),
  p("The financial dashboard uses Recharts to render time-series line charts (revenue, transactions, payouts). The data is aggregated on the backend through a dedicated endpoint and consumed by the chart component."),

  // ----------------------------------------------------------------------- //
  h2("7.6  Test Strategy"),
  p("Testing was layered to balance confidence and cost. Lower layers (handlers, repositories) are covered by automated tests; higher layers (end-to-end flows on real devices) rely on disciplined manual testing."),

  h3("7.6.1  Backend Tests"),
  bullet("Unit tests for MediatR command and query handlers, using xUnit and an in-memory EF Core provider for fast iteration."),
  bullet("Integration tests for the HTTP API using TestServer, covering authentication, authorisation, validation, and the happy path of each endpoint."),
  bullet("Idempotency tests for the Paymob webhook handler — sending the same webhook twice produces a single state transition."),
  bullet("Smoke tests over the SignalR hub using a test client to verify message delivery."),

  h3("7.6.2  Mobile Tests"),
  bullet("Widget tests for critical screens: login, search, doctor profile, booking, chat."),
  bullet("Cubit tests using bloc_test to verify state transitions in response to use-case calls."),
  bullet("Repository tests with mocked Dio clients to verify request shapes and error handling."),

  h3("7.6.3  Admin Tests"),
  bullet("Component tests for forms, dialogs, and tables."),
  bullet("Manual exploratory testing of the entire workflow on Chrome and Firefox."),

  h3("7.6.4  Manual Testing"),
  p("At the end of every sprint, the team performed a manual end-to-end test on Android devices. The test plan covered the following critical paths:"),

  numbered("Patient signs up, completes onboarding, searches for a doctor, books an appointment, pays via Paymob test card, and chats with the doctor."),
  numbered("Doctor signs up, uploads documents, waits for admin approval, sets availability, accepts an appointment, completes it, and requests a payout."),
  numbered("Admin approves a doctor, processes a payout, deactivates a user, moderates a flagged review."),
  numbered("Edge cases: cancellation just before the appointment, refund, double-booking attempt under concurrent load, network drop during payment."),

  h3("7.6.5  Bug Tracking"),
  p("Defects discovered during testing were tracked as GitHub Issues with labels for area (backend, mobile, admin), severity (blocker, high, medium, low), and milestone. The team triaged the queue weekly and prioritised blockers and high-severity issues for the next sprint. By the end of the project, the backlog contained only minor cosmetic items, all documented in the future-work section."),

  // ----------------------------------------------------------------------- //
  h2("7.7  Deployment Readiness"),
  p("Before submission, the team performed a deployment-readiness checklist:"),

  bullet("Environment variables externalised through appsettings.{Environment}.json and validated at startup."),
  bullet("Database migration script verified on a fresh SQL Server instance."),
  bullet("Cloudinary upload preset, FCM service-account JSON, Paymob secret, and Gemini API key configured."),
  bullet("Android release APK built with R8 obfuscation and signed with the project keystore."),
  bullet("iOS archive verified in Xcode (Apple Developer profile required for store submission, deferred)."),
  bullet("Admin dashboard production build verified."),
  bullet("SSL certificates installed on staging environment."),
  bullet("Smoke test executed end-to-end on the staging environment."),

  // ----------------------------------------------------------------------- //
  h2("7.8  Operational Considerations"),

  h3("7.8.1  Logging"),
  p("The backend uses Serilog for structured logging. Logs are written to the console in development and to rolling files in production. Important events (login, payment, booking, admin action) are logged with correlation IDs that make it easy to trace a single user's journey across multiple endpoints."),

  h3("7.8.2  Error Handling"),
  p("A global exception handler middleware converts uncaught exceptions into ProblemDetails responses with appropriate status codes. The Flutter app maps ProblemDetails into user-friendly error messages through a centralised error mapper."),

  h3("7.8.3  Backup and Recovery"),
  p("Database backups are configured nightly on the production server, with a retention period of fourteen days. Cloudinary maintains its own storage durability guarantees. The SignalR connections are stateless, so a server restart causes a brief reconnect but no data loss."),

  // ----------------------------------------------------------------------- //
  h2("7.9  Conclusion"),
  p("The implementation phase translated the requirements and design of the previous chapters into a working system. The combination of clean architecture, MediatR vertical slices, feature-based Flutter modules, and a disciplined test strategy made it possible to deliver a wide product surface without sacrificing maintainability. The final chapter reflects on the outcomes of the project and lays out the future-work agenda."),

  pageBreak(),
];

module.exports = { chapter7 };
