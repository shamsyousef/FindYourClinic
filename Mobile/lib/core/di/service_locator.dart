import 'package:get_it/get_it.dart';

import '../network/api_client.dart';
import '../theme/theme_mode_cubit.dart';
import '../utils/token_storage.dart';
import '../../features/auth/data/repos/auth_repository_impl.dart';
import '../../features/auth/domain/repos/auth_repository.dart';
import '../../features/auth/domain/usecases/auth_usecases.dart';
import '../../features/auth/presentation/cubits/auth_cubit.dart';
import '../../features/doctor_onboarding/data/repos/onboarding_repository_impl.dart';
import '../../features/doctor_onboarding/domain/repos/onboarding_repository.dart';
import '../../features/doctor_onboarding/domain/usecases/get_my_documents_usecase.dart';
import '../../features/doctor_onboarding/domain/usecases/upload_documents_usecase.dart';
import '../../features/doctor_onboarding/presentation/cubits/onboarding_cubit.dart';
import '../../features/auth/data/repos/specialty_repository_impl.dart';
import '../../features/auth/domain/repos/specialty_repository.dart';
import '../../features/auth/domain/usecases/get_specialties_usecase.dart';
import '../../features/auth/presentation/cubits/specialty_cubit.dart';

// Patient Home
import '../../features/patient_home/data/repos/home_repository_impl.dart';
import '../../features/patient_home/domain/repos/home_repository.dart';
import '../../features/patient_home/domain/usecases/get_home_summary_usecase.dart';
import '../../features/patient_home/presentation/cubits/patient_home_cubit.dart';

// Home Highlights
import '../../features/home_highlights/presentation/cubits/home_highlights_cubit.dart';

// Doctor Home
import '../../features/doctor_home/data/repos/doctor_dashboard_repository_impl.dart';
import '../../features/doctor_home/domain/repos/doctor_dashboard_repository.dart';
import '../../features/doctor_home/domain/usecases/get_doctor_dashboard_usecase.dart';
import '../../features/doctor_home/presentation/cubits/doctor_home_cubit.dart';
import '../../features/doctor_home/presentation/cubits/insights_cubit.dart';

// Search
import '../../features/search/data/repos/doctor_search_repository_impl.dart';
import '../../features/search/domain/repos/doctor_search_repository.dart';
import '../../features/search/domain/usecases/search_doctors_usecase.dart';
import '../../features/search/presentation/cubits/search_cubit.dart';

// Doctor Profile
import '../../features/doctor_profile/data/repos/doctor_profile_repository_impl.dart';
import '../../features/doctor_profile/domain/repos/doctor_profile_repository.dart';
import '../../features/doctor_profile/domain/usecases/doctor_profile_usecases.dart';
import '../../features/doctor_profile/presentation/cubits/doctor_profile_cubit.dart';
import '../../features/doctor_profile/presentation/cubits/doctor_shell_profile_cubit.dart';
import '../../features/doctor_profile/presentation/cubits/edit_doctor_profile_cubit.dart';

// Nearby Clinics
import '../../features/nearby_clinics/presentation/cubits/nearby_clinics_cubit.dart';

// Notifications
import '../../features/notifications/data/repos/notification_repository_impl.dart';
import '../../features/notifications/domain/repos/notification_repository.dart';
import '../../features/notifications/domain/usecases/notification_usecases.dart';
import '../../features/notifications/presentation/cubits/notification_badge_cubit.dart';
import '../../features/notifications/presentation/cubits/notifications_cubit.dart';

// Appointments
import '../../features/appointments/data/repos/appointment_repository_impl.dart';
import '../../features/appointments/domain/repos/appointment_repository.dart';
import '../../features/appointments/domain/usecases/appointment_usecases.dart';
import '../../features/appointments/presentation/cubits/appointment_cubit.dart';
import '../../features/appointments/presentation/cubits/booking_cubit.dart';

// Chat
import '../../features/chat/data/datasources/chat_remote_datasource.dart';
import '../../features/chat/data/datasources/chat_signalr_datasource.dart';
import '../../features/chat/data/repositories/chat_repository_impl.dart';
import '../../features/chat/domain/repositories/i_chat_repository.dart';
import '../../features/chat/domain/usecases/get_conversations_usecase.dart';
import '../../features/chat/domain/usecases/get_messages_usecase.dart';
import '../../features/chat/domain/usecases/mark_conversation_as_read_usecase.dart';
import '../../features/chat/domain/usecases/send_message_usecase.dart';
import '../../features/chat/domain/usecases/start_conversation_usecase.dart';
import '../../features/chat/presentation/cubit/chat_cubit.dart';
import '../../features/chat/presentation/cubit/conversations_cubit.dart';

