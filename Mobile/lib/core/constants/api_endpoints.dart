/// All API endpoint paths in one place.
/// Base URL is configured in ApiClient.
class ApiEndpoints {
  ApiEndpoints._();

  // ─── Auth ───
  static const login = '/api/auth/login';
  static const register = '/api/auth/register';
  static const googleLogin = '/api/auth/google';
  static const forgotPassword = '/api/auth/forgot-password';
  static const resetPassword = '/api/auth/reset-password';
  static const changePassword = '/api/auth/change-password';
  static const refreshToken = '/api/auth/refresh-token';
  static const uploadDoctorDocuments = '/api/auth/doctor/upload-documents';

  // ─── Users ───
  static const userProfile = '/api/users/profile';
  static const userProfileImage = '/api/users/profile/image';

  // ─── Notifications ───
  static const notifications = '/api/notifications';
  static const deviceToken = '/api/notifications/device-token';
  static String markNotificationRead(String id) => '/api/notifications/$id/read';

  // ─── Doctors ───
  static const doctors = '/api/doctors';
  static const topRatedDoctors = '/api/doctors/top-rated';
  static String doctorDetails(String id) => '/api/doctors/$id';
  static String doctorAvailability(String id) => '/api/doctors/$id/availability';
  static String doctorWeeklySchedule(String id) => '/api/doctors/$id/weekly-schedule';
  static const updateDoctorProfile = '/api/doctors/profile';
  static const doctorMyStatus = '/api/doctors/me/status';
  static const doctorMyDocuments = '/api/doctors/me/documents';

  // ─── Doctor Availability ───
  static String doctorSlots(String doctorId) =>
      '/api/doctors/availability/$doctorId/slots';
  static const createAvailability = '/api/doctors/availability';
  static String updateAvailability(String id) => '/api/doctors/availability/$id';

  // ─── Admin ───
  static const pendingDoctors = '/api/admin/doctors/pending';
  static String approveDoctor(String id) => '/api/admin/doctors/$id/approve';
  static String rejectDoctor(String id) => '/api/admin/doctors/$id/reject';

  // ─── Appointments ───
  static const appointments = '/api/appointments';
  static const myAppointments = '/api/appointments/my';
  static const doctorAppointments = '/api/appointments/doctor/my';
  static String appointmentById(String id) => '/api/appointments/$id';
  static String cancelAppointment(String id) => '/api/appointments/$id/cancel';
  static String confirmAppointment(String id) => '/api/appointments/$id/confirm';
  static String completeAppointment(String id) => '/api/appointments/$id/complete';

  // ─── Reviews ───
  static String doctorReviews(String doctorId) =>
      '/api/doctors/$doctorId/reviews';

  // ─── Health Records ───
  static const healthRecords = '/api/health-records';
  static String healthRecord(String id) => '/api/health-records/$id';
  static const healthSummary = '/api/health-records/summary';
  static String patientHealthRecords(String patientId) => '/api/health-records/patient/$patientId';

  // ─── Users (Doctor access) ───
  static String patientProfileForDoctor(String patientId) => '/api/users/patient/$patientId';

  // ─── Messages ───
  static const conversations = '/api/messages/conversations';
  static String conversationMessages(String id) =>
      '/api/messages/conversations/$id';
  static String startConversation(String doctorId) =>
      '/api/messages/conversations/$doctorId';
  static String sendMessage(String id) =>
      '/api/messages/conversations/$id/send';
  static String markConversationRead(String id) =>
      '/api/messages/conversations/$id/read';

  // ─── Home ───
  static const homeSummary = '/api/home/summary';
  static const doctorDashboard = '/api/doctors/dashboard';

  // ─── Specialties ───
  static const specialties = '/api/specialties';

  // ─── AI Health ───
  static const aiChat = '/api/ai/chat';
  static const aiChatHistory = '/api/ai/chat/history';
  static const aiSymptomsAnalyze = '/api/ai/symptoms/analyze';

  // ─── SignalR ───
  static const chatHub = '/hubs/chat';
}
