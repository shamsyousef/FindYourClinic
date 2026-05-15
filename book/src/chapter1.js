const {
  chapterTitle, h2, h3, p, lead, bullet, numbered, pageBreak, note,
} = require("./helpers");

const chapter1 = () => [
  chapterTitle("Chapter 1: Introduction"),

  // ----------------------------------------------------------------------- //
  h2("1.1  Overview and Background"),
  lead("Access to reliable, timely healthcare is one of the most fundamental needs in any society. Yet for millions of patients — particularly in regions with dense urban centres surrounded by underserved rural areas, such as Egypt — the everyday experience of finding the right doctor, understanding their availability, and securing an appointment remains far more difficult than it should be in 2026."),

  p("In a typical scenario, a patient who needs medical attention has to call several clinics one after the other, ask friends and relatives for personal recommendations, search through inconsistent online listings, or physically visit a clinic just to discover its working hours. The doctor’s actual schedule is usually only visible to the receptionist, payment options are limited to cash on-site, and any follow-up question after the visit either requires another full visit or a delicate phone call to the clinic. Patients regularly report missed appointments, long waiting times, and difficulty obtaining basic guidance about which specialty to consult."),

  p("These pain points are not new, and they are not unique to one country. Numerous studies and digital-health reports have shown that patients consistently demand three things from a modern healthcare experience: clarity (who is the doctor, where are they, when can I see them?), speed (book and pay without phone tag), and continuity (be able to talk to my doctor and keep my history in one place). The traditional, fragmented model of healthcare access struggles to deliver any of these three reliably."),

  p("The Find Your Clinic platform was conceived in direct response to these challenges. It is a cross-platform digital healthcare directory and consultation system that consolidates everything a patient needs into a single mobile experience, while giving doctors and administrators powerful tools to manage their side of the workflow. The platform combines a Flutter mobile application (Android and iOS), a .NET 10 backend API powered by Entity Framework Core on SQL Server, real-time chat over SignalR, a Next.js administrative dashboard, and a Google Gemini-based AI health assistant — all integrated into one cohesive product."),

  p("Find Your Clinic empowers a patient to discover nearby doctors by specialty, view verified profiles with photos, biographies, fees, and patient ratings, book an open time slot in seconds, pay for the consultation online through a secure gateway, and continue the conversation with their doctor through a secure in-app chat that supports text, voice notes, and shared medical attachments. Patients also benefit from a digital health-records vault, push notifications, and an AI assistant that can analyse symptoms in natural language and guide them toward the right specialty."),

  p("For doctors, the platform delivers an equally complete experience. After registering, uploading their license and identity documents for admin verification, doctors gain access to a personalised dashboard where they can manage availability, accept or reject incoming appointments, chat with patients, write health record updates, and track their earnings through a built-in wallet. The administrative dashboard, in turn, gives platform operators the tools to verify doctors, moderate reviews, manage specialties, monitor financial transactions, and inspect platform-wide analytics."),

  p("This combination of patient-centred mobile design, doctor empowerment, and administrative oversight is what makes Find Your Clinic more than a simple directory. It is a complete, secure, and intelligent healthcare ecosystem designed to make professional medical care just a few taps away."),

  // ----------------------------------------------------------------------- //
  h2("1.2  Motivation"),
  p("The motivation for building Find Your Clinic comes from a combination of personal observation, structured user research, and a clear technological opportunity. As students living in Egypt — a country of more than one hundred million people with thousands of clinics, hospitals, and specialists distributed unevenly across the country — we have all experienced the daily friction of accessing healthcare. Booking a visit to a specialist often involves calling several numbers, asking the family group chat for recommendations, and ending the day uncertain about whether the chosen doctor is truly the right one."),

  p("During the early discovery phase of this project, we interviewed and surveyed patients of different ages and educational backgrounds, as well as doctors and clinic administrators. A few themes emerged consistently:"),

  bullet("Patients want a single, trustworthy place to discover doctors. They are tired of jumping between social media groups, third-party listing sites, and word-of-mouth referrals that often turn out to be outdated."),
  bullet("Patients want to see real availability before they decide. The most frequent complaint we heard was \"I called three clinics and none of them picked up\" — appointment booking should be self-service and immediate."),
  bullet("Patients want a quick way to talk to the doctor after the visit. Many described going back to the clinic just to ask a single question, or hesitating to do so because of the time and travel involved."),
  bullet("Doctors want a centralised, low-friction way to manage their schedule, patient list, and financials. Many doctors run more than one clinic and struggle to maintain a unified calendar."),
  bullet("Clinic administrators want to reduce no-shows, smooth out reception load, and offer modern conveniences (online payment, digital reminders) to keep up with patient expectations."),

  p("Beyond user research, the timing for a project like Find Your Clinic is technologically ideal. Cross-platform frameworks like Flutter have matured to the point where a single codebase can deliver a near-native experience on both Android and iOS, dramatically reducing development cost. The .NET ecosystem has evolved into one of the most productive and reliable backends available, with native support for real-time communication, dependency injection, and identity management. Large language models such as Google Gemini make it possible to embed a credible, conversational health assistant directly inside a consumer app. Modern payment gateways such as Paymob have made online payment in Egypt a realistic option for small clinics. All these pieces, individually mature, can now be assembled into something genuinely useful."),

  p("Our motivation, therefore, is twofold. First, to solve a real, daily, painful problem that we and our communities have lived through. Second, to do so using a modern, scalable, and secure architecture that can outlive the academic project and grow into a real product capable of serving patients and doctors at scale."),

  // ----------------------------------------------------------------------- //
  h2("1.3  Problem Statement"),
  p("Despite the steady digitisation of many service industries in Egypt and the wider region, healthcare access for everyday patients remains largely analogue and fragmented. The current state of the practice presents at least five concrete problems:"),

  numbered("Fragmented discovery. Information about doctors and clinics is scattered across personal recommendations, generic listing websites, social-media pages, and printed signs. There is no single trusted source where a patient can compare doctors by specialty, location, fee, and patient ratings."),
  numbered("Opaque availability. The actual schedule of a doctor is hidden inside the clinic and only accessible through phone calls. Patients waste significant time hunting for a slot, and clinics waste reception capacity answering repetitive availability questions."),
  numbered("Broken communication. Once a patient has visited a doctor, there is rarely a structured, secure channel to ask a follow-up question, share a lab result, or request a prescription clarification. Patients often resort to personal WhatsApp numbers, which is inconvenient for doctors and unsafe from a privacy standpoint."),
  numbered("Manual, cash-only payments. Many clinics still operate on cash, which limits flexibility, complicates record-keeping, and forces patients to handle physical money even when they prefer digital options."),
  numbered("No personal health-record continuity. Each clinic keeps its own paper or local digital records. Patients rarely have a unified view of their medications, allergies, lab results, and prior diagnoses. When they switch doctors or visit an emergency room, the history starts from scratch."),

  p("Compounding these issues, patients also struggle with information asymmetry: without medical training, it is genuinely difficult to decide whether a particular set of symptoms requires a cardiologist, a gastroenterologist, or a general practitioner. This uncertainty often leads to either over-consultation (visiting the wrong specialty and being redirected) or under-consultation (postponing a visit because the patient is unsure where to go)."),

  p("Find Your Clinic addresses all of these problems with a single, integrated platform. It provides a comprehensive doctor directory with rich profiles and ratings, real-time appointment booking with explicit availability slots, secure in-app chat for follow-up questions and document sharing, an integrated online payment flow with patient-side and doctor-side wallets, a personal health records module, and an AI health assistant that helps patients understand symptoms and choose the right specialty before they even start their search."),

  // ----------------------------------------------------------------------- //
  h2("1.4  Objectives"),
  p("The objectives of Find Your Clinic are organised around the five problem areas identified in the previous section, and translated into concrete, measurable product goals."),

  h3("1.4.1  Improve Access to Healthcare Providers"),
  bullet("Provide a powerful, location-aware search experience that lets patients filter doctors by specialty, distance, fee range, language, and patient rating."),
  bullet("Maintain verified, photo-rich doctor profiles that present biography, qualifications, clinic address, working hours, and consultation fee in a clear, consistent format."),

  h3("1.4.2  Enable Real-Time Appointment Booking"),
  bullet("Allow doctors to publish weekly availability slots through an in-app planner; allow patients to see and book those slots in real time without phone calls."),
  bullet("Prevent double-booking and overbooking through server-side validation, and notify both sides whenever an appointment is created, rescheduled, or cancelled."),

  h3("1.4.3  Provide Secure Patient–Doctor Communication"),
  bullet("Deliver an in-app, real-time chat experience built on SignalR that supports text, voice notes, image attachments, and reaction messages."),
  bullet("Restrict chat access to confirmed patient–doctor relationships, and protect all messages with role-based authorisation and encrypted transport."),

  h3("1.4.4  Support Online Payments and Doctor Earnings"),
  bullet("Integrate with the Paymob payment gateway to enable patients to pay for consultations directly through the mobile app."),
  bullet("Maintain a transparent transaction ledger and a doctor wallet that tracks confirmed earnings, refunds, and platform fees, with admin-managed payouts."),

  h3("1.4.5  Centralise Personal Health Records"),
  bullet("Offer patients a secure digital vault for their medications, lab results, allergies, chronic conditions, and family medical history."),
  bullet("Allow patients to selectively share records with treating doctors and to update them over time as their health evolves."),

  h3("1.4.6  Provide AI-Powered Guidance"),
  bullet("Embed a Gemini-based AI Health Assistant that supports both text and voice interaction, helping patients describe symptoms in natural language."),
  bullet("Use the assistant to recommend an appropriate specialty, prepare the patient for the consultation, and answer general health questions — always with a clear disclaimer that it does not replace a real doctor."),

  h3("1.4.7  Empower Doctors and Administrators"),
  bullet("Give doctors a dedicated dashboard with appointment management, availability planning, patient chat, health record updates, and earnings tracking."),
  bullet("Give administrators a comprehensive web dashboard for doctor verification, review moderation, specialty management, and financial oversight."),

  h3("1.4.8  Ensure Inclusivity and Accessibility"),
  bullet("Support both Arabic and English with full right-to-left layout."),
  bullet("Provide a voice-driven assistant for users who prefer or require hands-free interaction, and apply Material 3 colour contrast for visually impaired users."),

  // ----------------------------------------------------------------------- //
  h2("1.5  Significance and Impact of the Research"),
  p("The significance of Find Your Clinic lies not only in solving a concrete consumer problem, but also in demonstrating how a small student team can apply modern software engineering principles to deliver a production-grade healthcare platform. The project blends several disciplines — mobile development, distributed systems, real-time communication, applied machine learning, security engineering, and human-computer interaction — into a single coherent product."),

  p("From a societal perspective, the platform has the potential to meaningfully improve the everyday experience of healthcare for patients across Egypt and similar markets. By collapsing search, scheduling, communication, payment, and AI guidance into a single trusted experience, Find Your Clinic reduces the cognitive load on patients, encourages earlier consultations, and lowers the threshold for asking a doctor a question. For doctors, the platform unlocks a wider audience, simplifies administrative work, and creates new digital earning channels. For administrators and clinic operators, it provides actionable analytics and a centralised verification process that improves trust in the broader system."),

  p("From an academic perspective, the project illustrates several modern engineering practices that we believe deserve to be highlighted in a graduation work:"),

  bullet("Clean architecture with strict layering between the Domain, Infrastructure, and API layers in the .NET backend, ensuring that business rules remain independent of frameworks and data stores."),
  bullet("Vertical slices using the MediatR library, where each feature has its own command, query, handler, and validator — making the codebase scalable to many features without growing monolithic controllers."),
  bullet("Feature-based folder structure in the Flutter mobile application, where every feature contains its own data, domain, and presentation layers — encouraging local reasoning and easy refactoring."),
  bullet("Cubit/Bloc state management without code generation, leveraging Dart 3 sealed classes for exhaustive state handling and avoiding the build-time complexity of Freezed."),
  bullet("Real-time communication using SignalR, demonstrating how WebSocket-based messaging integrates cleanly with role-based authorisation and JWT identity."),
  bullet("Responsible AI integration, where a large language model is used to assist patients but is clearly bounded by a medical-aware system prompt, retry logic, and a disclaimer."),

  p("Taken together, these design choices show how a thoughtfully architected codebase can support a wide product surface — patient app, doctor app, admin dashboard, real-time chat, payments, AI, push notifications — while remaining maintainable, testable, and ready for production deployment."),

  // ----------------------------------------------------------------------- //
  h2("1.6  Scope and Functionality"),
  p("Find Your Clinic is intended to be a complete patient-doctor connection platform. Its scope, summarised at a high level, includes the following capabilities:"),

  h3("1.6.1  Patient Capabilities"),
  bullet("Sign up and sign in using email and password or Google OAuth, with full email verification and password recovery."),
  bullet("Browse and search doctors by specialty, location, rating, fee range, and availability."),
  bullet("View detailed doctor profiles with photo, biography, working hours, fees, and verified reviews."),
  bullet("Book, reschedule, or cancel appointments and receive instant push notifications about status changes."),
  bullet("Pay for consultations through the integrated Paymob gateway."),
  bullet("Engage in real-time chat with the doctor after a confirmed appointment, including voice notes, image attachments, and message reactions."),
  bullet("Store and manage personal health records (medications, allergies, lab results, chronic conditions, vaccinations)."),
  bullet("Use the AI Health Assistant for symptom guidance, specialty recommendations, and general health questions, with both text and voice interaction."),
  bullet("Receive push notifications for appointments, messages, payment confirmations, and review requests."),
  bullet("Switch between Arabic and English, light and dark mode, and configure accessibility preferences."),

  h3("1.6.2  Doctor Capabilities"),
  bullet("Apply for verification by uploading identity documents, medical license, and proof of practice."),
  bullet("Build a verified public profile with photo, biography, specialty, clinic address, fee, and supported languages."),
  bullet("Define and update weekly availability through a structured slot planner."),
  bullet("Manage incoming appointment requests (confirm, complete, cancel) and view a unified appointment calendar."),
  bullet("Chat with patients in real time, send voice notes, and share documents."),
  bullet("Create and update patient health record entries (with the patient's permission)."),
  bullet("Track earnings through a personal wallet, view transaction history, and request payouts."),
  bullet("Receive push notifications for new bookings, messages, payments, and reviews."),

  h3("1.6.3  Administrator Capabilities"),
  bullet("Authenticate as Admin with role-restricted access."),
  bullet("Review pending doctor applications, inspect uploaded documents, and approve or reject with reason."),
  bullet("Activate or deactivate patient and doctor accounts as needed."),
  bullet("Manage the master list of medical specialties used during doctor registration."),
  bullet("Moderate doctor reviews to remove inappropriate content."),
  bullet("Monitor financial flows: consultation payments, doctor wallets, payouts, refunds, and platform revenue."),
  bullet("Search and inspect health records for support and compliance purposes."),

  h3("1.6.4  Scope Boundaries"),
  p("To keep the academic project focused, the current version of Find Your Clinic intentionally excludes the following items, which are documented as future work in Chapter 8:"),

  bullet("Tele-consultation via video or audio calls (the platform currently supports asynchronous chat and voice notes, but not live video calls)."),
  bullet("Integration with national e-health systems or insurance providers."),
  bullet("E-prescription with regulated digital signatures."),
  bullet("In-app pharmacy ordering and delivery."),
  bullet("Multi-clinic management features for hospital administrators."),

  // ----------------------------------------------------------------------- //
  h2("1.7  Platform Overview"),
  p("Find Your Clinic is delivered as three coordinated clients that share a single backend API and database:"),

  h3("1.7.1  Mobile Application (Flutter)"),
  p("The mobile app is the primary surface for patients and doctors. It is built with Flutter and a single Dart codebase that compiles to native Android and iOS binaries. The app uses the Cubit/Bloc pattern for state management, GoRouter for navigation, GetIt for dependency injection, and Dio for HTTP communication. Major modules include authentication, doctor search, appointment booking, real-time chat, health records, the AI Health Assistant, notifications, payments, and settings."),

  h3("1.7.2  Administrative Dashboard (Next.js)"),
  p("The admin dashboard is a Next.js 14 web application using the App Router, TypeScript, Tailwind CSS for styling, Lucide React for icons, and Axios for API communication. It is intentionally web-only because it targets office workflows rather than on-the-go usage. Major pages include doctor approval, user management, specialty management, review moderation, financial oversight, and health record lookup."),

  h3("1.7.3  Backend API (.NET 10)"),
  p("The backend is a .NET 10 Web API built around clean architecture. The Domain project contains pure C# entities, enums, and interfaces, with no external dependencies. The Infrastructure project contains Entity Framework Core 10 on SQL Server, ASP.NET Identity for user management, JWT token issuance, and integrations with Cloudinary, Firebase Cloud Messaging, Google OAuth, and the Paymob gateway. The API project organises business logic as MediatR vertical slices (commands, queries, handlers, validators) and exposes REST endpoints through thin controllers. Real-time chat is delivered via a dedicated SignalR hub."),

  h3("1.7.4  Cross-Cutting Services"),
  bullet("SQL Server is used as the primary relational store, with Entity Framework Core migrations under source control."),
  bullet("Cloudinary handles all image storage (doctor profile pictures, document scans, health record attachments) with secure delivery URLs."),
  bullet("Firebase Cloud Messaging delivers push notifications to both iOS and Android."),
  bullet("Paymob handles online payment for consultations, with a webhook-driven verification flow on the backend."),
  bullet("Google Gemini powers the AI Health Assistant, with a custom system prompt and retry-and-fallback logic."),
  bullet("Google OAuth allows users to sign in with their Google account."),

  // ----------------------------------------------------------------------- //
  h2("1.8  Methodology"),
  p("The development of Find Your Clinic followed an iterative, user-centred methodology inspired by Agile and Lean UX principles, but adapted to the constraints of a one-academic-year graduation project."),

  h3("1.8.1  Discovery and Research"),
  p("The first phase focused on understanding the problem space. We conducted unstructured interviews with patients of different ages and educational levels, and follow-up sessions with several doctors and clinic administrators. We complemented these interviews with desk research on existing healthcare platforms in Egypt and abroad, identifying both their strengths (rich profiles, online booking) and their gaps (poor real-time communication, missing AI assistance, weak verification). The output of this phase was a written set of personas, user journeys, and pain points that guided every subsequent design decision."),

  h3("1.8.2  System and Database Design"),
  p("In the second phase, we translated the research output into a concrete system design. We produced an Entity Relationship Diagram for the relational store, a UML class diagram for the domain model, a Use Case diagram covering the three actors (Patient, Doctor, Admin), and workflow diagrams for the most important journeys (booking, chatting, paying). We selected the technology stack — Flutter, .NET 10, SQL Server, SignalR, Next.js — based on a deliberate evaluation of maturity, scalability, team expertise, and licensing."),

  h3("1.8.3  UI/UX Design"),
  p("Concurrently with system design, we built high-fidelity mockups for all major screens of the mobile app and the admin dashboard. The mobile mockups emphasise Material 3 styling, clear typography, dark-mode parity, and an Arabic right-to-left layout. We iterated several rounds of feedback with peers and supervisors before locking in the visual language."),

  h3("1.8.4  Iterative Development"),
  p("Development was organised into two-week sprints. Each sprint targeted a small set of vertical slices — for example, \"appointment booking end-to-end\" — that touched the backend, the mobile app, and (where relevant) the admin dashboard. We used Git with feature branches and pull requests, code review between team members, and continuous local testing on physical Android devices. Every sprint produced a runnable build of the platform, which we tested ourselves and occasionally with friends and family acting as informal beta users."),

  h3("1.8.5  Testing and Verification"),
  p("Testing was layered. The backend has unit tests for command and query handlers and integration tests against an in-memory database. The mobile app has widget tests for critical UI flows and use-case tests for repository logic. We complemented automated tests with extensive manual exploratory testing on real devices, simulating realistic scenarios such as bad network conditions, simultaneous appointments, and edge cases in payment confirmation."),

  h3("1.8.6  Deployment Readiness"),
  p("The final phase focused on getting the platform to a state that could realistically be deployed. This involved consolidating environment variables, hardening security (RLS-like policies expressed in handlers, JWT lifetime configuration, secure cookie flags on the admin), running Android release builds with R8 obfuscation, signing the iOS build, and verifying that Firebase, Cloudinary, Paymob, and Gemini all responded correctly under the production configuration."),

  note("The detailed timeline, including week-by-week milestones, is presented in Chapter 4 (Methodology)."),

  pageBreak(),
];

module.exports = { chapter1 };
