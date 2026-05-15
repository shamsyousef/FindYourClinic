const { AlignmentType, TextRun, Paragraph, TableOfContents } = require("docx");
const {
  PRIMARY, ACCENT, MUTED,
  centeredTitle, centeredText, blank, pageBreak,
  chapterTitle, h2, p, bullet, lead, imagePlaceholder, run,
} = require("./helpers");

// =========================================================================
// Cover page
// =========================================================================
const cover = () => [
  ...blank(2),
  centeredText("Arab Republic of Egypt", 24, { bold: true }),
  centeredText("Ministry of Higher Education and Scientific Research", 24, { bold: true }),
  centeredText("University of Sadat City", 24, { bold: true }),
  centeredText("Faculty of Computers and Artificial Intelligence", 24, { bold: true }),
  ...blank(2),

  // Placeholder for the faculty logos
  ...imagePlaceholder("Cover", "University and Faculty logos", "≈ 4 cm tall"),
  ...blank(2),

  centeredTitle("Find Your Clinic", 64, PRIMARY),
  centeredTitle("Healthcare Directory Platform", 40, ACCENT),
  ...blank(1),
  centeredText("A Smart Cross-Platform System for Connecting Patients, Doctors, and Clinics", 22, {
    italics: true, color: MUTED,
  }),
  ...blank(3),

  centeredText("Graduation Project", 28, { bold: true }),
  centeredText("By", 26, { bold: true }),
  ...blank(1),
  centeredText("Ahmed Sami AboAziz          Abdelrahman Ragab Sharaf", 24),
  centeredText("Ahmed Ashraf Khatab          Mina Kamal", 24),
  centeredText("Shams Ashraf Ali          Farah Ayman Sadeek", 24),
  ...blank(2),

  centeredText("Under the supervision of", 24, { bold: true }),
  ...blank(1),
  centeredText("Prof. Ibrahim Salim          Dr. Ahmed Tealeb", 24),
  ...blank(3),

  new Paragraph({
    alignment: AlignmentType.CENTER,
    spacing: { before: 120, after: 120, line: 320 },
    children: [
      new TextRun({
        text: "A graduation project submitted to the Faculty of Computers and Artificial Intelligence in partial fulfillment of the requirements for the degree of Bachelor of Computer Science and Artificial Intelligence.",
        font: "Calibri",
        size: 22,
        italics: true,
        color: MUTED,
      }),
    ],
  }),

  ...blank(2),
  centeredText("Egypt — 2026", 26, { bold: true, color: PRIMARY }),
  pageBreak(),
];

// =========================================================================
// Examination Committee
// =========================================================================
const committee = () => [
  ...blank(1),
  centeredTitle("Examination Committee Page", 36),
  ...blank(2),

  p("The committee for"),
  ...blank(1),
  centeredText("Ahmed Sami AboAziz          Abdelrahman Ragab Sharaf", 24, { bold: true }),
  centeredText("Ahmed Ashraf Khatab          Mina Kamal", 24, { bold: true }),
  centeredText("Shams Ashraf Ali          Farah Ayman Sadeek", 24, { bold: true }),
  ...blank(2),

  p("Certifies that this is the approved version of the following graduation project and is acceptable in quality and form for publication in paper and in digital formats:"),
  ...blank(1),
  centeredTitle("Find Your Clinic — Healthcare Directory Platform", 32),
  ...blank(2),

  centeredText("Graduation Project Committee Members", 24, { bold: true }),
  ...blank(2),

  p("Supervisor:"),
  p("Signature: ________________________________      Date: _____________________"),
  ...blank(1),
  p("Co-Supervisor:"),
  p("Signature: ________________________________      Date: _____________________"),
  ...blank(1),
  p("First Member:"),
  p("Signature: ________________________________      Date: _____________________"),
  ...blank(1),
  p("Second Member:"),
  p("Signature: ________________________________      Date: _____________________"),
  ...blank(3),

  centeredText("University of Sadat City", 24, { bold: true }),
  centeredText("Faculty of Computers and Artificial Intelligence", 24, { bold: true }),
  centeredText("2026", 24, { bold: true }),
  pageBreak(),
];

