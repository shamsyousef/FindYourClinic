# FindYourClinic API Documentation

## Common Response Pattern

Most endpoints return:

- `ApiResponse<T>`
  - `success` (bool)
  - `message` (string?)
  - `data` (`T`)
  - `errors` (list?)

Some endpoints may return `Unauthorized` / `BadRequest` / `NotFound` depending on validation and authorization.

Core entities/tables used across modules:

- `DoctorProfiles`
- `Specialties`
- `DoctorDocuments`
- `Appointments`
- `DoctorAvailabilities`
- `DoctorReviews`
- `HealthRecords`
- `Conversations`
- `ChatMessages`
- `Notifications`
- `ApplicationUser` (`Users` / `AspNetUsers`)
- `RefreshTokens`
- `PasswordResetTokens`

---

## Controllers

## AuthController (`/api/auth`)

### `POST /api/auth/register`
- **Purpose:** Register patient or doctor account.
- **Request Body:** `RegisterCommand`
  - `firstName?`, `lastName?`, `fullName?`, `specialtyId?`, `email`, `password`, `role`
- **Response:** `ApiResponse<RegisterResultDto>`
- **Related entities:** `ApplicationUser`, `DoctorProfiles`, `Specialties`
- **Flow:** Controller sends command to handler; handler validates role/data, creates user, creates doctor profile if needed, returns auth result or pending token.

### `POST /api/auth/login`
- **Purpose:** Email/password login.
- **Request Body:** `LoginCommand` (`email`, `password`)
- **Response:** `ApiResponse<AuthResponse>`
- **Related entities:** `ApplicationUser`, `RefreshTokens`
- **Flow:** Validate credentials and account status, generate JWT + refresh token.

### `POST /api/auth/google`
- **Purpose:** Login/register with Google token.
- **Request Body:** `GoogleLoginCommand` (`idToken`, `role?`)
- **Response:** `ApiResponse<GoogleLoginResultDto>`
- **Related entities:** `ApplicationUser`, `DoctorProfiles`
- **Flow:** Verify Google token, resolve/create user, return auth or pending flow.

### `POST /api/auth/doctor/upload-documents`
- **Purpose:** Doctor uploads verification documents.
- **Request Form-data:** `files[]`, `documentTypes[]`
- **Response:** `ApiResponse<List<UploadedDoctorDocumentDto>>`
- **Related entities:** `DoctorProfiles`, `DoctorDocuments`
- **Flow:** Resolve doctor id from claims, upload files, save document metadata rows.

### `POST /api/auth/forgot-password`
- **Purpose:** Start password reset.
- **Request Body:** `ForgotPasswordCommand` (`email`)
- **Response:** `ApiResponse<object>`
- **Related entities:** `ApplicationUser`, `PasswordResetTokens`
- **Flow:** Generate reset token and send email.

### `POST /api/auth/reset-password`
- **Purpose:** Complete password reset.
- **Request Body:** `ResetPasswordCommand` (`token`, `newPassword`)
- **Response:** `ApiResponse<object>`
- **Related entities:** `ApplicationUser`, `PasswordResetTokens`
- **Flow:** Validate token, update password.

### `POST /api/auth/refresh-token`
- **Purpose:** Get new access token from refresh token.
- **Request Body:** `RefreshTokenCommand` (`refreshToken`)
- **Response:** `ApiResponse<AuthResponse>`
- **Related entities:** `RefreshTokens`, `ApplicationUser`
- **Flow:** Validate refresh token and issue new auth tokens.

---

## UsersController (`/api/users`) [Authorize]

### `GET /api/users/profile`
- **Purpose:** Get current user profile.
- **Route/Query Params:** none
- **Response:** `ApiResponse<UserProfileDto>`
- **Related entities:** `ApplicationUser`
- **Flow:** Read user id from claim, query profile by id.

