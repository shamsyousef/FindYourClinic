# Find Your Clinic

Find Your Clinic is a full healthcare platform with:

- A Flutter mobile app for patients and doctors.
- A .NET backend API with real-time chat and domain modules.
- A Next.js admin dashboard for operations and moderation.

This document is the main technical guide for understanding, running, and maintaining the project.

## 1) Repository Structure

```text
Find-Your-Clinic/
+-- Mobile/                         # Flutter app (patients + doctors)
+-- Backend/                        # .NET API + Domain + Infrastructure
|   +-- src/FindYourClinic.API
|   +-- src/FindYourClinic.Domain
|   +-- src/FindYourClinic.Infrastructure
+-- admin/                          # Next.js admin dashboard
+-- docs/                           # Specs and implementation plans
+-- Figma/                          # UI reference exports
```

## 2) High-Level Architecture

### Mobile (Flutter)

- Pattern: `presentation -> domain -> data`
- State management: `flutter_bloc` (Cubit/Bloc)
- DI: `get_it` via `Mobile/lib/core/di/service_locator.dart`
- Routing: `go_router`
- Networking: `dio` with JWT refresh interceptor

Feature folders follow:

```text
features/{feature_name}/
+-- data/
+-- domain/
+-- presentation/
```

### Backend (.NET)

- Projects:
  - `FindYourClinic.API` (controllers, feature handlers, API composition)
  - `FindYourClinic.Domain` (entities, interfaces, enums)
  - `FindYourClinic.Infrastructure` (EF Core, auth, external services)
- Architectural style:
  - MediatR request/handler per feature
  - FluentValidation pipeline
  - Entity Framework Core + SQL Server
  - ASP.NET Identity + JWT

### Admin (Next.js)

- Next.js 14 + React 18 + TypeScript + Tailwind
- Axios client with token injection
- Admin-specific pages: dashboard, approvals, users, specialties, reviews, financial

## 3) Main Product Capabilities

### Patient app

- Authentication (email/password + Google)
- Doctor search and profile viewing
- Appointment booking, viewing, canceling
- Health records CRUD and summary
- In-app chat with doctors (SignalR-backed)
- Notifications (FCM + in-app)
- AI health chat and symptom analysis
- Payments and receipts

### Doctor app

- Doctor onboarding and document upload
- Availability management
- Appointment management (confirm/complete)
- Chat with patients
- Doctor dashboard and insights
- Profile and payment info management
- Earnings and transaction history

### Admin dashboard

- Login restricted to Admin role
- Doctor approval/rejection workflow
- User/doctor activation toggles
- Specialty CRUD
- Review moderation
- Financial overview, transactions, and doctor payouts

## 4) Backend API Modules (Controller Groups)

- `api/auth`
- `api/users`
- `api/doctors`
- `api/doctors/availability`
- `api/appointments`
- `api/messages`
- `api/notifications`
- `api/health-records`
- `api/reviews`
- `api/specialties`
- `api/ai`
- `api/payments`
- `api/admin/users`
- `api/admin/doctors`
- `api/admin/reviews`
- `api/admin/financial`

Swagger is enabled by default:

- `http://localhost:5106/swagger`
- or `http://<host-ip>:5106/swagger`

## 5) Prerequisites

### Required tooling

- Flutter SDK compatible with Dart `3.11.x` (`Mobile/pubspec.yaml`)
- .NET SDK supporting `net10.0` (`Backend/src/*/*.csproj`)
- SQL Server (local or remote)
- Node.js 18+ and npm

### External services used

- Firebase Cloud Messaging
- Cloudinary
- Google OAuth
- SMTP provider (email)
- Gemini API
- Paymob

## 6) Configuration

### 6.1 Backend configuration files

- `Backend/src/FindYourClinic.API/appsettings.json`
- `Backend/src/FindYourClinic.API/appsettings.Development.json`

Important sections:

