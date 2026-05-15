import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../di/service_locator.dart';
import '../utils/token_storage.dart';
import '../../features/accessibility/domain/entities/voice_command_intent.dart';
import '../../features/accessibility/presentation/cubits/voice_assistant_cubit.dart';
import '../../features/accessibility/presentation/cubits/voice_assistant_visibility_cubit.dart';
import '../../features/accessibility/presentation/widgets/voice_assistant_fab.dart';
import '../../features/auth/presentation/cubits/auth_cubit.dart';
import '../../features/auth/presentation/cubits/specialty_cubit.dart';
import '../../features/auth/presentation/screens/doctor_rejected_screen.dart';
import '../../features/auth/presentation/screens/change_password_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/doctor_onboarding/presentation/cubits/onboarding_cubit.dart';
import '../../features/doctor_onboarding/presentation/screens/doctor_document_upload_screen.dart';
import '../../features/doctor_onboarding/presentation/screens/doctor_pending_screen.dart';

// Phase 4 imports
import '../../features/patient_home/presentation/cubits/patient_home_cubit.dart';
import '../../features/patient_home/presentation/screens/patient_home_screen.dart';
import '../../features/doctor_home/presentation/cubits/doctor_home_cubit.dart';
import '../../features/doctor_home/presentation/screens/doctor_home_screen.dart';
import '../../features/search/presentation/cubits/search_cubit.dart';
import '../../features/search/presentation/screens/search_screen.dart';
import '../../features/doctor_home/presentation/cubits/insights_cubit.dart';
import '../../features/doctor_home/presentation/screens/doctor_insights_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/help_support/presentation/screens/help_support_screen.dart';
import '../../features/doctor_profile/presentation/cubits/doctor_profile_cubit.dart';
import '../../features/doctor_profile/presentation/cubits/edit_doctor_profile_cubit.dart';
import '../../features/doctor_profile/presentation/screens/doctor_profile_screen.dart';
import '../../features/doctor_profile/presentation/screens/doctor_edit_profile_screen.dart';
import '../../features/doctor_profile/presentation/screens/doctor_shell_profile_screen.dart';
import '../../features/doctor_profile/presentation/cubits/doctor_shell_profile_cubit.dart';
import '../../features/nearby_clinics/presentation/cubits/nearby_clinics_cubit.dart';
import '../../features/nearby_clinics/presentation/screens/nearby_clinics_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../features/notifications/domain/usecases/notification_usecases.dart';
import '../../features/notifications/presentation/cubits/notification_badge_cubit.dart';
import '../../features/notifications/presentation/cubits/notifications_cubit.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/chat/presentation/cubit/conversations_cubit.dart';
import '../../features/chat/presentation/cubit/conversations_state.dart';
import '../../features/chat/presentation/screens/conversations_screen.dart';
import '../../features/chat/presentation/screens/chat_screen.dart';
import '../../features/appointments/presentation/cubits/appointment_cubit.dart';
import '../../features/appointments/presentation/screens/patient_appointments_screen.dart';
import '../../features/appointments/presentation/screens/doctor_appointments_screen.dart';
import '../../features/appointments/presentation/screens/appointment_detail_screen.dart';
import '../../features/appointments/presentation/cubits/booking_cubit.dart';
import '../../features/appointments/presentation/screens/book_appointment_screen.dart';
import '../../features/doctor_availability/presentation/cubits/manage_availability_cubit.dart';
import '../../features/doctor_availability/presentation/screens/manage_availability_screen.dart';
import '../../features/patient_profile/presentation/cubits/patient_profile_cubit.dart';
import '../../features/patient_profile/presentation/screens/patient_profile_screen.dart';
import '../../features/patient_profile/presentation/screens/edit_patient_profile_screen.dart';
import '../../features/health_records/domain/entities/health_record_entity.dart';
import '../../features/health_records/presentation/cubits/health_record_cubit.dart';
import '../../features/health_records/presentation/screens/health_records_screen.dart';
import '../../features/health_records/presentation/screens/health_record_detail_screen.dart';
import '../../features/health_records/presentation/screens/add_health_record_screen.dart';

