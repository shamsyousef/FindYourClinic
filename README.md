# Find Your Clinic

> A full-stack healthcare platform connecting patients with doctors — featuring real-time chat, AI health analysis, appointment booking, and a complete admin back-office.
>
> Built with **Flutter** (mobile), **.NET 10** (backend), and **Next.js 14** (admin) — covering the full journey from patient sign-up and doctor onboarding through to appointments, payments, and operational oversight.

---

## Platform Overview

| Layer | Technology | Purpose |
|---|---|---|
| 📱 **Mobile** | Flutter 3.11 · Dart | Patient & doctor apps (iOS + Android) |
| 🖥 **Backend** | .NET 10 · ASP.NET Core | REST API, real-time hub, business logic |
| 🛠 **Admin** | Next.js 14 · TypeScript | Operations dashboard for admins |
| 🗄 **Database** | SQL Server + EF Core | Persistence and migrations |

---

## Table of Contents

1. [Repository Structure](#1-repository-structure)
2. [Architecture](#2-architecture)
3. [Features](#3-features)
4. [Backend API Reference](#4-backend-api-reference)
5. [Prerequisites](#5-prerequisites)
6. [Configuration](#6-configuration)
7. [Local Development Setup](#7-local-development-setup)
8. [Testing](#8-testing)
9. [Runtime Notes](#9-runtime-notes)
10. [Key Paths for Contributors](#10-key-paths-for-contributors)
11. [Troubleshooting](#11-troubleshooting)
12. [Roadmap](#12-roadmap)

---

## 1) Repository Structure

```text
Find-Your-Clinic/
├── Mobile/                         # Flutter app (patients + doctors)
│   ├── lib/
│   │   ├── core/                   # DI, routing, network, theme, utils
│   │   └── features/               # One folder per product feature
│   └── test/
├── Backend/
│   └── src/
│       ├── FindYourClinic.API/      # Controllers, MediatR handlers, middleware
│       ├── FindYourClinic.Domain/   # Entities, interfaces, enums (pure C#)
│       └── FindYourClinic.Infrastructure/  # EF Core, Identity, external services
├── admin/                          # Next.js admin dashboard
│   └── src/
│       ├── app/                    # Next.js App Router pages
│       ├── components/             # Shared UI components
│       └── lib/                    # API client and utilities
├── docs/                           # Specs and implementation plans
└── Figma/                          # UI reference exports
```

---

## 2) Architecture

### Mobile (Flutter)

Follows a strict **presentation → domain → data** layered architecture per feature.

```
features/{feature_name}/
├── data/          # Repositories (impl), DTOs, remote data sources
├── domain/        # Use cases, repository interfaces, entities
└── presentation/  # Cubits, pages, widgets
```

| Concern | Solution |
|---|---|
| State management | `flutter_bloc` — Cubit/Bloc only |
| Dependency injection | `get_it` — registered in `core/di/service_locator.dart` |
| Routing | `go_router` |
| Networking | `dio` with JWT access/refresh interceptor |
| Real-time chat | `signalr_netcore` → `/hubs/chat` |
| Push notifications | Firebase Cloud Messaging + `flutter_local_notifications` |
| Maps | `flutter_map` + `geolocator` |
| Secure storage | `flutter_secure_storage` |
| Media (chat) | `record`, `just_audio`, `video_player` |
| Payments | `webview_flutter` (Paymob iframe) |
| Accessibility / TTS | `speech_to_text`, `flutter_tts` |

**19 product features:**
`auth` · `patient_home` · `doctor_home` · `search` · `appointments` · `chat` · `health_records` · `ai_health` · `notifications` · `payment` · `doctor_onboarding` · `doctor_availability` · `doctor_profile` · `patient_profile` · `nearby_clinics` · `home_highlights` · `settings` · `help_support` · `accessibility`

---

### Backend (.NET 10)

| Concern | Solution |
|---|---|
| Request pipeline | MediatR — one request/handler pair per feature |
| Validation | FluentValidation pipeline behavior |
| Auth | ASP.NET Identity + JWT (access + refresh tokens) |
| ORM | Entity Framework Core — code-first migrations |
| Real-time | ASP.NET Core SignalR (`/hubs/chat`) |
| Rate limiting | Built-in `RateLimiter` — scoped to auth and AI routes |
| Error handling | Global exception middleware |
| Background work | `IHostedService` — appointment reminders, auto-completion |
| File storage | Cloudinary |
| Push notifications | Firebase Admin SDK |
| AI | Gemini API |
| Payments | Paymob |

**Project layers:**

```
FindYourClinic.API          ← composition root, controllers, hubs, middleware
FindYourClinic.Domain       ← pure C#: entities, interfaces, enums, value objects
FindYourClinic.Infrastructure  ← EF Core, Identity, Cloudinary, FCM, Gemini, Paymob
```

---

### Admin Dashboard (Next.js 14)

| Concern | Solution |
|---|---|
| Framework | Next.js 14 App Router + React 18 |
| Language | TypeScript |
| Styling | Tailwind CSS |
| HTTP client | Axios with JWT injection |

**Admin pages:** `dashboard` · `approvals` · `users` · `specialties` · `reviews` · `financial` · `health-records`

---

## 3) Features

### Patient App

- Email/password and Google OAuth sign-in
- Doctor discovery — search by specialty, name, rating, location
- Nearby clinics map view
- Appointment booking, viewing, and cancellation
- Health records CRUD with summaries
- Real-time chat with doctors (text, audio, video)
- In-app and push notifications (FCM)
- AI health chat and symptom analysis (Gemini-powered)
- Payments via Paymob with receipt history
- Accessibility: voice input (speech-to-text) and TTS read-back

### Doctor App

- Guided onboarding with document/credential upload
- Availability slot management
- Appointment management — confirm and complete
- Real-time chat with patients
- Earnings dashboard and transaction history
- Profile and payment info management

### Admin Dashboard

- Login restricted to the `Admin` role
- Doctor approval / rejection workflow with notes
- User and doctor activation toggles
- Specialty CRUD
- Review moderation (view and delete)
- Financial overview — transactions and doctor payouts

---

## 4) Backend API Reference

All endpoints are prefixed with `/api/`. Swagger UI is available at:

```
http://localhost:5106/swagger
http://<host-ip>:5106/swagger
```

| Group | Base route |
|---|---|
| Auth | `/api/auth` |
| Users | `/api/users` |
| Doctors | `/api/doctors` |
| Doctor availability | `/api/doctors/availability` |
| Appointments | `/api/appointments` |
| Chat messages | `/api/messages` |
| Notifications | `/api/notifications` |
| Health records | `/api/health-records` |
| Reviews | `/api/reviews` |
| Specialties | `/api/specialties` |
| AI health | `/api/ai` |
| Payments | `/api/payments` |
| Admin — users | `/api/admin/users` |
| Admin — doctors | `/api/admin/doctors` |
| Admin — reviews | `/api/admin/reviews` |
| Admin — financial | `/api/admin/financial` |
| SignalR hub | `/hubs/chat` |

> **JWT via query string for the hub:** clients may pass `?access_token=<token>` when establishing the SignalR connection.

---

## 5) Prerequisites

### Tooling

| Tool | Required version |
|---|---|
| Flutter SDK | compatible with Dart `^3.11.4` |
| .NET SDK | `net10.0` |
| SQL Server | 2019+ (local or remote) |
| Node.js | 18+ |
| npm | bundled with Node 18+ |
| `dotnet-ef` CLI | `dotnet tool install -g dotnet-ef` |

### External Services

| Service | Used for |
|---|---|
| Firebase | Push notifications (FCM) + Google OAuth |
| Cloudinary | Doctor document and avatar uploads |
| Google OAuth | Social login |
| SMTP provider | Email verification and notifications |
| Gemini API | AI health chat and symptom analysis |
| Paymob | In-app payment processing |

---

## 6) Configuration

### 6.1 Backend — `appsettings.json` sections

```
Backend/src/FindYourClinic.API/
├── appsettings.json
└── appsettings.Development.json
```

| Section | Key settings |
|---|---|
| `ConnectionStrings` | `DefaultConnection` |
| `JwtSettings` | `SecretKey`, `Issuer`, `Audience`, expiry durations |
| `Firebase` | service-account credentials |
| `Cloudinary` | `CloudName`, `ApiKey`, `ApiSecret` |
| `Google` | `ClientId`, `ClientSecret` |
| `Email` | `Host`, `Port`, `Username`, `Password` |
| `Gemini` | `ApiKey` |
| `Paymob` | `ApiKey`, `IntegrationId`, `IframeId` |
| `AdminSeed` | initial admin email/password |

> **⚠ Security — action required**
>
> Sensitive credentials are currently in committed config files. Before going to production, migrate every secret to environment variables or `dotnet user-secrets` and **rotate any exposed keys immediately**.

```bash
dotnet user-secrets --project Backend/src/FindYourClinic.API set "JwtSettings:SecretKey"              "..."
dotnet user-secrets --project Backend/src/FindYourClinic.API set "ConnectionStrings:DefaultConnection" "..."
dotnet user-secrets --project Backend/src/FindYourClinic.API set "Cloudinary:ApiSecret"               "..."
dotnet user-secrets --project Backend/src/FindYourClinic.API set "Google:ClientSecret"                "..."
dotnet user-secrets --project Backend/src/FindYourClinic.API set "Email:Password"                     "..."
dotnet user-secrets --project Backend/src/FindYourClinic.API set "Paymob:ApiKey"                      "..."
dotnet user-secrets --project Backend/src/FindYourClinic.API set "Gemini:ApiKey"                      "..."
```

### 6.2 Mobile — API base URL

Hardcoded in [`Mobile/lib/core/network/api_client.dart`](Mobile/lib/core/network/api_client.dart).  
Update the base URL to your running backend host before launching on a device or emulator.

### 6.3 Admin — API base URL

Hardcoded in [`admin/src/lib/api.ts`](admin/src/lib/api.ts).  
Set it to the same backend host.

> **Recommended:** Move both base URLs to `.env` / `.env.local` files and reference them via environment variables — eliminates the need to touch source code per environment.

---

## 7) Local Development Setup

### 7.1 Backend

```bash
cd Backend

# Restore and build
dotnet restore
dotnet build

# Apply EF Core migrations
dotnet ef database update \
  --project src/FindYourClinic.Infrastructure \
  --startup-project src/FindYourClinic.API

# Run
dotnet run --project src/FindYourClinic.API
```

Default listener: **`http://0.0.0.0:5106`**  
Swagger: **`http://localhost:5106/swagger`**

---

### 7.2 Admin Dashboard

```bash
cd admin
npm install
npm run dev
```

Default URL: **`http://localhost:3000`**

---

### 7.3 Mobile App

```bash
cd Mobile
flutter pub get
flutter run
```

> **Emulator tip:** Android emulators reach the host machine at `10.0.2.2`. If your backend listens on `localhost:5106`, set the base URL to `http://10.0.2.2:5106` inside `api_client.dart` when running on an emulator.

---

## 8) Testing

### Mobile

Tests live under `Mobile/test/`.

```bash
cd Mobile
flutter test
```

### Backend

No dedicated test project exists yet under `Backend/tests/` — this is an open gap. The recommended approach when adding tests:

- **Unit tests** for domain use-case logic
- **Integration tests** using `WebApplicationFactory<Program>` + an in-memory or containerised SQL Server

### Admin

No automated test suite is configured yet. Recommended starting point: Vitest + React Testing Library for component tests and mocked API handlers.

---

## 9) Runtime Notes

| Topic | Detail |
|---|---|
| SignalR hub | `/hubs/chat` — JWT accepted via `?access_token=<token>` query param |
| Rate limiting | Applied to `/api/auth/*` and `/api/ai/*` routes |
| Global error handling | Middleware converts unhandled exceptions to RFC 7807 problem details |
| Background services | Appointment reminders (T-24 h, T-1 h) and auto-completion of past appointments |
| CORS | Configured in `Program.cs` — update allowed origins before deploying |

---

## 10) Key Paths for Contributors

| Path | Purpose |
|---|---|
| [`Mobile/lib/main.dart`](Mobile/lib/main.dart) | Mobile entry point |
| [`Mobile/lib/core/routing/app_router.dart`](Mobile/lib/core/routing/app_router.dart) | All app routes (go_router) |
| [`Mobile/lib/core/di/service_locator.dart`](Mobile/lib/core/di/service_locator.dart) | get_it registrations |
| [`Mobile/lib/core/network/api_client.dart`](Mobile/lib/core/network/api_client.dart) | Dio client + interceptors |
| [`Backend/src/FindYourClinic.API/Program.cs`](Backend/src/FindYourClinic.API/Program.cs) | Backend composition root |
| [`Backend/src/FindYourClinic.Infrastructure/Persistence/ApplicationDbContext.cs`](Backend/src/FindYourClinic.Infrastructure/Persistence/ApplicationDbContext.cs) | EF Core DbContext |
| [`Backend/src/FindYourClinic.API/Hubs/`](Backend/src/FindYourClinic.API/Hubs/) | SignalR chat hub |
| [`Backend/src/FindYourClinic.API/Middleware/`](Backend/src/FindYourClinic.API/Middleware/) | Global exception handler |
| [`admin/src/lib/api.ts`](admin/src/lib/api.ts) | Admin Axios client |
| [`admin/src/app/(dashboard)/page.tsx`](admin/src/app/(dashboard)/page.tsx) | Admin dashboard home |

---

## 11) Troubleshooting

**`401 Unauthorized` in admin**
- Re-login and verify the backend is reachable from the browser.
- Confirm the authenticated user has the `Admin` role in the database.

**Mobile cannot reach the API**
- Check `api_client.dart` base URL — use `10.0.2.2` for Android emulators, not `localhost`.
- Confirm the backend process is running and listening on port `5106`.
- Ensure no firewall is blocking the port.

**Database / migration errors**
- Verify `ConnectionStrings:DefaultConnection` is correct and SQL Server is running.
- Re-run `dotnet ef database update` after pulling new migrations.

**Push notifications not received**
- Check Firebase service-account credentials in `appsettings.json`.
- Confirm device FCM token registration is hitting `/api/notifications` successfully.

**SignalR connection fails**
- Ensure the JWT is passed via `Authorization` header or `?access_token=` query param.
- Check CORS — the hub endpoint must allow the client origin.

---

## 12) Roadmap

- [ ] Migrate all runtime secrets to environment variables 
- [ ] Add backend test project — unit tests for domain use cases + integration tests for API endpoints
- [ ] Add admin test coverage — Vitest + React Testing Library
- [ ] Replace hardcoded frontend API base URLs with `.env` / `.env.local`
- [ ] CI/CD pipeline — GitHub Actions: lint → test → build for all three platforms