- `ConnectionStrings:DefaultConnection`
- `JwtSettings`
- `Firebase`
- `Cloudinary`
- `Google`
- `Email`
- `Gemini`
- `Paymob`
- `AdminSeed`

### Security note (important)

Sensitive credentials appear in committed backend config files. Move all secrets to environment variables or user-secrets and rotate compromised credentials immediately.

Recommended:

```bash
dotnet user-secrets --project Backend/src/FindYourClinic.API set "JwtSettings:SecretKey" "..."
dotnet user-secrets --project Backend/src/FindYourClinic.API set "ConnectionStrings:DefaultConnection" "..."
dotnet user-secrets --project Backend/src/FindYourClinic.API set "Cloudinary:ApiSecret" "..."
dotnet user-secrets --project Backend/src/FindYourClinic.API set "Google:ClientSecret" "..."
dotnet user-secrets --project Backend/src/FindYourClinic.API set "Email:Password" "..."
dotnet user-secrets --project Backend/src/FindYourClinic.API set "Paymob:ApiKey" "..."
dotnet user-secrets --project Backend/src/FindYourClinic.API set "Gemini:ApiKey" "..."
```

### 6.2 Mobile base URL

Mobile API base URL is currently hardcoded in:

- `Mobile/lib/core/network/api_client.dart`

Update it to your backend host before running on device/emulator.

### 6.3 Admin base URL

Admin API base URL is currently hardcoded in:

- `admin/src/lib/api.ts`

Set it to the same running backend API host.

## 7) Local Development Setup

### 7.1 Run backend

```bash
cd Backend
dotnet restore
dotnet build
dotnet ef database update --project src/FindYourClinic.Infrastructure --startup-project src/FindYourClinic.API
dotnet run --project src/FindYourClinic.API
```

Default HTTP URL from launch settings:

- `http://0.0.0.0:5106`

### 7.2 Run admin dashboard

```bash
cd admin
npm install
npm run dev
```

Default URL:

- `http://localhost:3000`

### 7.3 Run mobile app

```bash
cd Mobile
flutter pub get
flutter run
```

If using Android emulator, ensure API host is reachable from emulator/device.

## 8) Testing and Quality

### Mobile tests

Exists under:

- `Mobile/test/...`

Run:

```bash
cd Mobile
flutter test
```

### Backend tests

No dedicated backend test project is currently present under `Backend/tests` (gap to address).

### Admin tests

No automated test suite is currently configured (gap to address).

## 9) Runtime and Infrastructure Notes

- Chat hub endpoint: `/hubs/chat`
- JWT is also accepted via query string for hub connections (`access_token`)
- Rate limiting policies are configured for auth and AI routes
- Global exception middleware is enabled
- Background hosted services handle appointment reminders and auto-completion

## 10) Key Paths for Contributors

- Mobile app entry: `Mobile/lib/main.dart`
- Mobile router: `Mobile/lib/core/routing/app_router.dart`
- Mobile DI: `Mobile/lib/core/di/service_locator.dart`
- Backend entry: `Backend/src/FindYourClinic.API/Program.cs`
- Backend DbContext: `Backend/src/FindYourClinic.Infrastructure/Persistence/ApplicationDbContext.cs`
- Admin API client: `admin/src/lib/api.ts`

## 11) Common Troubleshooting

- `401 Unauthorized` in admin:
  - Re-login and ensure backend is reachable.
  - Confirm user role is `Admin`.
- Mobile cannot call API:
  - Verify `api_client.dart` host points to reachable backend IP.
  - Confirm backend is listening on `5106`.
- Database/migration errors:
  - Verify connection string and SQL Server availability.
  - Re-run `dotnet ef database update`.
- Notifications not received:
  - Verify Firebase credentials and token registration API.

## 12) Suggested Next Improvements

- Move all runtime config to environment-driven settings.
- Add backend test project (unit + integration).
- Add admin test coverage (component + API mocks).
- Replace hardcoded frontend API hosts with env variables.
