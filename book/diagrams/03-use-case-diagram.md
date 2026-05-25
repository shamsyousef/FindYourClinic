# Figure 3 — Use Case Diagram

Use-case diagram showing what each of the three actors (Patient, Doctor, Admin) can do
in Find Your Clinic. Mermaid does not have a dedicated UML use-case syntax, so this is
modelled as a labelled flowchart with rounded "use case" nodes grouped per actor.

```mermaid
flowchart LR
    %% ---------------- Actors ----------------
    Patient(("👤 Patient"))
    Doctor(("🩺 Doctor"))
    Admin(("🛡️ Admin"))

    %% ---------------- Shared use cases ----------------
    subgraph Shared["Shared Use Cases"]
        UC_SignIn(["Sign In / Sign Out"])
        UC_EditProfile(["Edit Profile"])
        UC_Notifications(["Receive Notifications"])
        UC_Chat(["Real-Time Chat (post-confirmation)"])
    end

    %% ---------------- Patient use cases ----------------
    subgraph PatientUseCases["Patient Use Cases"]
        UC_Register(["Register Account"])
        UC_Search(["Search Doctors"])
        UC_ViewProfile(["View Doctor Profile"])
        UC_Book(["Book Appointment"])
        UC_Pay(["Pay Consultation Fee"])
        UC_Reschedule(["Reschedule / Cancel"])
        UC_HealthRecords(["Manage Health Records"])
        UC_AI(["Use AI Health Assistant"])
        UC_Review(["Leave Review After Completion"])
        UC_Nearby(["Discover Nearby Clinics"])
    end

    %% ---------------- Doctor use cases ----------------
    subgraph DoctorUseCases["Doctor Use Cases"]
        UC_Apply(["Apply as Doctor & Upload Documents"])
        UC_BuildProfile(["Build / Update Public Profile"])
        UC_Availability(["Manage Weekly Availability"])
        UC_ManageAppts(["Manage Appointments"])
        UC_UpdateRecord(["Write Patient Health Record"])
        UC_Earnings(["View Earnings"])
        UC_RequestPayout(["Request Payout"])
    end

    %% ---------------- Admin use cases ----------------
    subgraph AdminUseCases["Admin Use Cases"]
        UC_Approve(["Approve / Reject Doctor Applications"])
        UC_Users(["Activate / Deactivate Users"])
        UC_Specialties(["Manage Specialties"])
        UC_Moderate(["Moderate Reviews"])
        UC_Financial(["Monitor Financial Dashboard"])
        UC_Payouts(["Process Payouts"])
        UC_RecordLookup(["Lookup Records (Compliance)"])
    end

    %% ---------------- Patient links ----------------
    Patient --- UC_Register
    Patient --- UC_SignIn
    Patient --- UC_EditProfile
    Patient --- UC_Search
    Patient --- UC_ViewProfile
    Patient --- UC_Nearby
    Patient --- UC_Book
    Patient --- UC_Pay
    Patient --- UC_Reschedule
    Patient --- UC_Chat
    Patient --- UC_AI
    Patient --- UC_HealthRecords
    Patient --- UC_Review
    Patient --- UC_Notifications

    %% ---------------- Doctor links ----------------
    Doctor --- UC_Apply
    Doctor --- UC_SignIn
    Doctor --- UC_EditProfile
    Doctor --- UC_BuildProfile
    Doctor --- UC_Availability
    Doctor --- UC_ManageAppts
    Doctor --- UC_Chat
    Doctor --- UC_UpdateRecord
    Doctor --- UC_Earnings
    Doctor --- UC_RequestPayout
    Doctor --- UC_Notifications

    %% ---------------- Admin links ----------------
    Admin --- UC_SignIn
    Admin --- UC_Approve
    Admin --- UC_Users
    Admin --- UC_Specialties
    Admin --- UC_Moderate
    Admin --- UC_Financial
    Admin --- UC_Payouts
    Admin --- UC_RecordLookup

    %% ---------------- Include / Extend relations ----------------
    UC_Book -.->|"«include»"| UC_Pay
    UC_Pay  -.->|"«include»"| UC_Chat
    UC_Review -.->|"«extends»"| UC_Book

    %% ---------------- Styling ----------------
    classDef actor fill:#1F4E79,stroke:#0B2F4F,stroke-width:2px,color:#fff;
    class Patient,Doctor,Admin actor;

    classDef uc fill:#EAF1FA,stroke:#2E75B6,color:#0B2F4F,rx:12,ry:12;
    class UC_SignIn,UC_EditProfile,UC_Notifications,UC_Chat,UC_Register,UC_Search,UC_ViewProfile,UC_Book,UC_Pay,UC_Reschedule,UC_HealthRecords,UC_AI,UC_Review,UC_Nearby,UC_Apply,UC_BuildProfile,UC_Availability,UC_ManageAppts,UC_UpdateRecord,UC_Earnings,UC_RequestPayout,UC_Approve,UC_Users,UC_Specialties,UC_Moderate,UC_Financial,UC_Payouts,UC_RecordLookup uc;
```
