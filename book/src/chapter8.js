const {
  chapterTitle, h2, h3, p, lead, bullet, numbered, pageBreak, note,
} = require("./helpers");

const chapter8 = () => [
  chapterTitle("Chapter 8: Conclusion and Future Work"),

  // ----------------------------------------------------------------------- //
  h2("8.1  Introduction"),
  lead("This final chapter reflects on the outcomes of the Find Your Clinic project, summarises what was achieved, identifies the limitations of the current version, and lays out a concrete future-work agenda. The conclusions presented here are informed by every previous chapter of the book, from the problem statement and the literature review to the design artefacts and the implementation details."),

  // ----------------------------------------------------------------------- //
  h2("8.2  Conclusion"),
  p("Find Your Clinic set out to solve a real and widely felt problem: the difficulty patients face in finding qualified doctors, scheduling appointments, communicating with their providers, and managing their own health information. The literature review confirmed that this problem is well documented and that existing solutions consistently fall short — they are fragmented, partially digital, slow to confirm, and rarely trustworthy. The platform we have built is a direct response to that gap."),

  p("Architecturally, the project succeeded in delivering a clean, scalable, and modern system. The .NET 10 backend follows clean architecture with strict layering between the Domain, Infrastructure, and API projects. Business logic is organised as MediatR vertical slices, which allows the codebase to grow horizontally without becoming monolithic. The Flutter mobile application uses Cubit/Bloc for state management, GetIt for dependency injection, and a strict feature-based folder structure. The Next.js admin dashboard mirrors the same design principles. Together, the three clients share a single database, a single identity system, a single chat hub, and a single source of truth for every business rule."),

  p("Functionally, the project succeeded in delivering an unusually wide product surface for a graduation-scale effort: full authentication with email and Google OAuth; verified doctor profiles with admin approval; rich doctor discovery with location-aware search; real-time appointment booking with conflict detection; integrated online payment via Paymob; secure in-app chat with text, voice notes, image attachments, and reactions; a digital health-records vault with selective sharing; an AI-powered Health Assistant with both text and voice interaction; doctor reviews with admin moderation; push notifications across every state transition; doctor wallets and admin-managed payouts; and a Next.js admin dashboard with comprehensive operational tooling."),

  p("From a user-experience perspective, the project succeeded in being both aesthetically pleasing and accessible. The Material 3 design system, with its carefully tuned colour palette and typography, was applied consistently across every screen. Both Arabic and English are supported with full right-to-left layouts. Dark mode is implemented end-to-end. Voice commands and TTS responses give a hands-free option that is particularly valuable to patients with reduced mobility. These details matter: they turn a technically correct app into an app that is comfortable to use, which is what actually drives adoption."),

  p("From an academic perspective, the project illustrates how modern software-engineering practices — clean architecture, vertical slices, layered testing, code review, atomic commits, and continuous integration — translate into a real product. It also illustrates how thoughtfully applied AI can extend the boundaries of a healthcare app without crossing into unsafe territory: the Gemini-powered assistant helps the patient without replacing the doctor, and every prompt, retry, and fallback is engineered with that boundary in mind."),

  p("Find Your Clinic is, in summary, more than an academic exercise. It is a serious attempt to build a production-grade healthcare platform that we believe can be deployed and used by real patients and real doctors. The combination of architectural rigour, comprehensive features, and human-centred design positions the project as a strong foundation for continued development beyond graduation."),

  // ----------------------------------------------------------------------- //
  h2("8.3  Limitations of the Current Version"),
  p("Honest reflection requires acknowledging what the current version does not yet do. The following limitations are documented as scope boundaries rather than failures, and most of them already appear in the future-work agenda below."),

  bullet("No live video or audio consultations. The current chat supports text, voice notes, and attachments, but not live calls."),
  bullet("No insurance integration. The platform does not yet connect to insurance providers to verify coverage or process claims."),
  bullet("No e-prescription. Doctors can send prescriptions inside the chat as text or images, but the system does not produce digitally signed prescriptions."),
  bullet("No multi-clinic hospital management. The current product is optimised for solo doctors and small clinics, not for large hospitals with many specialists and complex administrative hierarchies."),
  bullet("No in-app pharmacy. We considered building a pharmacy ordering module but deferred it because it would require partnerships and licensing that are outside the scope of an academic project."),
  bullet("No public REST API for third parties. The internal REST endpoints are well structured, but they have not been formalised into a public, versioned API with documentation."),
  bullet("Limited language coverage. Only Arabic and English are supported today; expanding to other regional languages (French, Turkish, Urdu) is straightforward but has not been done."),
  bullet("No native iOS submission. The iOS build has been verified to compile and run, but it has not been submitted to the App Store, which requires an Apple Developer Program enrolment."),
  bullet("Light analytics. Admin analytics show revenue and active users, but more advanced behavioural analytics (search-to-booking conversion, retention cohorts) are not yet implemented."),

  // ----------------------------------------------------------------------- //
  h2("8.4  Future Work"),
  p("Building on the foundation we have laid, the future work agenda is organised into seven themes. Each theme contains specific deliverables that the team or future contributors can pick up in any order."),

  h3("8.4.1  Live Tele-Consultation"),
  bullet("Integrate a WebRTC service (LiveKit or Twilio Programmable Video) to support live audio and video calls between patients and doctors."),
  bullet("Add a doctor-side dashboard for live calls with waiting room, mute controls, and screen sharing."),
  bullet("Implement a tariff model for paid video consultations, distinct from chat-only consultations."),

  h3("8.4.2  E-Prescription and Pharmacy"),
  bullet("Implement structured e-prescriptions with drug, dosage, frequency, and duration fields."),
  bullet("Add digital signing of prescriptions, anchored to the doctor's verified identity."),
  bullet("Partner with a local pharmacy chain to enable in-app ordering and home delivery."),
  bullet("Provide a patient-side medication tracker that issues reminders and tracks adherence."),

  h3("8.4.3  Insurance Integration"),
  bullet("Connect to one or more local insurance providers to verify coverage before booking."),
  bullet("Implement a claim-submission workflow that takes the appointment, the prescription, and the payment record and forwards them to the insurer."),
  bullet("Display covered vs. out-of-pocket costs to the patient at booking time."),

  h3("8.4.4  Hospital and Clinic Management"),
  bullet("Add a hospital actor with multi-doctor scheduling, shared waiting rooms, and aggregated analytics."),
  bullet("Implement clinic-level admin roles distinct from platform-level admins."),
  bullet("Add room and equipment scheduling for clinics that need it."),

  h3("8.4.5  Personalisation and Recommendations"),
  bullet("Use historical appointment data to recommend doctors based on the patient's past specialties and ratings."),
  bullet("Use the AI assistant's conversation history to predict the patient's needs and proactively surface relevant doctors."),
  bullet("Add patient cohorts (children, women's health, chronic conditions) with curated content and recommended providers."),

  h3("8.4.6  AI Beyond the Assistant"),
  bullet("Build a triage classifier that ranks symptom urgency and recommends emergency care for red-flag patterns."),
  bullet("Provide doctor-side AI tooling that summarises long chat threads and drafts follow-up messages."),
  bullet("Extend the AI to interpret lab results and explain them in plain language, with strong disclaimers."),

  h3("8.4.7  Accessibility, Inclusivity, and Quality"),
  bullet("Expand language support to French, Turkish, and additional regional languages."),
  bullet("Add high-contrast and large-text themes for visually impaired users."),
  bullet("Add screen-reader friendly semantic labels across every screen."),
  bullet("Conduct a formal accessibility audit against WCAG 2.2 AA."),
  bullet("Add an in-app feedback channel that routes user reports directly into the GitHub issue queue."),

  // ----------------------------------------------------------------------- //
  h2("8.5  Closing Remarks"),
  p("Building Find Your Clinic has been a uniquely formative experience. Over the course of an academic year, six students moved a healthcare platform from a blank page to a feature-rich, production-grade product. The journey involved more than code: we interviewed users, sketched designs, debated architectures, wrote tests, fought regressions, and iterated until the experience felt right. We learned what it means to deliver software that real people might one day rely on for their health."),

  p("We are proud of the result, and we are equally proud of the process. The clean-architecture discipline, the vertical-slice approach, the feature-based mobile structure, the layered test strategy, and the commitment to atomic commits and code review are habits that will outlive this project. The future-work agenda makes it clear that there is a great deal more to build. With the foundation we have laid, that work can proceed quickly."),

  p("We close this book with deep gratitude to our supervisors, our families, and the patients and doctors who shared their time and stories with us during the research phase. They are the reason we built this — and the reason we will keep building."),

  ...require("./helpers").blank(2),

  pageBreak(),
];

module.exports = { chapter8 };