import '../../features/doctor_availability/data/datasources/doctor_availability_remote_datasource.dart';
import '../../features/doctor_availability/data/repos/doctor_availability_repository_impl.dart';
import '../../features/doctor_availability/domain/repos/doctor_availability_repository.dart';
import '../../features/doctor_availability/domain/usecases/manage_availability_usecases.dart';
import '../../features/doctor_availability/presentation/cubits/manage_availability_cubit.dart';

// Patient Profile
import '../../features/patient_profile/data/repos/patient_profile_repository_impl.dart';
import '../../features/patient_profile/domain/repos/patient_profile_repository.dart';
import '../../features/patient_profile/domain/usecases/patient_profile_usecases.dart';
import '../../features/patient_profile/presentation/cubits/patient_profile_cubit.dart';

// Patient Card (doctor view)
import '../../features/appointments/presentation/cubits/patient_card_cubit.dart';

// Health Records
import '../../features/health_records/data/repos/health_record_repository_impl.dart';
import '../../features/health_records/domain/repos/health_record_repository.dart';
import '../../features/health_records/domain/usecases/health_record_usecases.dart';
import '../../features/health_records/presentation/cubits/health_record_cubit.dart';

// AI Health
import '../../features/ai_health/data/datasources/ai_health_remote_datasource.dart';
import '../../features/ai_health/data/repos/ai_health_repository_impl.dart';
import '../../features/ai_health/domain/repos/ai_health_repository.dart';
import '../../features/ai_health/domain/usecases/send_message_usecase.dart' as ai_send;
import '../../features/ai_health/domain/usecases/get_chat_history_usecase.dart';
import '../../features/ai_health/domain/usecases/analyze_symptoms_usecase.dart';
import '../../features/ai_health/presentation/cubits/ai_chat_cubit.dart';
import '../../features/ai_health/presentation/cubits/symptom_checker_cubit.dart';
import '../../features/ai_health/presentation/cubits/voice_input_cubit.dart';
import '../services/tts_service.dart';

// Accessibility (voice assistant for blind patients)
import '../../features/accessibility/data/accessibility_preferences_store.dart';
import '../../features/accessibility/data/datasources/voice_command_remote_datasource.dart';
import '../../features/accessibility/data/repos/voice_command_repository_impl.dart';
import '../../features/accessibility/domain/repos/voice_command_repository.dart';
import '../../features/accessibility/domain/usecases/process_voice_command_usecase.dart';
import '../../features/accessibility/presentation/cubits/voice_assistant_cubit.dart';
import '../../features/accessibility/presentation/cubits/voice_assistant_visibility_cubit.dart';

// Payment
import '../../features/payment/data/preferred_payment_method_store.dart';
import '../../features/payment/data/repos/payment_repository_impl.dart';
import '../../features/payment/domain/repos/payment_repository.dart';
import '../../features/payment/domain/usecases/payment_usecases.dart';
import '../../features/payment/presentation/cubits/checkout_cubit.dart';
import '../../features/payment/presentation/cubits/doctor_earnings_cubit.dart';
import '../../features/payment/presentation/cubits/doctor_payment_info_cubit.dart';
import '../../features/payment/presentation/cubits/payment_history_cubit.dart';
import '../../features/payment/presentation/cubits/paymob_webview_cubit.dart';

final sl = GetIt.instance;