### `PUT /api/users/profile`
- **Purpose:** Update current user name.
- **Request Body:** `UpdateProfileRequest` (`firstName`, `lastName`)
- **Response:** `ApiResponse<object>`
- **Related entities:** `ApplicationUser`
- **Flow:** Read user id from claim, update user fields.

---

## NotificationsController (`/api/notifications`) [Authorize]

### `POST /api/notifications/device-token`
- **Purpose:** Save/update push token.
- **Request Body:** `UpdateDeviceTokenCommand` (`token`)
- **Response:** `ApiResponse<string>`
- **Related entities:** `ApplicationUser`, `Notifications` subsystem
- **Flow:** Store token for current user.

### `DELETE /api/notifications/device-token`
- **Purpose:** Remove push token.
- **Response:** `ApiResponse<string>`
- **Related entities:** `ApplicationUser`
- **Flow:** Clear token fields.

### `GET /api/notifications?page=&pageSize=`
- **Purpose:** Get paginated notifications.
- **Query Params:** `page`, `pageSize`
- **Response:** `ApiResponse<NotificationsPageDto>`
- **Related entities:** `Notifications`
- **Flow:** Query by user id with paging.

### `PUT /api/notifications/{id}/read`
- **Purpose:** Mark notification as read.
- **Route Params:** `id`
- **Response:** `ApiResponse<string>`
- **Related entities:** `Notifications`
- **Flow:** Validate ownership then update `IsRead`.

---

## DoctorsController (`/api/doctors`)

### `GET /api/doctors`
- **Purpose:** Search doctors with filters/sorting/paging.
- **Query Params:** `specialtyId`, `lat`, `lng`, `radiusKm`, `minRating`, `minFee`, `maxFee`, `availability`, `sortBy`, `page`, `pageSize`
- **Response:** `ApiResponse<PaginatedResponse<DoctorSearchDto>>`
- **Related entities:** `DoctorProfiles`, `Specialties`, `ApplicationUser`, `DoctorReviews`, `DoctorAvailabilities`, `Appointments`
- **Flow:** Build doctor query, join ratings, apply geo and other filters, compute next slot hints, paginate and return DTOs.

### `GET /api/doctors/top-rated`
- **Purpose:** Get top-rated doctors with cursor paging.
- **Query Params:** `pageSize`, `cursor`
- **Response:** `ApiResponse<CursorPaginatedResponse<TopRatedDoctorDto>>`
- **Related entities:** `DoctorProfiles`, `DoctorReviews`
- **Flow:** Aggregate ratings, apply cursor filter, sort, return current page and next cursor.

### `GET /api/doctors/{id}`
- **Purpose:** Get public doctor details.
- **Route Params:** `id` (doctor user id)
- **Response:** `ApiResponse<DoctorDetailsDto>`
- **Related entities:** `DoctorProfiles`, `DoctorReviews`, `DoctorAvailabilities`, `Appointments`
- **Flow:** Load approved doctor details, compute rating summary and next available slot.

### `GET /api/doctors/{id}/availability`
- **Purpose:** Get doctor slots for a date.
- **Route Params:** `id`
- **Query Params:** `date?`
- **Response:** `ApiResponse<List<DateTime>>`
- **Related entities:** `DoctorProfiles`, `DoctorAvailabilities`, `Appointments`
- **Flow:** Resolve doctor profile and build available slots from schedule minus booked appointments.

### `PUT /api/doctors/profile` [Authorize]
- **Purpose:** Doctor updates own profile.
- **Request Body:** `UpdateOwnDoctorProfileCommand`
  - `specialtyId`, `clinicName?`, `clinicAddress?`, `latitude?`, `longitude?`, `consultationFee`, `experienceYears`, `bio?`
- **Response:** `ApiResponse<object>`
- **Related entities:** `DoctorProfiles`, `Specialties`
- **Flow:** Validate role + specialty, update doctor profile fields.

---

## DoctorAvailabilityController (`/api/doctors/availability`)

