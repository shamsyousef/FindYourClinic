part of 'app_router.dart';

/// Centralized route name constants to avoid magic strings.
class RouteNames {
  RouteNames._();

  // Auth
  static const splash = 'splash';
  static const login = 'login';
  static const signUp = 'signUp';
  static const forgotPassword = 'forgotPassword';
  static const otp = 'otp';
  static const resetPassword = 'resetPassword';

  // Doctor Onboarding
  static const doctorDocuments = 'doctorDocuments';
  static const doctorPending = 'doctorPending';
  static const doctorRejected = 'doctorRejected';
  static const onboarding = 'onboarding';

  // Patient Shell
  static const patientHome = 'patientHome';
  static const patientAppointments = 'patientAppointments';
  static const patientMessages = 'patientMessages';
  static const patientRecords = 'patientRecords';
  static const patientProfile = 'patientProfile';

  // Doctor Shell
  static const doctorHome = 'doctorHome';
  static const manageAvailability = 'manageAvailability';
  static const doctorAppointments = 'doctorAppointments';
  static const doctorChat = 'doctorChat';
  static const doctorInsights = 'doctorInsights';
  static const doctorProfile = 'doctorProfile';
  static const doctorProfileEdit = 'doctorProfileEdit';
  static const doctorProfileDocuments = 'doctorProfileDocuments';

  // Discovery & Detail
  static const search = 'search';
  static const doctorDetails = 'doctorDetails';
  static const nearbyClinics = 'nearbyClinics';
  static const notifications = 'notifications';

  // Chat
  static const chatDetail = 'chatDetail';

  // Appointments
  static const bookAppointment = 'bookAppointment';
  static const appointmentDetail = 'appointmentDetail';

  // Health Records
  static const healthRecordDetail = 'healthRecordDetail';
  static const addHealthRecord = 'addHealthRecord';

  // Patient Profile
  static const patientProfileEdit = 'patientProfileEdit';

  // Settings
  static const settings = 'settings';
  static const changePassword = 'changePassword';

  // AI Health
  static const aiChat = 'aiChat';
  static const symptomChecker = 'symptomChecker';
  static const symptomResult = 'symptomResult';
}