/// Initialize all dependencies. Called once at app startup.
Future<void> initServiceLocator() async {
  // ─── Core ───
  sl.registerLazySingleton<TokenStorage>(() => TokenStorage());
  sl.registerLazySingleton<ApiClient>(
    () => ApiClient(tokenStorage: sl<TokenStorage>()),
  );
  sl.registerLazySingleton<ThemeModeCubit>(() => ThemeModeCubit());

  // ─── Auth Feature ───
  _initAuth();

  // ─── Specialty Feature ───
  _initSpecialties();

  // ─── Doctor Onboarding Feature ───
  _initOnboarding();

  // ─── Patient Home Feature ───
  _initPatientHome();

  // ─── Home Highlights Feature ───
  _initHomeHighlights();

  // ─── Doctor Home Feature ───
  _initDoctorHome();

  // ─── Search Feature ───
  _initSearch();

  // ─── Doctor Profile Feature ───
  _initDoctorProfile();

  // ─── Doctor Availability Feature ───
  _initDoctorAvailability();

  // ─── Nearby Clinics Feature ───
  _initNearbyClinics();

  // ─── Notifications Feature ───
  _initNotifications();

  // ─── Appointments Feature ───
  _initAppointments();

  // ─── Chat Feature ───
  _initChat();

  // ─── Patient Profile Feature ───
  _initPatientProfile();

  // ─── Health Records Feature ───
  _initHealthRecords();

  // ─── AI Health Feature ───
  _initAiHealth();

  // ─── Accessibility Feature (depends on AI Health for VoiceInputCubit/TTS
  //     and on Appointments for GetPatientAppointmentsUseCase) ───
  _initAccessibility();

  // ─── Payment Feature ───
  _initPayment();
}

void _initAuth() {
  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      apiClient: sl<ApiClient>(),
      tokenStorage: sl<TokenStorage>(),
    ),
  );

  // Use Cases
  sl.registerFactory(() => LoginUseCase(sl<AuthRepository>()));
  sl.registerFactory(() => RegisterUseCase(sl<AuthRepository>()));
  sl.registerFactory(() => GoogleLoginUseCase(sl<AuthRepository>()));
  sl.registerFactory(() => ForgotPasswordUseCase(sl<AuthRepository>()));
  sl.registerFactory(() => ResetPasswordUseCase(sl<AuthRepository>()));
  sl.registerFactory(() => ChangePasswordUseCase(sl<AuthRepository>()));
  sl.registerFactory(() => LogoutUseCase(sl<AuthRepository>()));
  sl.registerFactory(() => GetDoctorStatusUseCase(sl<AuthRepository>()));
  sl.registerFactory(() => RequestAccountDeletionUseCase(sl<AuthRepository>()));

  // Cubit
  sl.registerFactory(
    () => AuthCubit(
      loginUseCase: sl<LoginUseCase>(),
      registerUseCase: sl<RegisterUseCase>(),
      googleLoginUseCase: sl<GoogleLoginUseCase>(),
      forgotPasswordUseCase: sl<ForgotPasswordUseCase>(),
      resetPasswordUseCase: sl<ResetPasswordUseCase>(),
      changePasswordUseCase: sl<ChangePasswordUseCase>(),
      logoutUseCase: sl<LogoutUseCase>(),
      getDoctorStatusUseCase: sl<GetDoctorStatusUseCase>(),
      requestAccountDeletionUseCase: sl<RequestAccountDeletionUseCase>(),
    ),
  );
}

void _initSpecialties() {
  sl.registerLazySingleton<SpecialtyRepository>(
    () => SpecialtyRepositoryImpl(apiClient: sl<ApiClient>()),
  );
  sl.registerFactory(() => GetSpecialtiesUseCase(sl<SpecialtyRepository>()));
  sl.registerFactory(() => SpecialtyCubit(sl<GetSpecialtiesUseCase>()));
}

void _initOnboarding() {
  sl.registerLazySingleton<OnboardingRepository>(
    () => OnboardingRepositoryImpl(apiClient: sl<ApiClient>()),
  );
  sl.registerFactory(() => GetMyDocumentsUseCase(sl<OnboardingRepository>()));
  sl.registerFactory(() => UploadDocumentsUseCase(sl<OnboardingRepository>()));
  sl.registerFactory(
    () => OnboardingCubit(
      getMyDocumentsUseCase: sl<GetMyDocumentsUseCase>(),
      uploadDocumentsUseCase: sl<UploadDocumentsUseCase>(),
    ),
  );
}

void _initPatientHome() {
  sl.registerLazySingleton<HomeRepository>(
    () => HomeRepositoryImpl(apiClient: sl<ApiClient>()),
  );
  sl.registerFactory(() => GetHomeSummaryUseCase(sl<HomeRepository>()));
  sl.registerFactory(
    () => PatientHomeCubit(getHomeSummaryUseCase: sl<GetHomeSummaryUseCase>()),
  );
}

void _initHomeHighlights() {
  sl.registerFactory(
    () => HomeHighlightsCubit(tokenStorage: sl<TokenStorage>()),
  );
}