// AI Health
import '../../features/ai_health/domain/entities/symptom_analysis.dart';
import '../../features/ai_health/presentation/cubits/ai_chat_cubit.dart';
import '../../features/ai_health/presentation/cubits/symptom_checker_cubit.dart';
import '../../features/ai_health/presentation/screens/ai_chat_screen.dart';
import '../../features/ai_health/presentation/screens/symptom_checker_screen.dart';
import '../../features/ai_health/presentation/screens/symptom_result_screen.dart';

// Payment
import '../../features/payment/domain/entities/payment_entities.dart' as pay_entities;
import '../../features/payment/presentation/screens/checkout_screen.dart';
import '../../features/payment/presentation/screens/doctor_earnings_screen.dart';
import '../../features/payment/presentation/screens/doctor_payment_info_screen.dart';
import '../../features/payment/presentation/screens/doctor_transaction_history_screen.dart';
import '../../features/payment/presentation/cubits/doctor_earnings_cubit.dart';
import '../../features/payment/presentation/screens/patient_payment_methods_screen.dart';
import '../../features/payment/presentation/screens/patient_transaction_history_screen.dart';
import '../../features/payment/presentation/screens/receipt_detail_screen.dart';

// Booking Success
import '../../features/appointments/presentation/screens/booking_success_screen.dart';

part 'route_names.dart';

/// Main app router with auth redirect and role-based shell navigation.
class AppRouter {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final TokenStorage _tokenStorage;

  AppRouter() : _tokenStorage = sl<TokenStorage>();