// =========================================================================
// Abstract (English)
// =========================================================================
const abstractEn = () => [
  chapterTitle("Abstract"),
  lead("Find Your Clinic is an integrated healthcare directory platform that bridges the gap between patients and verified medical professionals through a modern, cross-platform digital experience. The system combines a mobile application for patients and doctors, an administrative dashboard for platform operators, and a robust cloud-ready API, delivering an end-to-end workflow that covers doctor discovery, appointment booking, real-time consultation, secure payments, and personal health record management."),

  p("The platform addresses a long-standing problem faced by patients across Egypt and similar markets: difficulty in locating qualified doctors near them, lack of visibility into appointment availability, fragmented communication channels, and limited access to verified medical information. Traditional methods such as personal referrals, phone calls, and inconsistent online listings introduce delays, increase uncertainty, and discourage timely care. Find Your Clinic consolidates these touchpoints into a single, trustworthy mobile experience designed for both patients and healthcare providers."),

  p("At the core of the platform is a powerful directory engine that allows patients to search and filter doctors by specialty, location, rating, language, and consultation fee. Each doctor maintains a verified public profile, manages working hours through a built-in availability planner, and exposes a list of bookable time slots in real time. Patients can request appointments instantly, pay through an integrated payment gateway, and exchange messages, voice notes, and medical attachments with their doctors over a secure real-time chat channel."),

  p("In addition to discovery and booking, the system provides an AI Health Assistant powered by Google’s Gemini large language model. The assistant supports both text and voice interaction, helping patients understand symptoms, prepare for consultations, and decide which specialty fits their case — without replacing professional medical judgment. A complementary digital Health Records module allows patients to securely store medications, lab results, allergies, and chronic conditions, and to share them selectively with treating doctors."),

  p("The administrative side of the platform is delivered as a Next.js web dashboard. It empowers operators to verify doctor identities and credentials, moderate reviews, manage medical specialties, supervise the financial workflow (consultation payments, doctor wallets, and payouts), and inspect platform-wide analytics. Strong identity, role-based access control, and encrypted communication channels ensure that sensitive medical and financial data is handled responsibly across all three clients."),

  p("Technically, the project is built on a clean and scalable architecture: a Flutter mobile application with Cubit/Bloc state management, a .NET 10 backend organized around MediatR vertical slices and Entity Framework Core on SQL Server, real-time chat over SignalR, a Next.js admin dashboard with Tailwind CSS, and a network of external integrations (Cloudinary, Firebase Cloud Messaging, Paymob, Google Sign-In, and Gemini). The result is a production-grade healthcare experience that is fast, secure, accessible, and ready to scale to thousands of doctors and patients."),

  p("Ultimately, Find Your Clinic transforms how patients access healthcare. By centralizing search, scheduling, communication, payment, AI assistance, and records into one cohesive system, the platform reduces friction, encourages earlier consultations, and improves continuity of care for individuals of all ages and backgrounds."),

  pageBreak(),
];