void _initDoctorHome() {
  sl.registerLazySingleton<DoctorDashboardRepository>(
    () => DoctorDashboardRepositoryImpl(apiClient: sl<ApiClient>()),
  );
  sl.registerFactory(
    () => GetDoctorDashboardUseCase(sl<DoctorDashboardRepository>()),
  );
  sl.registerFactory(
    () => DoctorHomeCubit(getDashboardUseCase: sl<GetDoctorDashboardUseCase>()),
  );
  sl.registerFactory(() => InsightsCubit(sl<GetDoctorDashboardUseCase>()));
}

void _initSearch() {
  sl.registerLazySingleton<DoctorSearchRepository>(
    () => DoctorSearchRepositoryImpl(apiClient: sl<ApiClient>()),
  );
  sl.registerFactory(() => SearchDoctorsUseCase(sl<DoctorSearchRepository>()));
  sl.registerFactory(
    () => SearchCubit(searchDoctorsUseCase: sl<SearchDoctorsUseCase>()),
  );
}

void _initDoctorProfile() {
  sl.registerLazySingleton<DoctorProfileRepository>(
    () => DoctorProfileRepositoryImpl(apiClient: sl<ApiClient>()),
  );
  sl.registerFactory(
    () => GetDoctorDetailsUseCase(sl<DoctorProfileRepository>()),
  );
  sl.registerFactory(
    () => GetDoctorReviewsUseCase(sl<DoctorProfileRepository>()),
  );
  sl.registerFactory(
    () => GetDoctorAvailabilityUseCase(sl<DoctorProfileRepository>()),
  );
  sl.registerFactory(
    () => AddReviewUseCase(sl<DoctorProfileRepository>()),
  );
  sl.registerFactory(
    () => UpdateDoctorProfileUseCase(sl<DoctorProfileRepository>()),
  );
  sl.registerFactory(
    () => UpdateDoctorProfileImageUseCase(sl<DoctorProfileRepository>()),
  );
  sl.registerFactory(
    () => EditDoctorProfileCubit(
      getDetails: sl<GetDoctorDetailsUseCase>(),
      updateProfile: sl<UpdateDoctorProfileUseCase>(),
      updateProfileImage: sl<UpdateDoctorProfileImageUseCase>(),
    ),
  );
  sl.registerFactory(
    () => DoctorProfileCubit(
      getDetailsUseCase: sl<GetDoctorDetailsUseCase>(),
      getReviewsUseCase: sl<GetDoctorReviewsUseCase>(),
      getAvailabilityUseCase: sl<GetDoctorAvailabilityUseCase>(),
      addReviewUseCase: sl<AddReviewUseCase>(),
    ),
  );
  sl.registerFactory(
    () => DoctorShellProfileCubit(
      getProfile: sl<GetPatientProfileUseCase>(),
      getDetails: sl<GetDoctorDetailsUseCase>(),
      getDashboard: sl<GetDoctorDashboardUseCase>(),
    ),
  );
}

void _initNearbyClinics() {
  // Reuses SearchDoctorsUseCase from _initSearch
  sl.registerFactory(
    () => NearbyClinicsCubit(searchDoctorsUseCase: sl<SearchDoctorsUseCase>()),
  );
}

void _initNotifications() {
  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(apiClient: sl<ApiClient>()),
  );
  sl.registerFactory(
    () => GetNotificationsUseCase(sl<NotificationRepository>()),
  );
  sl.registerFactory(
    () => GetUnreadNotificationCountUseCase(sl<NotificationRepository>()),
  );
  sl.registerFactory(
    () => MarkNotificationReadUseCase(sl<NotificationRepository>()),
  );
  sl.registerFactory(
    () => MarkAllNotificationsReadUseCase(sl<NotificationRepository>()),
  );
  sl.registerFactory(
    () => RegisterDeviceTokenUseCase(sl<NotificationRepository>()),
  );
  sl.registerLazySingleton<NotificationBadgeCubit>(
    () => NotificationBadgeCubit(
      getUnreadCountUseCase: sl<GetUnreadNotificationCountUseCase>(),
    ),
  );
  sl.registerFactory(
    () => NotificationsCubit(
      getNotificationsUseCase: sl<GetNotificationsUseCase>(),
      markReadUseCase: sl<MarkNotificationReadUseCase>(),
      markAllReadUseCase: sl<MarkAllNotificationsReadUseCase>(),
      badgeCubit: sl<NotificationBadgeCubit>(),
    ),
  );
}