### `GET /api/doctors/availability/{doctorId}/slots`
- **Purpose:** Get available slots for a doctor on a specific date.
- **Route Params:** `doctorId`
- **Query Params:** `date`
- **Response:** `ApiResponse<List<DateTime>>`
- **Related entities:** `DoctorProfiles`, `DoctorAvailabilities`, `Appointments`
- **Flow:** Resolve doctor profile, generate 30-minute candidate slots, remove booked and past slots.

### `POST /api/doctors/availability` [Authorize]
- **Purpose:** Create availability window.
- **Request Body:** `UpsertAvailabilityRequest` (`dayOfWeek`, `startTime`, `endTime`, `isActive`)
- **Response:** `ApiResponse<AvailabilityDto>`
- **Related entities:** `DoctorProfiles`, `DoctorAvailabilities`
- **Flow:** Validate doctor role and time range, insert availability row.

### `PUT /api/doctors/availability/{id}` [Authorize]
- **Purpose:** Update availability window.
- **Route Params:** `id`
- **Request Body:** `UpsertAvailabilityRequest`
- **Response:** `ApiResponse<AvailabilityDto>`
- **Related entities:** `DoctorAvailabilities`, `DoctorProfiles`
- **Flow:** Validate owner doctor and time range, update availability row.

---

## AdminDoctorsController (`/api/admin/doctors`) [AdminOnly]

### `GET /api/admin/doctors/pending`
- **Purpose:** List pending doctor verification requests.
- **Response:** `ApiResponse<List<PendingDoctorDto>>`
- **Related entities:** `DoctorProfiles`, `DoctorDocuments`, `Specialties`, `ApplicationUser`
- **Flow:** Query pending profiles and include docs + specialty/user data.

### `POST /api/admin/doctors/{doctorId}/approve`
- **Purpose:** Approve doctor account.
- **Route Params:** `doctorId`
- **Response:** `ApiResponse<object>`
- **Related entities:** `DoctorProfiles`, `ApplicationUser`, `Notifications`
- **Flow:** Update doctor status to approved and notify doctor.

### `POST /api/admin/doctors/{doctorId}/reject`
- **Purpose:** Reject doctor account.
- **Route Params:** `doctorId`
- **Request Body:** `RejectDoctorRequest` (`reason`)
- **Response:** `ApiResponse<object>`
- **Related entities:** `DoctorProfiles`, `ApplicationUser`, `Notifications`
- **Flow:** Mark profile rejected with reason and notify doctor.

---

## AppointmentsController (`/api/appointments`) [Authorize]

### `POST /api/appointments`
- **Purpose:** Patient books appointment.
- **Request Body:** `BookAppointmentRequest` (`doctorProfileId`, `scheduledAt`, `locationName?`)
- **Response:** `ApiResponse<AppointmentDto>`
- **Related entities:** `Appointments`, `DoctorProfiles`, `DoctorAvailabilities`, `Notifications`
- **Flow:** Validate patient role and slot validity, prevent overlap, create appointment, notify doctor.

### `GET /api/appointments/my`
- **Purpose:** Get patient appointments.
- **Response:** `ApiResponse<List<AppointmentDto>>`
- **Related entities:** `Appointments`, `DoctorProfiles`, `Specialties`, `ApplicationUser`
- **Flow:** Validate patient role, query by patient id, include doctor and specialty details.

### `GET /api/appointments/doctor/my`
- **Purpose:** Get doctor appointments.
- **Response:** `ApiResponse<List<AppointmentDto>>`
- **Related entities:** `DoctorProfiles`, `Appointments`, `ApplicationUser`
- **Flow:** Validate doctor role, resolve doctor profile id, query appointments for that profile.

### `PUT /api/appointments/{id}/cancel`
- **Purpose:** Cancel appointment (patient or doctor owner).
- **Route Params:** `id`
- **Response:** `ApiResponse<object>`
- **Related entities:** `Appointments`, `DoctorProfiles`, `Notifications`
- **Flow:** Validate ownership + status, set cancelled, notify other party.