// =========================================================================
// Abstract (Arabic) – النص العربي
// =========================================================================
const abstractAr = () => [
  chapterTitle("الخلاصة"),

  new Paragraph({
    alignment: AlignmentType.RIGHT,
    bidirectional: true,
    spacing: { before: 120, after: 200, line: 360 },
    children: [
      new TextRun({
        text: "منصة Find Your Clinic هي نظام رقمي متكامل للرعاية الصحية يهدف إلى تسهيل وصول المرضى إلى الأطباء المعتمدين من خلال تطبيق جوال حديث ومتعدد المنصات. تجمع المنصة بين تطبيق للجوال للمرضى والأطباء، ولوحة تحكم إدارية على الويب، وواجهة برمجة تطبيقات سحابية قوية، لتقدّم تجربة شاملة تغطي البحث عن الأطباء، وحجز المواعيد، والاستشارة الفورية، والدفع الإلكتروني، وإدارة السجلات الصحية الشخصية.",
        font: "Calibri",
        size: 24,
        rightToLeft: true,
      }),
    ],
  }),

  new Paragraph({
    alignment: AlignmentType.RIGHT,
    bidirectional: true,
    spacing: { before: 120, after: 200, line: 360 },
    children: [
      new TextRun({
        text: "تواجه شريحة كبيرة من المرضى صعوبات حقيقية في العثور على طبيب موثوق قريب منهم، وفي معرفة أوقات عمل العيادات، والتواصل المباشر مع الأطباء، والحصول على معلومات صحية صحيحة. تعالج Find Your Clinic هذه المشكلات بدمج جميع نقاط التفاعل في تطبيق واحد بسيط وآمن وسريع، يدعم المرضى ومقدّمي الخدمة على حدٍ سواء.",
        font: "Calibri",
        size: 24,
        rightToLeft: true,
      }),
    ],
  }),

  new Paragraph({
    alignment: AlignmentType.RIGHT,
    bidirectional: true,
    spacing: { before: 120, after: 200, line: 360 },
    children: [
      new TextRun({
        text: "يوفّر النظام محرّك بحث ذكي يسمح للمريض بتصفية الأطباء حسب التخصص والموقع الجغرافي والتقييم وسعر الكشف. ولكل طبيب صفحة عامة موثّقة وجدول مواعيد متاح فوريًا، ويستطيع المريض الحجز ودفع الكشف إلكترونيًا، ثم التواصل مع طبيبه عبر دردشة آمنة في الوقت الحقيقي تدعم الرسائل النصية والصوتية والمرفقات الطبية.",
        font: "Calibri",
        size: 24,
        rightToLeft: true,
      }),
    ],
  }),

  new Paragraph({
    alignment: AlignmentType.RIGHT,
    bidirectional: true,
    spacing: { before: 120, after: 200, line: 360 },
    children: [
      new TextRun({
        text: "تتضمن المنصة كذلك مساعدًا صحيًا ذكيًا مبنيًا على نموذج Gemini من Google يدعم النص والصوت، ويُمكّن المريض من فهم أعراضه واختيار التخصص المناسب دون أن يحلّ محل الطبيب. كما يوفّر النظام وحدة سجلات صحية رقمية تخزّن الأدوية ونتائج التحاليل والحساسيات والأمراض المزمنة، ويمكن مشاركتها بأمان مع الطبيب المعالج.",
        font: "Calibri",
        size: 24,
        rightToLeft: true,
      }),
    ],
  }),

  new Paragraph({
    alignment: AlignmentType.RIGHT,
    bidirectional: true,
    spacing: { before: 120, after: 200, line: 360 },
    children: [
      new TextRun({
        text: "أما على المستوى الإداري، فتُوفَّر لوحة تحكم ويب مبنية على Next.js تمكّن المسؤولين من توثيق الأطباء، ومراجعة التقييمات، وإدارة التخصصات، ومراقبة العمليات المالية، واستخراج الإحصاءات. ويعتمد النظام على هوية رقمية قوية وصلاحيات وصول دقيقة وبروتوكولات تشفير حديثة لضمان حماية البيانات الصحية والمالية الحساسة.",
        font: "Calibri",
        size: 24,
        rightToLeft: true,
      }),
    ],
  }),

  new Paragraph({
    alignment: AlignmentType.RIGHT,
    bidirectional: true,
    spacing: { before: 120, after: 200, line: 360 },
    children: [
      new TextRun({
        text: "تم بناء المشروع باستخدام Flutter للتطبيق الجوال مع نمط Cubit/Bloc، وواجهة برمجة تطبيقات .NET 10 معتمدة على MediatR و Entity Framework Core فوق SQL Server، ودردشة لحظية عبر SignalR، ولوحة تحكم Next.js مع Tailwind CSS، إضافة إلى تكامل مع Cloudinary وFirebase Cloud Messaging وPaymob وGoogle Sign-In وGemini. النتيجة منصة جاهزة للإنتاج وقابلة للتوسع لخدمة آلاف الأطباء والمرضى.",
        font: "Calibri",
        size: 24,
        rightToLeft: true,
      }),
    ],
  }),

  pageBreak(),
];