  late final GoRouter router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    redirect: _globalRedirect,
    routes: [
      // ─── Splash ───
      GoRoute(
        path: '/splash',
        name: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      // ─── Onboarding ───
      GoRoute(
        path: '/onboarding',
        name: RouteNames.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),

      // ─── Auth Routes ───
      GoRoute(
        path: '/login',
        name: RouteNames.login,
        builder: (context, state) => BlocProvider(
          create: (_) => sl<AuthCubit>(),
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: '/signup',
        name: RouteNames.signUp,
        builder: (context, state) => MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => sl<AuthCubit>()),
            BlocProvider(
              create: (_) => sl<SpecialtyCubit>()..loadSpecialties(),
            ),
          ],
          child: const SignUpScreen(),
        ),
      ),
      GoRoute(
        path: '/forgot-password',
        name: RouteNames.forgotPassword,
        builder: (context, state) => BlocProvider(
          create: (_) => sl<AuthCubit>(),
          child: const ForgotPasswordScreen(),
        ),
      ),
      GoRoute(
        path: '/otp',
        name: RouteNames.otp,
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'OTP Verification'),
      ),
      GoRoute(
        path: '/reset-password',
        name: RouteNames.resetPassword,
        builder: (context, state) {
          final token = state.uri.queryParameters['token'] ?? '';
          return BlocProvider(
            create: (_) => sl<AuthCubit>(),
            child: ResetPasswordScreen(token: token),
          );
        },
      ),

      // ─── Doctor Onboarding ───
      GoRoute(
        path: '/doctor-documents',
        name: RouteNames.doctorDocuments,
        builder: (context, state) {
          final token = state.extra as String? ?? '';
          final isResubmission =
              state.uri.queryParameters['resubmit'] == 'true';
          return BlocProvider(
            create: (_) => sl<OnboardingCubit>(),
            child: DoctorDocumentUploadScreen(
              pendingToken: token,
              isResubmission: isResubmission,
            ),
          );
        },
      ),
      GoRoute(
        path: '/doctor-pending',
        name: RouteNames.doctorPending,
        builder: (context, state) => const DoctorPendingScreen(),
      ),
      GoRoute(
        path: '/doctor-rejected',
        name: RouteNames.doctorRejected,
        builder: (context, state) => DoctorRejectedScreen(
          rejectionReason: state.extra as String?,
        ),
      ),

      // ─── Discovery Routes (outside shells) ───
      GoRoute(
        path: '/search',
        name: RouteNames.search,
        builder: (context, state) {
          final specialtyId = state.uri.queryParameters['specialtyId'];
          final specialtyName = state.uri.queryParameters['specialtyName'];
          return MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => sl<SearchCubit>()),
              BlocProvider<VoiceAssistantCubit>.value(
                value: sl<VoiceAssistantCubit>(),
              ),
            ],
            child: SearchScreen(
              initialSpecialtyId: specialtyId,
              initialSpecialtyName: specialtyName,
            ),
          );
        },
      ),
      GoRoute(
        path: '/doctor-details/:id',
        name: RouteNames.doctorDetails,
        builder: (context, state) {
          final doctorId = state.pathParameters['id']!;
          final extra = state.extra as Map<String, dynamic>?;
          final canReview = extra?['canReview'] as bool? ?? false;
          final canMessage = extra?['canMessage'] as bool? ?? false;
          return MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => sl<DoctorProfileCubit>()),
              BlocProvider<VoiceAssistantCubit>.value(
                value: sl<VoiceAssistantCubit>(),
              ),
            ],
            child: DoctorProfileScreen(
              doctorId: doctorId,
              canReview: canReview,
              canMessage: canMessage,
            ),
          );
        },
      ),
      GoRoute(
        path: '/nearby-clinics',
        name: RouteNames.nearbyClinics,
        builder: (context, state) => BlocProvider(
          create: (_) => sl<NearbyClinicsCubit>(),
          child: const NearbyClinicsScreen(),
        ),
      ),
      GoRoute(
        path: '/notifications',
        name: RouteNames.notifications,
        builder: (context, state) => BlocProvider(
          create: (_) => sl<NotificationsCubit>(),
          child: const NotificationsScreen(),
        ),
      ),

      // ─── Chat Detail ───
      GoRoute(
        path: '/chat/:conversationId',
        name: RouteNames.chatDetail,
        builder: (context, state) {
          final conversationId = state.pathParameters['conversationId']!;
          final extra = state.extra as Map<String, dynamic>?;
          return ChatScreen(
            conversationId: conversationId,
            otherPartyName: extra?['otherPartyName'] as String?,
            otherPartyImageUrl: extra?['otherPartyImageUrl'] as String?,
            otherPartyUserId: extra?['otherPartyUserId'] as String?,
          );
        },
      ),

      // ─── Doctor Availability ───
      GoRoute(
        path: '/doctor/home/availability',
        name: RouteNames.manageAvailability,
        builder: (context, state) => BlocProvider(
          create: (_) => sl<ManageAvailabilityCubit>(),
          child: const ManageAvailabilityScreen(),
        ),
      ),
      GoRoute(
        path: '/doctor/profile/documents',
        name: RouteNames.doctorProfileDocuments,
        builder: (context, state) => BlocProvider(
          create: (_) => sl<OnboardingCubit>(),
          child: const DoctorDocumentUploadScreen(pendingToken: ''),
        ),
      ),

      // ─── Appointment Detail ───
      GoRoute(
        path: '/appointment/:id',
        name: RouteNames.appointmentDetail,
        builder: (context, state) {
          final appointmentId = state.pathParameters['id']!;
          final isDoctorView = state.uri.queryParameters['doctor'] == 'true';
          return BlocProvider(
            create: (_) => sl<AppointmentCubit>(),
            child: AppointmentDetailScreen(
              appointmentId: appointmentId,
              isDoctorView: isDoctorView,
            ),
          );
        },
      ),

      // ─── Health Record — Add / Edit ───
      GoRoute(
        path: '/health-record/new',
        name: RouteNames.addHealthRecord,
        builder: (context, state) {
          final existing = state.extra as HealthRecordEntity?;
          return BlocProvider(
            create: (_) => sl<HealthRecordCubit>(),
            child: AddHealthRecordScreen(existingRecord: existing),
          );
        },
      ),

      // ─── Health Record — Detail ───
      GoRoute(
        path: '/health-record/:id',
        name: RouteNames.healthRecordDetail,
        builder: (context, state) {
          final recordId = state.pathParameters['id']!;
          return BlocProvider(
            create: (_) => sl<HealthRecordCubit>()..loadRecordDetail(recordId),
            child: HealthRecordDetailScreen(recordId: recordId),
          );
        },
      ),

      // ─── Settings ───
      GoRoute(
        path: '/settings',
        name: RouteNames.settings,
        builder: (context, state) => const SettingsScreen(),
      ),

      // ─── Change Password (authenticated, not an auth page) ───
      GoRoute(
        path: '/change-password',
        name: RouteNames.changePassword,
        builder: (context, state) => BlocProvider(
          create: (_) => sl<AuthCubit>(),
          child: const ChangePasswordScreen(),
        ),
      ),

      // ─── Help & Support ───
      GoRoute(
        path: '/help-support',
        name: RouteNames.helpSupport,
        builder: (context, state) => const HelpSupportScreen(),
      ),

      // ─── Book Appointment ───
      GoRoute(
        path: '/book-appointment',
        name: RouteNames.bookAppointment,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return BlocProvider(
            create: (_) => sl<BookingCubit>(),
            child: BookAppointmentScreen(
              doctorProfileId: extra['doctorProfileId'] as String,
              doctorUserId: extra['doctorUserId'] as String,
              doctorName: extra['doctorName'] as String,
              specialty: extra['specialty'] as String,
              consultationFee: extra['consultationFee'] as String?,
              clinicName: extra['clinicName'] as String?,
              doctorImageUrl: extra['doctorImageUrl'] as String?,
            ),
          );
        },
      ),

      // ─── Checkout (Payment) ───
      GoRoute(
        path: '/checkout',
        name: RouteNames.checkout,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return CheckoutScreen(
            doctorProfileId: extra['doctorProfileId'] as String,
            doctorName: extra['doctorName'] as String,
            doctorImageUrl: extra['doctorImageUrl'] as String?,
            specialty: extra['specialty'] as String?,
            consultationFee: extra['consultationFee'] as double,
            scheduledAt: extra['scheduledAt'] as DateTime,
            locationName: extra['locationName'] as String?,
          );
        },
      ),

      // ─── Payments — Patient ───
      GoRoute(
        path: '/patient/payments/methods',
        name: RouteNames.patientPaymentMethods,
        builder: (context, state) => const PatientPaymentMethodsScreen(),
      ),
      GoRoute(
        path: '/patient/payments/history',
        name: RouteNames.patientTransactionHistory,
        builder: (context, state) => const PatientTransactionHistoryScreen(),
      ),
      GoRoute(
        path: '/patient/payments/receipt',
        name: RouteNames.patientReceipt,
        builder: (context, state) {
          final tx = state.extra as pay_entities.TransactionEntity;
          return ReceiptDetailScreen(transaction: tx, isPatient: true);
        },
      ),

      // ─── Booking Success ───
      GoRoute(
        path: '/booking-success',
        name: RouteNames.bookingSuccess,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return BookingSuccessScreen(
            isConfirmed: extra['isConfirmed'] as bool,
            doctorName: extra['doctorName'] as String,
            scheduledAt: extra['scheduledAt'] as DateTime,
            appointmentId: extra['appointmentId'] as String?,
          );
        },
      ),

      // ─── Payments — Doctor ───
      GoRoute(
        path: '/doctor/earnings',
        name: RouteNames.doctorEarnings,
        builder: (context, state) => const DoctorEarningsScreen(),
      ),
      GoRoute(
        path: '/doctor/payment-info',
        name: RouteNames.doctorPaymentInfo,
        builder: (context, state) => const DoctorPaymentInfoScreen(),
      ),
      GoRoute(
        path: '/doctor/payments/history',
        name: RouteNames.doctorTransactionHistory,
        builder: (context, state) => const DoctorTransactionHistoryScreen(),
      ),
      GoRoute(
        path: '/doctor/payments/receipt',
        name: RouteNames.doctorReceipt,
        builder: (context, state) {
          final tx = state.extra as pay_entities.TransactionEntity;
          return ReceiptDetailScreen(transaction: tx, isPatient: false);
        },
      ),

      // ─── AI Health ───
      GoRoute(
        path: '/patient/ai-chat',
        name: RouteNames.aiChat,
        builder: (context, state) => BlocProvider(
          create: (_) => sl<AiChatCubit>()..loadHistory(),
          child: const AiChatScreen(),
        ),
      ),
      GoRoute(
        path: '/patient/symptom-checker',
        name: RouteNames.symptomChecker,
        builder: (context, state) => BlocProvider(
          create: (_) => sl<SymptomCheckerCubit>(),
          child: const SymptomCheckerScreen(),
        ),
      ),
      GoRoute(
        path: '/patient/symptom-result',
        name: RouteNames.symptomResult,
        builder: (context, state) {
          final analysis = state.extra as SymptomAnalysis;
          return SymptomResultScreen(analysis: analysis);
        },
      ),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => _PatientShell(
          navigationShell: navigationShell,
        ),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/patient/home',
              name: RouteNames.patientHome,
              builder: (context, state) => BlocProvider(
                create: (_) => sl<PatientHomeCubit>(),
                child: const PatientHomeScreen(),
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/patient/appointments',
              name: RouteNames.patientAppointments,
              builder: (context, state) => BlocProvider(
                create: (_) => sl<AppointmentCubit>()..loadPatientAppointments(),
                child: const PatientAppointmentsScreen(),
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/patient/messages',
              name: RouteNames.patientMessages,
              builder: (context, state) => const ConversationsScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/patient/records',
              name: RouteNames.patientRecords,
              builder: (context, state) => BlocProvider(
                create: (_) => sl<HealthRecordCubit>()..loadRecords(),
                child: const HealthRecordsScreen(),
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/patient/profile',
              name: RouteNames.patientProfile,
              builder: (context, state) => BlocProvider(
                create: (_) =>
                    sl<PatientProfileCubit>()..loadProfile(),
                child: const PatientProfileScreen(),
              ),
              routes: [
                GoRoute(
                  path: 'edit',
                  name: RouteNames.patientProfileEdit,
                  builder: (context, state) => BlocProvider(
                    create: (_) => sl<PatientProfileCubit>()..loadProfile(),
                    child: const EditPatientProfileScreen(),
                  ),
                ),
              ],
            ),
          ]),
        ],
      ),

      // ─── Doctor Shell ───
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => _DoctorShell(
          navigationShell: navigationShell,
        ),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/doctor/home',
              name: RouteNames.doctorHome,
              builder: (context, state) => BlocProvider(
                create: (_) => sl<DoctorHomeCubit>(),
                child: const DoctorHomeScreen(),
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/doctor/appointments',
              name: RouteNames.doctorAppointments,
              builder: (context, state) => BlocProvider(
                create: (_) => sl<AppointmentCubit>()..loadDoctorAppointments(),
                child: const DoctorAppointmentsScreen(),
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/doctor/chat',
              name: RouteNames.doctorChat,
              builder: (context, state) => const ConversationsScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/doctor/insights',
              name: RouteNames.doctorInsights,
              builder: (context, state) => MultiBlocProvider(
                providers: [
                  BlocProvider(
                    create: (_) => sl<InsightsCubit>()..loadInsights(),
                  ),
                  BlocProvider(
                    create: (_) => sl<DoctorEarningsCubit>()..load(),
                  ),
                ],
                child: const DoctorInsightsScreen(),
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/doctor/profile',
              name: RouteNames.doctorProfile,
              pageBuilder: (context, state) => NoTransitionPage(
                child: BlocProvider(
                  create: (_) =>
                      sl<DoctorShellProfileCubit>()..loadProfile(),
                  child: const DoctorShellProfileScreen(),
                ),
              ),
              routes: [
                GoRoute(
                  path: 'edit',
                  name: RouteNames.doctorProfileEdit,
                  builder: (context, state) => BlocProvider(
                    create: (_) => sl<EditDoctorProfileCubit>(),
                    child: const DoctorEditProfileScreen(),
                  ),
                ),
              ],
            ),
          ]),
        ],
      ),
    ],
  );

  /// Global redirect — checks auth state and role.
  Future<String?> _globalRedirect(
    BuildContext context,
    GoRouterState state,
  ) async {
    final isLoggedIn = await _tokenStorage.hasTokens();
    final currentPath = state.uri.path;

    final authPaths = [
      '/login', '/signup', '/forgot-password', '/otp', '/reset-password',
      '/doctor-documents', '/doctor-pending', '/doctor-rejected', '/onboarding',
    ];
    final isOnAuthPage = authPaths.contains(currentPath);

    if (!isLoggedIn && !isOnAuthPage && currentPath != '/splash') {
      return '/login';
    }

    if (isLoggedIn && isOnAuthPage) {
      final role = await _tokenStorage.getUserRole();
      return role == 'Doctor' ? '/doctor/home' : '/patient/home';
    }

    return null;
  }
}

