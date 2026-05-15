const {
  chapterTitle, h2, h3, p, lead, bullet, numbered, pageBreak, note, kvTable,
} = require("./helpers");

const chapter2 = () => [
  chapterTitle("Chapter 2: Literature Review"),

  // ----------------------------------------------------------------------- //
  h2("2.1  Introduction"),
  lead("This chapter situates Find Your Clinic in the broader landscape of digital healthcare platforms and the research that has shaped them. The goal is to understand what has been tried before, what works, what fails, and where the persistent gaps lie — so that the design and implementation choices made in later chapters are well-grounded rather than improvised."),

  p("Digital health is one of the most rapidly evolving areas of consumer software. In the last decade, dozens of mobile applications, web portals, and integrated platforms have launched globally with the goal of improving access to healthcare. Some have focused on appointment booking (Vezeeta, Doctolib, ZocDoc, Practo), others on tele-consultation (Babylon Health, Teladoc, MDLive), others on personal health records (Apple Health, Google Fit, MyChart), and still others on AI-powered symptom checkers (Ada, K Health, Buoy Health). Each of these projects has revealed something useful about what patients want — and what they consistently fail to receive."),

  p("Our literature review combined a mixed-methods approach. We surveyed existing healthcare applications available in Egypt and abroad, examined academic papers on telemedicine adoption and human-centred design for healthcare, and conducted informal interviews with patients, doctors, and clinic administrators. The chapter is structured as follows: Section 2.2 describes our data-collection strategy, Section 2.3 reviews the challenges in existing solutions, Section 2.4 summarises the key gaps identified in the literature, Section 2.5 explains how those gaps directly shaped Find Your Clinic, and Section 2.6 concludes the chapter."),

  // ----------------------------------------------------------------------- //
  h2("2.2  Data Collection"),
  p("Effective product research in healthcare requires more than reading reviews of competing apps. Healthcare is high-stakes, deeply personal, and culturally sensitive, which means user expectations are nuanced and difficult to surface through quantitative methods alone. We therefore adopted a mixed-methods strategy that combined three sources of input: stakeholder interviews and surveys, a structured competitive analysis, and an academic literature review."),

  h3("2.2.1  Stakeholder Interviews and Surveys"),
  p("At the heart of our research was a structured stakeholder survey targeting three primary groups within the healthcare ecosystem in Egypt. Each group surfaced a different perspective on the same underlying problem space."),

  h3("Patients"),
  p("A diverse group of participants representing different age groups, educational levels, and healthcare needs took part in the survey. The data collection focused on understanding how patients currently search for doctors, the importance of location-based services in their decision, their preferences for booking appointments online versus by phone, their attitudes toward digital payment, and their expectations regarding follow-up communication and AI guidance. Insights from patients shaped almost every user-facing decision in the product, from the prominence of the search bar to the structure of the doctor profile to the design of the chat interface."),

  h3("Healthcare Providers"),
  p("Physicians from several specialties (general practice, cardiology, dermatology, paediatrics, gynaecology), clinic administrators, and reception staff participated in our doctor-side research. The interviews explored how doctors currently advertise their availability, how appointments are managed today, how no-shows and cancellations affect clinic operations, and what concerns doctors have about online communication with patients. Feedback from this group defined the structure of doctor profiles, the design of the availability planner, the workflow of appointment confirmation, and the constraints on in-app chat (such as the rule that chat is only enabled after a confirmed appointment)."),

  h3("Healthcare Facilities and Medical Organisations"),
  p("This segment included private clinics, polyclinics, and small medical centres. The interviews examined how these facilities manage scheduling at scale, how they handle patient flow at peak hours, and how they envision the role of a centralised digital platform. Participants shared their perspectives on integrating with a third-party booking tool, accepting online payment, and managing reception workload. Their feedback influenced our roadmap and our decision to keep the v1 product focused on solo and small-clinic doctors rather than large hospitals — which would require deeper integration work and more complex governance."),

  h3("2.2.2  Competitive Analysis"),
  p("We conducted a structured competitive analysis of seven leading digital health platforms, divided into four categories:"),

  bullet("Appointment-booking platforms: Vezeeta (MENA region), Doctolib (Europe), ZocDoc (USA), Practo (India)."),
  bullet("Tele-consultation platforms: Babylon Health, Teladoc, MDLive."),
  bullet("Symptom checkers and AI assistants: Ada Health, K Health, Buoy Health."),
  bullet("Personal health record systems: Apple Health, Google Fit, Epic MyChart."),

  p("For each platform, we evaluated the discovery experience, the booking flow, the communication features, the payment model, the data ownership posture, the support for non-English languages, and the overall design quality. We then mapped each platform against a feature matrix that helped us see, at a glance, where the gaps were."),

  h3("2.2.3  Academic Literature"),
  p("Finally, we reviewed approximately twenty academic papers and industry reports covering telemedicine adoption, human-centred design in healthcare, real-time messaging architectures, mobile health (mHealth) accessibility, AI-assisted triage, privacy in health-data systems, and the regulatory landscape in Egypt and the GCC. While we do not reproduce the full bibliography here, the most influential themes from this body of work are reflected throughout the subsequent chapters."),

  // ----------------------------------------------------------------------- //
  h2("2.3  Challenges in Existing Solutions"),
  p("Despite the impressive number of digital healthcare platforms available, the field is far from solved. A careful review of existing applications — combined with the feedback we gathered from our stakeholders — reveals a recurring set of weaknesses that prevent them from delivering on their promise."),

  h3("2.3.1  Limited Accessibility to Accurate Healthcare Information"),
  p("Many directory applications provide basic doctor listings without verifying that the information is accurate, up-to-date, or complete. Working hours change, doctors switch clinics, and fees are updated, but the directory rarely catches up. Patients who rely on outdated information end up wasting time, calling clinics that have moved, or arriving at closed doors. Find Your Clinic addresses this with a structured admin verification flow, with doctor-controlled profile updates, and with explicit availability slots managed by the doctor themselves."),

  h3("2.3.2  Inefficient Appointment Booking Processes"),
  p("In several existing platforms, booking is technically present but practically incomplete. Patients are required to leave the app to call the clinic, fill in a non-standard form, or wait for human confirmation that may take hours. Real-time, slot-based booking with instant confirmation remains the exception rather than the rule, especially in markets like Egypt. Find Your Clinic uses a slot-based availability model with server-side conflict detection so that booking is final the moment the patient taps Confirm."),

  h3("2.3.3  Weak Location-Based Services"),
  p("Even when search filters by location are offered, many platforms rely on coarse city-level granularity rather than true geographic distance. Patients are shown doctors who are nominally in the same city but practically inaccessible. Find Your Clinic uses geolocation and explicit clinic coordinates to support distance-based ranking and a nearby-clinics view backed by an open map provider."),

  h3("2.3.4  Lack of Direct Communication Channels"),
  p("After the visit, the patient–doctor relationship typically becomes one-way and slow. Many platforms simply do not provide a structured way for a patient to ask the doctor a follow-up question. Where it exists, the communication channel is often unsecured (personal WhatsApp), unscalable for doctors, or hidden behind a paywall. Find Your Clinic embeds a secure, role-aware, real-time chat directly into the application, enabled automatically after a confirmed appointment and protected by JWT-based authorisation."),

  h3("2.3.5  Fragmented User Experience"),
  p("Patients today are forced to assemble their healthcare experience from many disconnected tools: a directory site to find the doctor, a phone call to confirm availability, cash to pay, a paper prescription to remember, a personal note to track medications. Each handoff is an opportunity for friction and error. Find Your Clinic consolidates the entire journey into a single mobile app, eliminating most of these handoffs."),

  h3("2.3.6  Low Usability and Poor Interface Design"),
  p("Some existing solutions suffer from cluttered interfaces, inconsistent navigation, or excessive medical jargon. These issues disproportionately affect elderly users and users with limited digital literacy — the very groups most likely to need healthcare assistance. Find Your Clinic places a strong emphasis on simple, scannable layouts, large tap targets, clear labels, dark-mode support, and a voice-driven assistant for users who prefer speech to typing."),

  h3("2.3.7  Limited Support for Diverse User Groups"),
  p("Many platforms ship only in English, ignoring large segments of the population. Few support right-to-left layouts properly, and even fewer provide accessibility affordances such as high-contrast themes, scalable typography, or voice control. Find Your Clinic ships with Arabic and English support, supports right-to-left layouts natively, and includes voice commands as a first-class feature."),

  h3("2.3.8  Trust and Reliability Concerns"),
  p("Patients are understandably cautious when entrusting their health and money to a digital platform. Yet many directory apps publish unverified profiles, fail to moderate reviews, and do not explain how doctor credentials were checked. The result is a credibility deficit that undermines adoption. Find Your Clinic addresses this with an explicit admin verification workflow: doctors upload documents, admins review them, and only approved doctors become discoverable. Reviews are moderated, financial transactions are logged for audit, and all communication takes place over HTTPS with JWT-secured WebSocket channels."),

  // ----------------------------------------------------------------------- //
  h2("2.4  Summary of Key Gaps in Literature"),
  p("Synthesising the issues identified above, we found seven distinct gaps that consistently appear across the existing literature and the existing market. Each of these gaps motivates a specific feature in Find Your Clinic."),

  kvTable(
    [
      ["1. Real-time, slot-based booking", "Most platforms still rely on asynchronous booking with human confirmation. Few provide instant, conflict-free, slot-based booking with immediate notifications to both sides."],
      ["2. Integrated patient–doctor communication", "Direct, in-app, real-time communication remains rare. Where it exists, it is often unsecure, one-way, or limited to text only."],
      ["3. True location-aware search", "Coarse city filters are common; fine-grained, distance-ranked discovery using device GPS is uncommon."],
      ["4. Unified profile, booking, payment, chat, and records", "The same patient typically uses 3–5 different apps and tools to complete a healthcare interaction. A unified experience is the exception."],
      ["5. Personalisation and user-centred features", "Most apps treat all patients identically. Few adapt to the patient's recent specialty, location, language preference, or interaction history."],
      ["6. Inclusivity across demographics and languages", "Arabic, right-to-left layouts, accessible typography, and voice interaction are still poorly supported."],
      ["7. Verified, trustworthy directories", "Many directories publish unverified doctor profiles and fail to moderate reviews, undermining user trust."],
    ],
    ["Identified Gap", "Description"]
  ),

  // ----------------------------------------------------------------------- //
  h2("2.5  Relevance of the Literature to Find Your Clinic"),
  p("The literature review described above directly shaped almost every product and engineering decision in Find Your Clinic. The connections are explicit and intentional."),

  h3("Real-time access drove the architecture"),
  p("Because patients consistently demand instant booking and direct doctor communication, Find Your Clinic adopts a real-time architecture from the ground up. The backend exposes a SignalR hub for chat, sends Firebase Cloud Messaging push notifications for any status change, and uses optimistic UI patterns on the mobile side to keep the experience responsive even on slow networks."),

  h3("Inclusivity drove the design system"),
  p("Because the literature highlights the failure of many apps to serve diverse user groups, Find Your Clinic was designed from day one with Arabic and English support, full right-to-left layout, dark and light themes, and a voice-driven assistant. Material 3 typography ensures legibility across screen sizes."),

  h3("Trust drove the verification workflow"),
  p("Because credibility is the most fragile component of a healthcare platform, Find Your Clinic invests heavily in admin-side verification. Doctors must upload identity documents, medical licences, and proof of practice; admins review them before any doctor becomes discoverable. Reviews are moderated. Financial transactions are stored in a transaction ledger that supports refunds and audit."),

  h3("Unified experience drove the platform scope"),
  p("Because patients are tired of bouncing between five apps, Find Your Clinic deliberately integrates search, booking, payment, chat, records, and AI inside a single mobile application. This is a strategic decision rather than a technical one: it costs more to build, but it is exactly what users repeatedly told us they wanted."),

  h3("AI assistance was added to address information asymmetry"),
  p("Because patients are unsure which specialty to consult, Find Your Clinic embeds a Gemini-based AI assistant that helps them describe symptoms in natural language, suggests an appropriate specialty, and prepares them for the consultation. The assistant is explicit about its limits: it is not a doctor, it does not provide diagnoses, and it always recommends professional consultation for serious symptoms."),

  // ----------------------------------------------------------------------- //
  h2("2.6  Conclusion"),
  p("The literature review reveals a paradox in digital healthcare: despite a flood of apps and platforms, patients still struggle to access reliable doctors quickly, communicate with them effectively, and maintain a unified view of their own health. The persistent gaps are not technical novelties — they are foundational requirements that competing solutions have repeatedly failed to deliver."),

  p("Find Your Clinic is designed as a direct response to those persistent gaps. It is informed by real conversations with patients, doctors, and administrators in Egypt; benchmarked against the best international platforms; and built on a modern technical foundation that allows it to deliver real-time booking, secure communication, integrated payment, personal health records, and AI-powered guidance inside a single coherent product. The remaining chapters describe how that product was specified, designed, implemented, and tested."),

  pageBreak(),
];

module.exports = { chapter2 };