// =========================================================================
// Acknowledgments
// =========================================================================
const acknowledgments = () => [
  chapterTitle("Acknowledgments"),
  ...blank(1),
  centeredText("In the Name of Allah, the Most Gracious, the Most Merciful", 24, { italics: true, color: MUTED }),
  ...blank(2),

  p("We extend our sincere gratitude to every individual who supported and contributed to the successful completion of this graduation project. The journey of building Find Your Clinic was long and challenging, and reaching this stage would not have been possible without the guidance, knowledge, and encouragement we received throughout."),

  p("First and foremost, we express our deepest appreciation to our esteemed supervisor, Dr. Ahmed Tealeb, whose unwavering support, insightful feedback, and expert guidance played a pivotal role in shaping the technical and academic foundations of this work. His commitment to excellence, his openness to innovation, and his sincere care for our progress motivated us to continually raise the quality of every component we built."),

  p("We are equally grateful to Prof. Ibrahim Salim for his valuable mentorship and continuous encouragement. His vast experience in computer science research and his clear, structured way of thinking helped us refine the architecture, methodology, and scientific framing of this project."),

  p("Our sincere thanks go to the Faculty of Computers and Artificial Intelligence at the University of Sadat City for providing the academic environment, the courses, and the supporting resources that prepared us for a project of this scale. We also thank the lecturers and teaching assistants who, throughout four years of study, equipped us with the foundations of programming, software engineering, databases, artificial intelligence, and human-computer interaction that came together in this work."),

  p("We extend our gratitude to the doctors, medical staff, and patients who participated in our user research interviews and surveys. Their honest feedback and lived experience shaped the design of every screen, every workflow, and every feature in the platform."),

  p("Finally, we thank our families and friends for their endless patience, encouragement, and emotional support throughout the long hours of design, development, and revision. Their belief in us has been a constant source of strength."),

  p("To all those who contributed to this project — directly or indirectly — we are truly grateful. This achievement is, in many ways, theirs as much as it is ours."),

  pageBreak(),
];

// =========================================================================
// Table of Contents (auto-generated by Word from headings)
// =========================================================================
const tableOfContents = () => [
  chapterTitle("Table of Contents"),
  new Paragraph({
    spacing: { before: 200, after: 200 },
    children: [
      new TextRun({
        text: "To refresh this table inside Microsoft Word: right-click anywhere on the list below and choose \"Update Field\" → \"Update entire table\".",
        font: "Calibri",
        size: 20,
        italics: true,
        color: MUTED,
      }),
    ],
  }),
  new TableOfContents("Table of Contents", {
    hyperlink: true,
    headingStyleRange: "1-3",
  }),
  pageBreak(),
];

// =========================================================================
// List of Figures
// =========================================================================
const listOfFigures = () => [
  chapterTitle("List of Figures"),
  ...blank(1),
  bullet("Figure 1 — System Architecture of the Find Your Clinic Platform"),
  bullet("Figure 2 — Entity Relationship Diagram (ERD) of the Domain Model"),
  bullet("Figure 3 — UML Class Diagram of Core Domain Entities"),
  bullet("Figure 4 — Use Case Diagram for Patient, Doctor, and Admin Actors"),
  bullet("Figure 5 — Patient Workflow Diagram"),
  bullet("Figure 6 — Doctor Workflow Diagram"),
  bullet("Figure 7 — Admin Workflow Diagram"),
  bullet("Figure 8 — Real-Time Chat Sequence Diagram"),
  bullet("Figure 9 — Appointment Booking Sequence Diagram"),
  bullet("Figure 10 — AI Health Assistant Interaction Flow"),
  bullet("Figure 11 — Splash and Onboarding Screens"),
  bullet("Figure 12 — Authentication Screens (Login, Sign-up, Password Reset)"),
  bullet("Figure 13 — Patient Home and Search Screens"),
  bullet("Figure 14 — Doctor Profile and Availability Screens"),
  bullet("Figure 15 — Appointment Booking and Payment Screens"),
  bullet("Figure 16 — Chat and Voice Note Screens"),
  bullet("Figure 17 — AI Assistant Chat Screen"),
  bullet("Figure 18 — Health Records Screens"),
  bullet("Figure 19 — Doctor Dashboard and Earnings Screens"),
  bullet("Figure 20 — Admin Dashboard Overview"),
  bullet("Figure 21 — Admin Doctor Approval and Moderation Screens"),
  pageBreak(),
];