// ─── Patient Shell with Bottom Nav ───
class _PatientShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  const _PatientShell({required this.navigationShell});

  @override
  State<_PatientShell> createState() => _PatientShellState();
}

class _PatientShellState extends State<_PatientShell> {
  DateTime? _lastPressedAt;
  late final ConversationsCubit _conversationsCubit;
  late final NotificationBadgeCubit _notificationBadgeCubit;
  late final VoiceAssistantCubit _voiceAssistantCubit;
  late final VoiceAssistantVisibilityCubit _voiceVisibilityCubit;

  @override
  void initState() {
    super.initState();
    _conversationsCubit = sl<ConversationsCubit>()..loadConversations();
    _notificationBadgeCubit = sl<NotificationBadgeCubit>()..loadUnreadCount();
    _voiceVisibilityCubit = sl<VoiceAssistantVisibilityCubit>();
    _voiceAssistantCubit = sl<VoiceAssistantCubit>()
      ..attachNavigationHandler(_handleVoiceIntent);
    _registerFcmToken();
  }

  /// Side-effects only (navigation). TTS is owned by the cubit, which has
  /// already spoken Gemini's `spokenResponse` before calling us — so this
  /// method must NOT speak again or we get double-speech.
  Future<void> _handleVoiceIntent(VoiceCommandIntent intent) async {
    if (!mounted) return;
    switch (intent) {
      case NavigateHomeIntent():
        widget.navigationShell.goBranch(0);
      case NavigateAppointmentsIntent():
        widget.navigationShell.goBranch(1);
      case NavigateHealthRecordsIntent():
        widget.navigationShell.goBranch(3);
      case NavigateProfileIntent():
        widget.navigationShell.goBranch(4);
      case NavigateSearchIntent(:final query):
        if (query != null && query.trim().isNotEmpty) {
          context.pushNamed(
            'search',
            queryParameters: {'specialtyName': query.trim()},
          );
        } else {
          context.pushNamed('search');
        }
      case NavigateNearbyClinicsIntent():
        context.pushNamed('nearbyClinics');
      case NavigateAiChatIntent():
        context.pushNamed('aiChat');
      case NavigateNotificationsIntent():
        context.pushNamed('notifications');
      case BookAppointmentIntent():
        // Cubit already spoke Gemini's confirmation; just navigate.
        context.pushNamed('search');
      case GoBackIntent():
        if (context.canPop()) context.pop();
      default:
        // ReadScreen / SelectItem / ReadNextAppointment / Help / Cancel /
        // Unknown are fully handled inside VoiceAssistantCubit (TTS only).
        break;
    }
  }