void _initAppointments() {
  // Repository
  sl.registerLazySingleton<AppointmentRepository>(
    () => AppointmentRepositoryImpl(apiClient: sl<ApiClient>()),
  );

  // Use Cases
  sl.registerFactory(() => BookAppointmentUseCase(sl<AppointmentRepository>()));
  sl.registerFactory(
    () => GetPatientAppointmentsUseCase(sl<AppointmentRepository>()),
  );
  sl.registerFactory(
    () => GetDoctorAppointmentsUseCase(sl<AppointmentRepository>()),
  );
  sl.registerFactory(
    () => GetAppointmentByIdUseCase(sl<AppointmentRepository>()),
  );
  sl.registerFactory(
    () => GetAvailableSlotsUseCase(sl<AppointmentRepository>()),
  );
  sl.registerFactory(
    () => CancelAppointmentUseCase(sl<AppointmentRepository>()),
  );
  sl.registerFactory(
    () => ConfirmAppointmentUseCase(sl<AppointmentRepository>()),
  );
  sl.registerFactory(
    () => CompleteAppointmentUseCase(sl<AppointmentRepository>()),
  );

  // Cubits
  sl.registerFactory(
    () => AppointmentCubit(
      getPatientAppointmentsUseCase: sl<GetPatientAppointmentsUseCase>(),
      getDoctorAppointmentsUseCase: sl<GetDoctorAppointmentsUseCase>(),
      getAppointmentByIdUseCase: sl<GetAppointmentByIdUseCase>(),
      cancelAppointmentUseCase: sl<CancelAppointmentUseCase>(),
      confirmAppointmentUseCase: sl<ConfirmAppointmentUseCase>(),
      completeAppointmentUseCase: sl<CompleteAppointmentUseCase>(),
      markAsPaidUseCase: sl<MarkAsPaidUseCase>(),
    ),
  );
  sl.registerFactory(
    () => BookingCubit(
      getAvailableSlotsUseCase: sl<GetAvailableSlotsUseCase>(),
      bookAppointmentUseCase: sl<BookAppointmentUseCase>(),
    ),
  );
}

void _initChat() {
  // Data Sources
  sl.registerLazySingleton<ChatRemoteDataSource>(
    () => ChatRemoteDataSourceImpl(sl<ApiClient>()),
  );
  sl.registerLazySingleton<ChatSignalRDataSource>(
    () => ChatSignalRDataSourceImpl(sl<TokenStorage>(), sl<ApiClient>().baseUrl),
  );

  // Repository
  sl.registerLazySingleton<IChatRepository>(
    () => ChatRepositoryImpl(
      sl<ChatRemoteDataSource>(),
      sl<ChatSignalRDataSource>(),
    ),
  );

  // Use Cases
  sl.registerFactory(() => GetConversationsUseCase(sl<IChatRepository>()));
  sl.registerFactory(() => GetMessagesUseCase(sl<IChatRepository>()));
  sl.registerFactory(() => StartConversationUseCase(sl<IChatRepository>()));
  sl.registerFactory(() => SendMessageUseCase(sl<IChatRepository>()));
  sl.registerFactory(() => SendImageMessageUseCase(sl<IChatRepository>()));
  sl.registerFactory(() => SendVideoMessageUseCase(sl<IChatRepository>()));
  sl.registerFactory(() => SendVoiceMessageUseCase(sl<IChatRepository>()));
  sl.registerFactory(() => ReactToMessageUseCase(sl<IChatRepository>()));
  sl.registerFactory(
    () => MarkConversationAsReadUseCase(sl<IChatRepository>()),
  );

  // Cubits
  sl.registerFactory(
    () => ConversationsCubit(
      sl<GetConversationsUseCase>(),
      sl<IChatRepository>(),
    ),
  );

  sl.registerFactoryParam<ChatCubit, String, String?>(
    (conversationId, currentUserId) => ChatCubit(
      conversationId: conversationId,
      currentUserId: currentUserId,
      getMessagesUseCase: sl<GetMessagesUseCase>(),
      sendMessageUseCase: sl<SendMessageUseCase>(),
      sendImageMessageUseCase: sl<SendImageMessageUseCase>(),
      sendVideoMessageUseCase: sl<SendVideoMessageUseCase>(),
      sendVoiceMessageUseCase: sl<SendVoiceMessageUseCase>(),
      reactToMessageUseCase: sl<ReactToMessageUseCase>(),
      markConversationAsReadUseCase: sl<MarkConversationAsReadUseCase>(),
      chatRepository: sl<IChatRepository>(),
    ),
  );
}

