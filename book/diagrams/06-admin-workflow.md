# Figure 6 — Admin Workflow Diagram

Workflow followed by a Find Your Clinic administrator inside the Next.js dashboard. The
administrator works through a set of queues (doctor approvals, flagged reviews, payout
requests, support tickets) and the diagram makes those queues explicit.

```mermaid
flowchart TD
    Start([🛡️ Admin opens dashboard]) --> Login["Sign in (role = Admin)"]
    Login --> Guard{Role check}
    Guard -- "Not Admin" --> Reject([403 → redirect to /login])
    Guard -- "Admin"     --> Overview["📊 Dashboard Overview<br/>active users · active doctors · today's revenue"]

    Overview --> Queue{Pick a queue}

    %% Approvals
    Queue -- "Pending Doctors" --> Approvals["📝 Approvals Queue"]
    Approvals --> InspectDoc["Open profile<br/>view ID · License · Practice docs"]
    InspectDoc --> Decision{Decision?}
    Decision -- "Approve" --> ApproveDoctor["Approve doctor<br/>email + push to doctor"] --> Approvals
    Decision -- "Reject"  --> RejectDoctor["Reject with reason<br/>email + push to doctor"] --> Approvals

    %% Users
    Queue -- "Users" --> Users["👥 User Management"]
    Users --> ToggleUser["Activate / Deactivate user account"] --> Users

    %% Specialties
    Queue -- "Specialties" --> SpecRoot["🏷️ Specialties CRUD"]
    SpecRoot --> SpecAction{Action?}
    SpecAction -- "Add"    --> SpecAdd["Create specialty"] --> SpecRoot
    SpecAction -- "Edit"   --> SpecEdit["Rename / re-icon"] --> SpecRoot
    SpecAction -- "Delete" --> SpecDel["Delete (only if no doctor uses it)"] --> SpecRoot

    %% Reviews
    Queue -- "Reviews" --> Reviews["⭐ Review Moderation"]
    Reviews --> ReviewDecision{Verdict?}
    ReviewDecision -- "Approve" --> RvApprove["Approve review"] --> Reviews
    ReviewDecision -- "Flag"    --> RvFlag["Flag for follow-up"] --> Reviews
    ReviewDecision -- "Remove"  --> RvRemove["Remove + log"] --> Reviews

    %% Finance
    Queue -- "Finance" --> Finance["💰 Financial Dashboard<br/>revenue · transactions · payouts"]
    Finance --> Payouts["💳 Payout Queue"]
    Payouts --> ProcessPayout["Process payout to doctor"]
    ProcessPayout --> MarkPaid["Mark transaction = Paid<br/>notify doctor"] --> Finance

    %% Health record support
    Queue -- "Support" --> Support["📋 Health Record Lookup"]
    Support --> SearchPatient["Search patient by email / id"]
    SearchPatient --> AuditLog["Read + audit log entry"] --> Support

    %% End loop
    Overview --> End([Logout])

    %% Styling
    classDef start fill:#0B2F4F,stroke:#0B2F4F,color:#fff;
    classDef bad   fill:#FBE4E4,stroke:#C44A4A,color:#5A1A1A;
    classDef ok    fill:#DCEAF7,stroke:#2E75B6,color:#0B2F4F;
    class Start,End,Reject start;
    class RejectDoctor,RvRemove,RvFlag bad;
```
