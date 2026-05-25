# Figure 7 — Booking and Payment Sequence Diagram

Sequence diagram of the most security-critical flow in Find Your Clinic: an end-to-end
appointment booking, payment, server-side verification, and chat unlock. The diagram
emphasises the **two-phase commit**: the appointment is created in `Pending` state,
payment is processed by Paymob, and the appointment is promoted to `Confirmed` only
after the backend independently verifies the payment through the webhook.

```mermaid
sequenceDiagram
    autonumber
    actor P as 👤 Patient (Flutter app)
    participant API as .NET 10 API<br/>(MediatR + EF Core)
    participant DB as 🗄️ SQL Server
    participant PM as 💳 Paymob
    participant HUB as 🔌 SignalR ChatHub
    participant FCM as 🔔 Firebase Cloud Messaging
    actor D as 🩺 Doctor (Flutter app)

    P->>API: POST /api/appointments {doctorId, slot, notes}
    API->>DB: Lock slot row · validate availability
    DB-->>API: OK (no conflict)
    API->>DB: Insert Appointment (status = Pending)<br/>Insert PendingBookingIntent
    API-->>P: 201 Created · appointmentId · paymentSessionId

    P->>API: POST /api/payments/intent {appointmentId}
    API->>PM: Create hosted-checkout session
    PM-->>API: paymentUrl · referenceId
    API-->>P: paymentUrl

    P->>PM: Open WebView · enter card details
    PM-->>P: Success page (informational)

    Note over PM,API: Paymob calls our webhook<br/>asynchronously — this is the<br/>source of truth, not the WebView.
    PM-->>API: POST /api/payments/webhook (signed)
    API->>API: Verify HMAC signature
    API->>DB: Find PendingBookingIntent by referenceId
    alt Idempotent — already processed
        DB-->>API: Already confirmed
        API-->>PM: 200 OK (no-op)
    else New webhook
        API->>DB: Update Appointment.Status = Confirmed
        API->>DB: Insert Transaction (status = Succeeded)
        API->>DB: Credit DoctorWallet.PendingBalance
        API->>DB: Open Conversation (patient ↔ doctor)
        API-->>PM: 200 OK
    end

    par Push to patient
        API->>FCM: Send "Appointment confirmed" to patient device
        FCM-->>P: Push notification
    and Push to doctor
        API->>FCM: Send "New appointment" to doctor device
        FCM-->>D: Push notification
    end

    Note over P,D: Both devices reconnect to the<br/>ChatHub and join the new conversation.

    P->>HUB: JoinConversation(conversationId)
    D->>HUB: JoinConversation(conversationId)

    P->>HUB: SendMessage("Hi doctor, see you tomorrow")
    HUB->>DB: Persist ChatMessage
    HUB-->>D: Broadcast new message
    D-->>HUB: Ack delivered
    HUB-->>P: Status = Delivered

    Note over D,P: Day of consultation — doctor marks completed.

    D->>API: PATCH /api/appointments/{id}/complete
    API->>DB: Update Appointment.Status = Completed
    API->>DB: Move wallet amount<br/>PendingBalance → AvailableBalance
    API->>FCM: Push "Please leave a review" to patient
    FCM-->>P: Push notification
```