void _initDoctorAvailability() {
  sl.registerLazySingleton<DoctorAvailabilityRemoteDataSource>(
    () => DoctorAvailabilityRemoteDataSourceImpl(apiClient: sl()),
  );
  sl.registerLazySingleton<DoctorAvailabilityRepository>(
    () => DoctorAvailabilityRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<GetMyAvailabilityUseCase>(
      () => GetMyAvailabilityUseCase(sl<DoctorAvailabilityRepository>()));
  sl.registerLazySingleton<AddAvailabilityUseCase>(
      () => AddAvailabilityUseCase(sl<DoctorAvailabilityRepository>()));
  sl.registerLazySingleton<RemoveAvailabilityUseCase>(
      () => RemoveAvailabilityUseCase(sl<DoctorAvailabilityRepository>()));
  sl.registerFactory<ManageAvailabilityCubit>(
    () => ManageAvailabilityCubit(
      getMyAvailabilityUseCase: sl<GetMyAvailabilityUseCase>(),
      addAvailabilityUseCase: sl<AddAvailabilityUseCase>(),
      removeAvailabilityUseCase: sl<RemoveAvailabilityUseCase>(),
    ),
  );
}

void _initPatientProfile() {
  sl.registerLazySingleton<PatientProfileRepository>(
    () => PatientProfileRepositoryImpl(apiClient: sl<ApiClient>()),
  );
  sl.registerFactory(() => GetPatientProfileUseCase(sl<PatientProfileRepository>()));
  sl.registerFactory(
    () => GetPatientProfileForDoctorUseCase(sl<PatientProfileRepository>()),
  );
  sl.registerFactory(
    () => UpdatePatientProfileUseCase(sl<PatientProfileRepository>()),
  );
  sl.registerFactory(
    () => UpdatePatientProfileImageUseCase(sl<PatientProfileRepository>()),
  );
  sl.registerFactory(
    () => PatientProfileCubit(
      getProfile: sl<GetPatientProfileUseCase>(),
      updateProfile: sl<UpdatePatientProfileUseCase>(),
      updateProfileImage: sl<UpdatePatientProfileImageUseCase>(),
      getAppointments: sl<GetPatientAppointmentsUseCase>(),
      getHealthSummary: sl<GetHealthSummaryUseCase>(),
    ),
  );
}

void _initHealthRecords() {
  sl.registerLazySingleton<HealthRecordRepository>(
    () => HealthRecordRepositoryImpl(apiClient: sl<ApiClient>()),
  );
  sl.registerFactory(() => GetHealthRecordsUseCase(sl<HealthRecordRepository>()));
  sl.registerFactory(() => GetHealthRecordByIdUseCase(sl<HealthRecordRepository>()));
  sl.registerFactory(() => GetHealthSummaryUseCase(sl<HealthRecordRepository>()));
  sl.registerFactory(() => CreateHealthRecordUseCase(sl<HealthRecordRepository>()));
  sl.registerFactory(() => UpdateHealthRecordUseCase(sl<HealthRecordRepository>()));
  sl.registerFactory(() => DeleteHealthRecordUseCase(sl<HealthRecordRepository>()));
  sl.registerFactory(
    () => GetPatientRecordsForDoctorUseCase(sl<HealthRecordRepository>()),
  );
  sl.registerFactory(
    () => HealthRecordCubit(
      getRecordsUseCase: sl<GetHealthRecordsUseCase>(),
      getByIdUseCase: sl<GetHealthRecordByIdUseCase>(),
      getSummaryUseCase: sl<GetHealthSummaryUseCase>(),
      createUseCase: sl<CreateHealthRecordUseCase>(),
      updateUseCase: sl<UpdateHealthRecordUseCase>(),
      deleteUseCase: sl<DeleteHealthRecordUseCase>(),
    ),
  );
  sl.registerFactory(
    () => PatientCardCubit(
      getProfile: sl<GetPatientProfileForDoctorUseCase>(),
      getRecords: sl<GetPatientRecordsForDoctorUseCase>(),
    ),
  );
}

void _initAiHealth() {
  sl.registerLazySingleton<AiHealthRemoteDataSource>(
    () => AiHealthRemoteDataSourceImpl(sl<ApiClient>()),
  );
  sl.registerLazySingleton<AiHealthRepository>(
    () => AiHealthRepositoryImpl(dataSource: sl<AiHealthRemoteDataSource>()),
  );
  sl.registerFactory(() => ai_send.SendMessageUseCase(sl<AiHealthRepository>()));
  sl.registerFactory(() => GetChatHistoryUseCase(sl<AiHealthRepository>()));
  sl.registerFactory(() => AnalyzeSymptomsUseCase(sl<AiHealthRepository>()));
  sl.registerFactory(
    () => AiChatCubit(sl<ai_send.SendMessageUseCase>(), sl<GetChatHistoryUseCase>()),
  );
  sl.registerFactory(() => SymptomCheckerCubit(sl<AnalyzeSymptomsUseCase>()));

  // Voice
  sl.registerLazySingleton(() => TtsService());
  sl.registerFactory(() => VoiceInputCubit());
}

void _initAccessibility() {
  // Data
  sl.registerLazySingleton(() => AccessibilityPreferencesStore());
  sl.registerLazySingleton<VoiceCommandRemoteDataSource>(
    () => VoiceCommandRemoteDataSourceImpl(sl<ApiClient>()),
  );
  sl.registerLazySingleton<VoiceCommandRepository>(
    () => VoiceCommandRepositoryImpl(
      dataSource: sl<VoiceCommandRemoteDataSource>(),
    ),
  );

  // Domain
  sl.registerLazySingleton(
    () => ProcessVoiceCommandUseCase(sl<VoiceCommandRepository>()),
  );

  // Presentation cubits.
  // Visibility is a singleton so Home and Settings stay in sync.
  sl.registerLazySingleton(
    () => VoiceAssistantVisibilityCubit(sl<AccessibilityPreferencesStore>()),
  );
  // Orchestrator is a singleton too so the patient shell, settings, and any
  // screen all share the same instance and the same active screen-context.
  sl.registerLazySingleton(
    () => VoiceAssistantCubit(
      voiceInputCubit: sl<VoiceInputCubit>(),
      tts: sl<TtsService>(),
      processVoiceCommand: sl<ProcessVoiceCommandUseCase>(),
      getAppointments: sl<GetPatientAppointmentsUseCase>(),
      bookAppointment: sl<BookAppointmentUseCase>(),
    ),
  );
}

void _initPayment() {
  sl.registerLazySingleton<PreferredPaymentMethodStore>(
    () => PreferredPaymentMethodStore(),
  );
  sl.registerLazySingleton<PaymentRepository>(
    () => PaymentRepositoryImpl(apiClient: sl<ApiClient>()),
  );
  sl.registerFactory(() => InitiatePaymentUseCase(sl<PaymentRepository>()));
  sl.registerFactory(() => ConfirmPaymentUseCase(sl<PaymentRepository>()));
  sl.registerFactory(() => GetPaymentHistoryUseCase(sl<PaymentRepository>()));
  sl.registerFactory(() => GetDoctorEarningsUseCase(sl<PaymentRepository>()));
  sl.registerFactory(() => MarkAsPaidUseCase(sl<PaymentRepository>()));
  sl.registerFactory(() => GetDoctorPaymentInfoUseCase(sl<PaymentRepository>()));
  sl.registerFactory(() => SaveDoctorPaymentInfoUseCase(sl<PaymentRepository>()));
  sl.registerFactory(
    () => DoctorPaymentInfoCubit(
      getInfo: sl<GetDoctorPaymentInfoUseCase>(),
      saveInfo: sl<SaveDoctorPaymentInfoUseCase>(),
    ),
  );
  sl.registerFactory(
    () => CheckoutCubit(
      initiatePayment: sl<InitiatePaymentUseCase>(),
      confirmPayment: sl<ConfirmPaymentUseCase>(),
    ),
  );
  sl.registerFactory(
    () => PaymobWebViewCubit(
      confirmPayment: sl<ConfirmPaymentUseCase>(),
    ),
  );
  sl.registerFactory(
    () => PaymentHistoryCubit(
      getPaymentHistory: sl<GetPaymentHistoryUseCase>(),
    ),
  );
  sl.registerFactory(
    () => DoctorEarningsCubit(
      getDoctorEarnings: sl<GetDoctorEarningsUseCase>(),
    ),
  );
}
