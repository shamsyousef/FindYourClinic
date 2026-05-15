const {
  chapterTitle, h2, h3, h4, p, lead, bullet, numbered, pageBreak, note, kvTable, imagePlaceholder,
} = require("./helpers");

const chapter6 = () => [
  chapterTitle("Chapter 6: Technological Foundations"),

  // ----------------------------------------------------------------------- //
  h2("6.1  Overview"),
  lead("Find Your Clinic is built on a modern, production-ready technology stack designed for scalability, security, and developer velocity. This chapter walks through every layer of the stack — from the Flutter mobile application at the top, through the Next.js admin dashboard, into the .NET 10 backend API, down to the SQL Server database, and out to the external integrations that complete the picture. For each layer, we explain what technologies were chosen, why they were chosen, and how they fit into the overall system."),

  ...imagePlaceholder("19", "System Architecture of the Find Your Clinic platform — three clients, one API, one database, six integrations"),

  // ----------------------------------------------------------------------- //
  h2("6.2  Backend API — .NET 10 and ASP.NET Core"),
  p("The backend is the heart of the system. It is implemented in C# on .NET 10 using ASP.NET Core for HTTP, MediatR for command/query orchestration, ASP.NET Identity for users and roles, Entity Framework Core 10 for data access, and SignalR for real-time communication. The backend lives in a single Visual Studio solution under Backend/ with three projects: FindYourClinic.Domain (pure C# entities), FindYourClinic.Infrastructure (EF Core, Identity, integrations), and FindYourClinic.API (controllers, hubs, features, middleware)."),

  h3("6.2.1  Why .NET 10"),
  bullet("Mature ecosystem with first-class support for dependency injection, configuration, logging, authentication, authorisation, real-time communication, and background work — all from a single trusted vendor."),
  bullet("Exceptional performance: ASP.NET Core consistently ranks among the fastest web frameworks in the TechEmpower benchmarks."),
  bullet("Robust tooling: Visual Studio, Rider, and the .NET CLI provide a smooth development experience."),
  bullet("Strong type system and modern language features (records, pattern matching, nullable reference types) that catch bugs at compile time."),

  h3("6.2.2  Project Layout"),
  p("The backend follows clean-architecture layering. Domain has no dependencies on any framework. Infrastructure depends on Domain. API depends on both. Tests are kept in a separate folder mirroring this structure."),

  bullet("FindYourClinic.Domain — entities, enums, interfaces, value objects. Pure POCOs."),
  bullet("FindYourClinic.Infrastructure — ApplicationDbContext (EF Core), Identity configuration, JwtService, CloudinaryService, EmailService, GoogleAuthService, NotificationService, repositories."),
  bullet("FindYourClinic.API — controllers (thin), SignalR hubs (ChatHub), MediatR features (Auth, Admin, AiHealth, Appointments, DoctorVerification, Doctors, DoctorAvailability, HealthRecords, Notifications, Payments, Reviews, Specialties, Users), middleware (global exception handler, request logging), Program.cs."),

  h3("6.2.3  Vertical Slices with MediatR"),
  p("Every backend feature is implemented as a vertical slice. A slice is a small folder containing the command or query class, the handler class, the validator (FluentValidation), and any feature-specific DTOs. This keeps growth linear: adding a new feature does not require touching dozens of files in different layers — it requires creating one new folder. Controllers are kept thin and simply dispatch the request to MediatR."),

  numbered("The controller receives the HTTP request and converts it into a command or query."),
  numbered("MediatR routes the request to the matching handler."),
  numbered("The handler validates input, calls repositories and services, and returns a response."),
  numbered("Controller serialises the response to JSON."),

  h3("6.2.4  Authentication and Authorisation"),
  p("Authentication uses ASP.NET Identity backed by SQL Server. Users are stored in the AspNetUsers table extended with healthcare-specific columns through the ApplicationUser entity. After successful login, the JwtService issues a JSON Web Token (JWT) signed with HMAC-SHA256, plus a longer-lived refresh token persisted in the RefreshTokens table. The access token carries the user ID and role in its claims, and is validated on every request through the JwtBearer middleware. For SignalR connections, the JWT can be provided in the access_token query parameter, allowing browser and mobile clients to authenticate WebSocket connections."),

  p("Authorisation is performed through ASP.NET Core authorisation policies. Each role (Patient, Doctor, Admin) is captured in a policy and applied at the controller or endpoint level. Some endpoints have richer authorisation rules — for example, the chat endpoints check that the requesting user is a participant in the conversation."),

  h3("6.2.5  Real-Time Communication with SignalR"),
  p("ChatHub is the SignalR hub that powers real-time messaging. It is registered at the path /hubs/chat and uses a custom NameIdentifierUserIdProvider to map the JWT sub claim to the SignalR user identity. The hub exposes methods for sending messages, joining a conversation, and acknowledging delivery. On the client side, the Flutter app uses the signalr_netcore package, and the admin dashboard could optionally use the JavaScript SignalR client (we have not yet exposed chat to the admin)."),

  h3("6.2.6  Background Work and Resilience"),
  p("Long-running and resilient operations are implemented as background tasks scheduled through hosted services. The NotificationService dispatches FCM messages asynchronously. The Paymob webhook handler verifies and processes payment confirmations idempotently — duplicate webhooks do not cause duplicate appointment confirmations. Failures are logged and retried with exponential backoff."),

  // ----------------------------------------------------------------------- //
  h2("6.3  Mobile Application — Flutter"),
  p("The Flutter mobile app is the primary surface for patients and doctors. It is implemented in Dart on Flutter, targeting both Android and iOS from a single codebase. The app uses Cubit/Bloc for state management, GoRouter for navigation, GetIt for dependency injection, Dio for HTTP, signalr_netcore for real-time chat, firebase_messaging for push notifications, and a wide range of platform integrations (location, voice, payments)."),

  h3("6.3.1  Why Flutter"),
  bullet("True cross-platform development from a single codebase — Android and iOS share over 95% of the code."),
  bullet("Native performance through the Skia rendering engine and ahead-of-time compilation."),
  bullet("A rich, expressive widget library that makes Material 3 implementation straightforward."),
  bullet("Excellent developer experience with hot reload, sound null safety, and strong tooling in VS Code and Android Studio."),

  h3("6.3.2  Project Layout"),
  p("The Mobile/lib folder follows the feature-based clean architecture defined in CLAUDE.md. Shared infrastructure lives in core/, and every feature has its own folder under features/."),

  bullet("core/di — GetIt service locator, registering repositories, use cases, cubits, the API client, and platform services."),
  bullet("core/routing — GoRouter configuration with role-aware redirects and shell routes."),
  bullet("core/network — Dio HTTP client with JWT interceptors and refresh-on-401 logic."),
  bullet("core/theme — Material 3 colour tokens, typography, and dark-mode definitions."),
  bullet("core/utils — token storage, validators, formatters, error mappers."),
  bullet("core/widgets — reusable UI components (buttons, fields, dialogs, loading indicators)."),
  bullet("features/auth, features/doctor_onboarding, features/patient_home, features/doctor_home, features/search, features/doctor_profile, features/patient_profile, features/appointments, features/booking, features/doctor_availability, features/chat, features/health_records, features/ai_health, features/notifications, features/payment, features/nearby_clinics, features/accessibility, features/settings, features/help_support — each with data/, domain/, presentation/ subfolders."),

  h3("6.3.3  State Management — Cubit / Bloc"),
  p("State management uses the Cubit/Bloc pattern (flutter_bloc ^9). Cubits depend only on use cases, never directly on repositories, which keeps presentation logic insulated from data-layer details. State unions use Dart 3 sealed classes for exhaustive pattern matching, so every state (Loading, Success, Empty, Error) is handled explicitly by the UI. We deliberately avoided Freezed and code generation to keep the build process fast."),

  h3("6.3.4  Dependency Injection — GetIt"),
  p("All dependencies are registered through the GetIt service locator in core/di/service_locator.dart. The locator registers the Dio HTTP client, every repository, every use case, every cubit, the secure token storage, and platform plug-ins. This keeps cubits and repositories free of constructor wiring code, and makes mocking trivial during tests."),

  h3("6.3.5  Networking"),
  p("HTTP communication uses the Dio package with two interceptors: one that injects the JWT access token in the Authorization header, and one that detects 401 responses and transparently refreshes the access token using the stored refresh token. The base URL is configurable per build flavour, and a logging interceptor produces curl-style traces in debug builds for easy diagnosis."),

  h3("6.3.6  Real-Time Chat Client"),
  p("The Flutter chat client uses signalr_netcore to maintain a single connection to the backend ChatHub. The client subscribes to conversation events, receives messages with delivery and read receipts, and triggers UI updates through the relevant Cubit. Voice notes are recorded with the record package, played back with just_audio, and uploaded to Cloudinary using a multi-part HTTP request."),

  h3("6.3.7  Push Notifications"),
  p("Firebase Cloud Messaging delivers push notifications to both Android and iOS. At login, the app registers its FCM token with the backend; the backend stores the token against the user record and uses it to target individual notifications. On Android the app handles both foreground and background notifications through a foreground service notification on Android 14+."),

  h3("6.3.8  Voice and Accessibility"),
  p("Voice input is provided by the speech_to_text package, transforming the user's speech into a text query. The AI assistant uses Flutter TTS to read responses aloud. A floating action button on the patient home gives one-tap access to the voice assistant from anywhere. These integrations transform the app from a tap-only experience into a hands-free one — particularly useful for elderly users or users with limited mobility."),

  // ----------------------------------------------------------------------- //
  h2("6.4  Admin Dashboard — Next.js 14"),
  p("The admin dashboard is a Next.js 14 web application using the App Router. It is implemented in TypeScript with React 18, styled with Tailwind CSS, iconed with Lucide React, and powered by Axios for API communication. Charts use Recharts. The dashboard is designed to be used on a desktop or large tablet — most admin workflows benefit from wide tables and side-by-side document viewing."),

  h3("6.4.1  Why Next.js 14"),
  bullet("App Router with server components by default, reducing client bundle size and improving time-to-first-paint."),
  bullet("Built-in routing with file-based conventions, route groups, and layouts."),
  bullet("First-class TypeScript support."),
  bullet("Excellent deployment options (Vercel, self-hosted Node, containerised)."),

  h3("6.4.2  Project Layout"),
  bullet("src/app/(dashboard)/ — protected route group with the sidebar layout."),
  bullet("src/app/(dashboard)/page.tsx — dashboard overview with KPIs."),
  bullet("src/app/(dashboard)/approvals/ — doctor approval queue."),
  bullet("src/app/(dashboard)/users/ — user management."),
  bullet("src/app/(dashboard)/specialties/ — specialty CRUD."),
  bullet("src/app/(dashboard)/reviews/ — review moderation."),
  bullet("src/app/(dashboard)/financial/ — revenue, wallets, payouts."),
  bullet("src/app/(dashboard)/health-records/ — support-only health record lookup."),
  bullet("src/app/login/ — authentication page restricted to the Admin role."),
  bullet("src/lib/api.ts — Axios instance with Bearer token injection and 401 redirect."),

  h3("6.4.3  Server and Client Components"),
  p("In line with the CLAUDE.md guidelines, the admin dashboard uses server components by default and adds 'use client' only where interactivity is needed. Most data fetching happens on the server, with client components reserved for forms, dialogs, and interactive charts."),

  // ----------------------------------------------------------------------- //
  h2("6.5  Database — SQL Server"),
  p("Find Your Clinic uses Microsoft SQL Server 2022 as the primary relational store. Entity Framework Core 10 manages the schema through migrations checked into source control. The DbContext (ApplicationDbContext) extends IdentityDbContext to integrate ASP.NET Identity tables with healthcare-specific tables. Indexes are defined on every column used for filtering or sorting (Specialty, City, Status, CreatedAt). UTC timestamps are stored consistently throughout."),

  h3("6.5.1  Why SQL Server"),
  bullet("Strong relational guarantees and rich constraint support, essential for healthcare data integrity."),
  bullet("Mature ecosystem and excellent integration with EF Core."),
  bullet("Free Developer and Express editions cover development and small-scale production deployments."),
  bullet("Cloud-hosted options (Azure SQL Database, AWS RDS for SQL Server) make scaling straightforward."),

  h3("6.5.2  Migrations"),
  p("Schema evolution is managed through EF Core migrations under FindYourClinic.Infrastructure/Persistence/Migrations. A new migration is generated whenever a domain entity changes, and applied to the database with the dotnet ef database update command. The migration history is reviewed in code review like any other code change."),

  // ----------------------------------------------------------------------- //
  h2("6.6  Real-Time Communication — SignalR"),
  p("SignalR was chosen over raw WebSockets because it provides automatic reconnection, transport negotiation (WebSockets when possible, Server-Sent Events as a fallback), and tight integration with ASP.NET Core authentication. The ChatHub exposes a small set of methods — SendMessage, JoinConversation, MarkAsRead — that map directly to user actions in the Flutter chat screen."),

  // ----------------------------------------------------------------------- //
  h2("6.7  AI Integration — Google Gemini"),
  p("The AI Health Assistant is powered by the Google Gemini API. The integration lives in the GeminiService class on the backend. The service wraps the official Gemini REST API and adds three layers of value: (a) a medical system prompt that constrains the assistant to safe, empathetic, non-diagnostic responses; (b) conversation history support, persisted in the AiChatMessages table; and (c) retry-and-fallback logic, where the service automatically falls back to a configured secondary model if the primary model is rate-limited."),

  h3("6.7.1  Medical System Prompt"),
  p("The system prompt instructs the model to behave as a compassionate health information assistant — to listen carefully, to summarise the patient's situation in plain language, to suggest possible specialties to consult, to avoid prescribing specific drugs, and to escalate to emergency services for red-flag symptoms. The prompt is version-controlled in the GeminiService source file."),

  h3("6.7.2  Retry and Fallback"),
  p("If the call to the primary Gemini model fails (HTTP 429, 500, 503, or a network timeout), the service retries with exponential backoff. If retries are exhausted, the service falls back to a configured secondary model. If both fail, a graceful error message is returned to the user with a suggestion to try again in a moment."),

  h3("6.7.3  Voice Integration"),
  p("The assistant supports voice in two directions. On the input side, the Flutter speech_to_text package converts the user's voice into text before sending it to the API. On the output side, Flutter TTS reads the assistant's reply aloud. The combination delivers a hands-free conversational experience that is especially useful when the user cannot type — for example, while caring for a child or recovering from surgery."),

  // ----------------------------------------------------------------------- //
  h2("6.8  External Integrations"),

  h3("6.8.1  Cloudinary"),
  p("Cloudinary handles all image and document storage. Profile pictures, document scans, and health record attachments are uploaded directly from the mobile app to Cloudinary using a signed upload preset, and the resulting secure URL is stored on the backend. Cloudinary's CDN ensures fast delivery regardless of the user's geographic location."),

  h3("6.8.2  Firebase Cloud Messaging"),
  p("FCM delivers push notifications. The backend NotificationService composes the payload and submits it to the FCM HTTP v1 API. Devices register their tokens on login, and the backend stores them in the user record so that subsequent notifications can be targeted with precision."),

  h3("6.8.3  Paymob"),
  p("Paymob is the payment gateway integration. The backend creates a payment intent, redirects the patient through a WebView to the Paymob hosted checkout, and finalises the transaction asynchronously when Paymob calls back via webhook. The webhook handler validates the signature, looks up the matching PendingBookingIntent, promotes the appointment to Confirmed, credits the doctor's wallet, and dispatches notifications."),

  h3("6.8.4  Google OAuth"),
  p("Google OAuth 2.0 provides one-tap sign-in. The Flutter google_sign_in package returns an ID token, which the backend validates against Google's public keys before issuing the local JWT."),

  h3("6.8.5  SMTP Email"),
  p("Transactional emails (verification, password reset, doctor decision notification) are sent through an SMTP provider configured in appsettings.json. The EmailService abstracts the provider behind a simple ISendEmail interface so that we can swap providers without touching call sites."),

  // ----------------------------------------------------------------------- //
  h2("6.9  Security Foundations"),
  p("Healthcare data is sensitive, and the platform treats security as a first-class concern. Several defensive layers are baked into the design:"),

  bullet("HTTPS-only transport, enforced at the API and the CDN."),
  bullet("Strong password hashing via ASP.NET Identity (PBKDF2 with a per-user salt)."),
  bullet("Short-lived JWT access tokens with rotated refresh tokens."),
  bullet("Role-based authorisation policies on every sensitive endpoint."),
  bullet("Resource-level authorisation in chat and health records (you can only read what you own or have permission to view)."),
  bullet("Signed Cloudinary URLs for medical documents and personal photos."),
  bullet("Idempotent payment webhook handler that resists duplicate calls and replay attacks."),
  bullet("Audit logging on every admin action."),
  bullet("Secrets stored in environment variables or appsettings.Development.json (never committed)."),

  pageBreak(),
];

module.exports = { chapter6 };
