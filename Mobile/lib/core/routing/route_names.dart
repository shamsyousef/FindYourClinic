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
  static const doctorAppointments = 'doctorAppointments';
  static const doctorChat = 'doctorChat';
  static const doctorInsights = 'doctorInsights';
  static const doctorProfile = 'doctorProfile';
}