### `PUT /api/appointments/{id}/confirm`
- **Purpose:** Doctor confirms scheduled appointment.
- **Route Params:** `id`
- **Response:** `ApiResponse<object>`
- **Related entities:** `Appointments`, `DoctorProfiles`, `Notifications`
- **Flow:** Validate doctor ownership and status transition to confirmed, notify patient.

### `PUT /api/appointments/{id}/complete`
- **Purpose:** Doctor completes confirmed appointment.
- **Route Params:** `id`
- **Response:** `ApiResponse<object>`
- **Related entities:** `Appointments`, `DoctorProfiles`, `Notifications`
- **Flow:** Validate ownership and status transition to completed, notify patient.

---

## ReviewsController (`/api/doctors/{doctorId}/reviews`)

### `GET /api/doctors/{doctorId}/reviews`
- **Purpose:** Get doctor reviews and average rating.
- **Route Params:** `doctorId`
- **Response:** `ApiResponse<ReviewListResponse>`
- **Related entities:** `DoctorProfiles`, `DoctorReviews`, `ApplicationUser`
- **Flow:** Resolve doctor profile, fetch reviews with patient names, compute average and total.

### `POST /api/doctors/{doctorId}/reviews` [Authorize]
- **Purpose:** Add/update patient review for doctor.
- **Route Params:** `doctorId`
- **Request Body:** `AddReviewRequest` (`rating`, `comment?`)
- **Response:** `ApiResponse<object>`
- **Related entities:** `DoctorProfiles`, `DoctorReviews`, `Appointments`
- **Flow:** Validate patient role and rating range, require completed appointment, then upsert review.

---

## SpecialtiesController (`/api/specialties`)

### `GET /api/specialties`
- **Purpose:** List active specialties.
- **Response:** `ApiResponse<List<SpecialtyDto>>`
- **Related entities:** `Specialties`
- **Flow:** Query active specialties ordered by name.

### `POST /api/specialties` [AdminOnly]
- **Purpose:** Create specialty.
- **Request Body:** `UpsertSpecialtyRequest` (`name`, `iconUrl?`, `isActive?`)
- **Response:** `ApiResponse<SpecialtyDto>`
- **Related entities:** `Specialties`
- **Flow:** Validate non-empty unique name, insert specialty.

### `PUT /api/specialties/{id}` [AdminOnly]
- **Purpose:** Update specialty.
- **Route Params:** `id`
- **Request Body:** `UpsertSpecialtyRequest`
- **Response:** `ApiResponse<object>`
- **Related entities:** `Specialties`
- **Flow:** Validate exists + duplicate name check, update fields.

### `DELETE /api/specialties/{id}` [AdminOnly]
- **Purpose:** Soft delete specialty.
- **Route Params:** `id`
- **Response:** `ApiResponse<object>`
- **Related entities:** `Specialties`
- **Flow:** Set `IsActive=false` and save.

---

## HealthRecordsController (`/api/health-records`) [Authorize]

### `GET /api/health-records`
- **Purpose:** Get current patient health records.
- **Response:** `ApiResponse<List<HealthRecordDto>>`
- **Related entities:** `HealthRecords`
- **Flow:** Ensure patient role, fetch records by patient id ordered by recorded date.

### `POST /api/health-records`
- **Purpose:** Add health record.
- **Request Body:** `CreateHealthRecordRequest` (`title`, `type`, `value?`, `recordedAt?`, `notes?`)
- **Response:** `ApiResponse<HealthRecordDto>`
- **Related entities:** `HealthRecords`
- **Flow:** Validate title, create and save new record.

### `GET /api/health-records/{id}`
- **Purpose:** Get one owned health record.
- **Route Params:** `id`
- **Response:** `ApiResponse<HealthRecordDto>`
- **Related entities:** `HealthRecords`
- **Flow:** Fetch by record id + current patient id.