// =========================================================================
// List of Abbreviations
// =========================================================================
const listOfAbbreviations = () => [
  chapterTitle("List of Abbreviations"),
  ...blank(1),
  bullet([run("AI", { bold: true }), run(" — Artificial Intelligence")]),
  bullet([run("API", { bold: true }), run(" — Application Programming Interface")]),
  bullet([run("BLoC", { bold: true }), run(" — Business Logic Component (Flutter state management)")]),
  bullet([run("CDN", { bold: true }), run(" — Content Delivery Network")]),
  bullet([run("CRUD", { bold: true }), run(" — Create, Read, Update, Delete")]),
  bullet([run("DI", { bold: true }), run(" — Dependency Injection")]),
  bullet([run("EF Core", { bold: true }), run(" — Entity Framework Core (ORM for .NET)")]),
  bullet([run("ERD", { bold: true }), run(" — Entity Relationship Diagram")]),
  bullet([run("FCM", { bold: true }), run(" — Firebase Cloud Messaging")]),
  bullet([run("HCI", { bold: true }), run(" — Human-Computer Interaction")]),
  bullet([run("HTTP / HTTPS", { bold: true }), run(" — HyperText Transfer Protocol (Secure)")]),
  bullet([run("JWT", { bold: true }), run(" — JSON Web Token")]),
  bullet([run("LLM", { bold: true }), run(" — Large Language Model")]),
  bullet([run("MediatR", { bold: true }), run(" — Mediator-pattern library used in the .NET API")]),
  bullet([run("MVP", { bold: true }), run(" — Minimum Viable Product")]),
  bullet([run("NLP", { bold: true }), run(" — Natural Language Processing")]),
  bullet([run("OAuth", { bold: true }), run(" — Open Authorization protocol")]),
  bullet([run("OS", { bold: true }), run(" — Operating System")]),
  bullet([run("REST", { bold: true }), run(" — Representational State Transfer")]),
  bullet([run("RLS", { bold: true }), run(" — Row-Level Security")]),
  bullet([run("SDK", { bold: true }), run(" — Software Development Kit")]),
  bullet([run("SignalR", { bold: true }), run(" — Real-time communication library for ASP.NET")]),
  bullet([run("SMS", { bold: true }), run(" — Short Message Service")]),
  bullet([run("SMTP", { bold: true }), run(" — Simple Mail Transfer Protocol")]),
  bullet([run("SPA", { bold: true }), run(" — Single Page Application")]),
  bullet([run("SQL", { bold: true }), run(" — Structured Query Language")]),
  bullet([run("SSL / TLS", { bold: true }), run(" — Transport-layer encryption")]),
  bullet([run("TTS / STT", { bold: true }), run(" — Text-to-Speech / Speech-to-Text")]),
  bullet([run("UI / UX", { bold: true }), run(" — User Interface / User Experience")]),
  bullet([run("UML", { bold: true }), run(" — Unified Modeling Language")]),
  pageBreak(),
];

module.exports = {
  cover,
  committee,
  abstractEn,
  abstractAr,
  acknowledgments,
  tableOfContents,
  listOfFigures,
  listOfAbbreviations,
};