  Future<void> _registerFcmToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await sl<RegisterDeviceTokenUseCase>()(token);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _conversationsCubit.close();
    // _notificationBadgeCubit, _voiceVisibilityCubit and _voiceAssistantCubit
    // are lazy singletons shared across screens — not closed here.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _conversationsCubit),
        BlocProvider.value(value: _notificationBadgeCubit),
        BlocProvider<VoiceAssistantCubit>.value(value: _voiceAssistantCubit),
        BlocProvider<VoiceAssistantVisibilityCubit>.value(
          value: _voiceVisibilityCubit,
        ),
      ],
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          if (widget.navigationShell.currentIndex != 0) {
            widget.navigationShell.goBranch(0);
            return;
          }
          final now = DateTime.now();
          if (_lastPressedAt == null ||
              now.difference(_lastPressedAt!) > const Duration(seconds: 2)) {
            _lastPressedAt = now;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Press back again to exit'),
                duration: Duration(seconds: 2),
              ),
            );
            return;
          }
          SystemNavigator.pop();
        },
        child: Scaffold(
          body: widget.navigationShell,
          floatingActionButton: const VoiceAssistantFab(),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          bottomNavigationBar: BlocBuilder<ConversationsCubit, ConversationsState>(
            builder: (context, state) {
              int unreadCount = 0;
              if (state is ConversationsLoaded) {
                unreadCount = state.conversations.fold<int>(0, (sum, conv) => sum + conv.unreadCount);
              }
              return BottomNavigationBar(
                currentIndex: widget.navigationShell.currentIndex,
                onTap: (index) => widget.navigationShell.goBranch(
                  index,
                  initialLocation: index == widget.navigationShell.currentIndex,
                ),
                items: [
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.home_outlined),
                    activeIcon: Icon(Icons.home),
                    label: 'Home',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.calendar_today_outlined),
                    activeIcon: Icon(Icons.calendar_today),
                    label: 'Appointments',
                  ),
                  BottomNavigationBarItem(
                    icon: Badge(
                      isLabelVisible: unreadCount > 0,
                      label: Text(unreadCount.toString()),
                      child: const Icon(Icons.chat_bubble_outline),
                    ),
                    activeIcon: Badge(
                      isLabelVisible: unreadCount > 0,
                      label: Text(unreadCount.toString()),
                      child: const Icon(Icons.chat_bubble),
                    ),
                    label: 'Messages',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.description_outlined),
                    activeIcon: Icon(Icons.description),
                    label: 'Records',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.person_outline),
                    activeIcon: Icon(Icons.person),
                    label: 'Profile',
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─── Doctor Shell with Bottom Nav ───
class _DoctorShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  const _DoctorShell({required this.navigationShell});

  @override
  State<_DoctorShell> createState() => _DoctorShellState();
}