### `DELETE /api/health-records/{id}`
- **Purpose:** Delete one owned record.
- **Route Params:** `id`
- **Response:** `ApiResponse<object>`
- **Related entities:** `HealthRecords`
- **Flow:** Validate ownership, remove record.

### `GET /api/health-records/summary`
- **Purpose:** Health summary for current patient.
- **Response:** `ApiResponse<HealthSummaryDto>`
- **Related entities:** `HealthRecords`
- **Flow:** Load records, compute total count + latest key measurements.

---

## MessagesController (`/api/messages`) [Authorize]

### `GET /api/messages/conversations`
- **Purpose:** Get my conversations list.
- **Response:** `ApiResponse<List<ConversationDto>>`
- **Related entities:** `Conversations`, `ChatMessages`, `ApplicationUser`
- **Flow:** Filter conversations by current role, include participants/messages, compute unread counts.

### `GET /api/messages/conversations/{id}`
- **Purpose:** Get messages for one conversation.
- **Route Params:** `id`
- **Response:** `ApiResponse<List<MessageDto>>`
- **Related entities:** `Conversations`, `ChatMessages`, `ApplicationUser`
- **Flow:** Validate participant, mark unread incoming as read, return ordered message list.

### `POST /api/messages/conversations/{doctorId}`
- **Purpose:** Patient starts or gets conversation with doctor.
- **Route Params:** `doctorId`
- **Response:** `ApiResponse<ConversationDto>`
- **Related entities:** `ApplicationUser`, `Conversations`
- **Flow:** Validate patient role and doctor existence, return existing or create new conversation.

### `POST /api/messages/conversations/{id}/send`
- **Purpose:** Send message.
- **Route Params:** `id`
- **Request Body:** `SendMessageRequest` (`content`)
- **Response:** `ApiResponse<MessageDto>`
- **Related entities:** `Conversations`, `ChatMessages`, `Notifications`
- **Flow:** Validate participant/content, insert message, update conversation, send notification and realtime events via SignalR.

### `PUT /api/messages/conversations/{id}/read`
- **Purpose:** Mark conversation messages as read.
- **Route Params:** `id`
- **Response:** `ApiResponse<object>`
- **Related entities:** `Conversations`, `ChatMessages`
- **Flow:** Validate participant, mark unread incoming messages as read, emit realtime read event.

---

## HomeController (`/api/home`) [Authorize]

### `GET /api/home/summary`
- **Purpose:** Patient dashboard summary.
- **Response:** `ApiResponse<HomeSummaryDto>`
- **Related entities:** `Appointments`, `DoctorProfiles`, `DoctorReviews`, `Specialties`, `HealthRecords`, `ApplicationUser`
- **Flow:** Ensure patient role, fetch upcoming appointment, health snapshot, top doctors, and active specialties; return combined home summary.

---

## Overall System Flow

1. **Auth + Verification**
   - User registers/logs in.
   - Doctor users may upload verification documents.
   - Admin approves or rejects doctor profiles.

2. **Doctor Discovery**
   - Patients search doctors by specialty, fee, rating, distance, and availability.
   - Top-rated and doctor details endpoints enrich browsing.

3. **Availability**
   - Doctors define weekly availability windows.
   - Slot endpoints generate real bookable times from windows minus booked appointments.

4. **Appointments**
   - Patients book slots.
   - Doctors confirm/complete; either side can cancel according to rules.
   - Notifications are sent on key status changes.

5. **Reviews**
   - Patients can review doctors after completed appointments.
   - Ratings feed back into search/top/home ranking.

6. **Health + Home**
   - Patients manage health records.
   - Home summary aggregates appointments, health stats, top doctors, and specialties.

7. **Messaging**
   - Patients and doctors chat in conversations.
   - Messaging integrates with notifications and realtime SignalR updates.