class _DoctorShellState extends State<_DoctorShell> {
  DateTime? _lastPressedAt;
  late final ConversationsCubit _conversationsCubit;
  late final NotificationBadgeCubit _notificationBadgeCubit;

  @override
  void initState() {
    super.initState();
    _conversationsCubit = sl<ConversationsCubit>()..loadConversations();
    _notificationBadgeCubit = sl<NotificationBadgeCubit>()..loadUnreadCount();
    _registerFcmToken();
  }

  Future<void> _registerFcmToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await sl<RegisterDeviceTokenUseCase>()(token);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _conversationsCubit.close();
    // _notificationBadgeCubit is a lazy singleton — not closed here
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _conversationsCubit),
        BlocProvider.value(value: _notificationBadgeCubit),
      ],
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          if (widget.navigationShell.currentIndex != 0) {
            widget.navigationShell.goBranch(0);
            return;
          }
          final now = DateTime.now();
          if (_lastPressedAt == null ||
              now.difference(_lastPressedAt!) > const Duration(seconds: 2)) {
            _lastPressedAt = now;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Press back again to exit'),
                duration: Duration(seconds: 2),
              ),
            );
            return;
          }
          SystemNavigator.pop();
        },
        child: Scaffold(
          body: widget.navigationShell,
          bottomNavigationBar: BlocBuilder<ConversationsCubit, ConversationsState>(
            builder: (context, state) {
              int unreadCount = 0;
              if (state is ConversationsLoaded) {
                unreadCount = state.conversations.fold<int>(0, (sum, conv) => sum + conv.unreadCount);
              }
              return BottomNavigationBar(
                currentIndex: widget.navigationShell.currentIndex,
                onTap: (index) => widget.navigationShell.goBranch(
                  index,
                  initialLocation: index == widget.navigationShell.currentIndex,
                ),
                items: [
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.home_outlined),
                    activeIcon: Icon(Icons.home),
                    label: 'Home',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.calendar_today_outlined),
                    activeIcon: Icon(Icons.calendar_today),
                    label: 'Appointments',
                  ),
                  BottomNavigationBarItem(
                    icon: Badge(
                      isLabelVisible: unreadCount > 0,
                      label: Text(unreadCount.toString()),
                      child: const Icon(Icons.chat_bubble_outline),
                    ),
                    activeIcon: Badge(
                      isLabelVisible: unreadCount > 0,
                      label: Text(unreadCount.toString()),
                      child: const Icon(Icons.chat_bubble),
                    ),
                    label: 'Chat',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.insights_outlined),
                    activeIcon: Icon(Icons.insights),
                    label: 'Insights',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.person_outline),
                    activeIcon: Icon(Icons.person),
                    label: 'Profile',
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─── Temporary placeholder screen ───
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await sl<AuthCubit>().logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Coming soon!',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
