import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../accessibility/domain/entities/screen_context.dart';
import '../../../accessibility/presentation/cubits/voice_assistant_cubit.dart';
import '../../../accessibility/presentation/cubits/voice_assistant_visibility_cubit.dart';
import '../../../accessibility/presentation/widgets/voice_assistant_card.dart';
import '../../../notifications/presentation/cubits/notification_badge_cubit.dart';
import '../../../notifications/presentation/cubits/notification_badge_state.dart';
import '../../../home_highlights/domain/entities/tour_step.dart';
import '../../../home_highlights/presentation/cubits/home_highlights_cubit.dart';
import '../../../home_highlights/presentation/widgets/home_highlights_overlay.dart';
import '../cubits/patient_home_cubit.dart';
import '../cubits/patient_home_state.dart';
import '../widgets/greeting_header.dart';
import '../widgets/health_stats_card.dart';
import '../widgets/specialty_chip.dart';
import '../widgets/top_doctor_card.dart';
import '../widgets/upcoming_appointment_card.dart';

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  static const _screenContext = ScreenContext(screen: PatientScreen.home);

  final _headerKey = GlobalKey();
  final _specialtiesKey = GlobalKey();
  final _upcomingKey = GlobalKey();
  final _healthKey = GlobalKey();
  final _aiToolsKey = GlobalKey();
  final _topDoctorsKey = GlobalKey();

  List<TourStep> _buildSteps({required bool hasUpcoming}) {
    return [
      TourStep(
        targetKey: _headerKey,
        title: 'Welcome',
        description:
            'Your personalized greeting and notifications live here. Tap the bell anytime.',
        cutoutPadding: EdgeInsets.zero,
        cutoutRadius: 0,
      ),
      TourStep(
        targetKey: _specialtiesKey,
        title: 'Browse by Specialty',
        description:
            'Tap a specialty to quickly find the right doctor for your needs.',
      ),
      if (hasUpcoming)
        TourStep(
          targetKey: _upcomingKey,
          title: 'Next Appointment',
          description: 'A quick view of your upcoming visit.',
        ),
      TourStep(
        targetKey: _healthKey,
        title: 'Health Overview',
        description: 'Track your key health stats at a glance.',
      ),
      TourStep(
        targetKey: _aiToolsKey,
        title: 'AI Health Tools',
        description:
            'Chat with the AI assistant or check your symptoms anytime.',
      ),
      TourStep(
        targetKey: _topDoctorsKey,
        title: 'Top Doctors',
        description: 'Discover highly rated doctors near you.',
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    context.read<PatientHomeCubit>().loadDashboard();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Register screen context only — never auto-speak. The summary is read
      // out only when the user explicitly says "read this screen".
      context.read<VoiceAssistantCubit>().setScreenContext(
            _screenContext,
            summary: _buildScreenSummary,
          );
    });
  }

  @override
  void dispose() {
    // Best-effort: clear the screen context if the cubit is still alive.
    // The shell owns the cubit, so we don't close it here.
    super.dispose();
  }

  String _buildScreenSummary() {
    final state = context.read<PatientHomeCubit>().state;
    if (state is! PatientHomeLoaded) {
      return 'Home. Loading your dashboard.';
    }
    final summary = state.summary;
    final upcoming = summary.upcomingAppointment;
    final parts = <String>['Home.'];
    if (upcoming != null) {
      parts.add('Your next appointment is with Doctor ${upcoming.doctorName}.');
    } else {
      parts.add('You have no upcoming appointments.');
    }
    if (summary.topDoctors.isNotEmpty) {
      parts.add('${summary.topDoctors.length} top doctors are listed.');
    }
    parts.add(
      "Tap the microphone or say things like 'find a cardiologist', "
      "'my appointments', or 'help'.",
    );
    return parts.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<HomeHighlightsCubit>(),
      child: Scaffold(
          body: Stack(
            children: [
              BlocBuilder<PatientHomeCubit, PatientHomeState>(
                builder: (context, state) => switch (state) {
                  PatientHomeInitial() || PatientHomeLoading() => const Center(
                    child: CircularProgressIndicator(),
                  ),
            PatientHomeError(:final message) => ErrorView(
              message: message,
              onRetry: () => context.read<PatientHomeCubit>().loadDashboard(),
            ),
            PatientHomeLoaded(:final summary) => RefreshIndicator(
              onRefresh: () => context.read<PatientHomeCubit>().loadDashboard(),
              child: CustomScrollView(
                slivers: [
                  // ─── App Bar ───
                  SliverAppBar(
                    expandedHeight: 120,
                    floating: true,
                    pinned: true,
                    backgroundColor: AppColors.primary,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        key: _headerKey,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.gradientStart,
                              AppColors.gradientMiddle,
                              AppColors.gradientEnd,
                            ],
                          ),
                        ),
                        child: SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                            child:
                                BlocBuilder<
                                  NotificationBadgeCubit,
                                  NotificationBadgeState
                                >(
                                  builder: (context, badgeState) {
                                    final count =
                                        badgeState is NotificationBadgeLoaded
                                        ? badgeState.unreadCount
                                        : 0;
                                    return GreetingHeader(
                                      unreadNotificationCount: count,
                                      onNotificationTap: () => context
                                          .pushNamed('notifications')
                                          .then((_) {
                                            if (context.mounted) {
                                              context
                                                  .read<
                                                    NotificationBadgeCubit
                                                  >()
                                                  .loadUnreadCount();
                                            }
                                          }),
                                    );
                                  },
                                ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ─── Search Bar ───
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                      child: GestureDetector(
                        onTap: () => context.pushNamed('search'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? AppColors.darkSurface
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.divider),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.shadow,
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.search,
                                color: AppColors.textHint,
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Search doctors, specialties...',
                                style: AppTextStyles.bodyMd.copyWith(
                                  color: AppColors.textHint,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ─── Specialties ───
                  SliverToBoxAdapter(
                    child: Container(
                      key: _specialtiesKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                            child: Text(
                              'Specialties',
                              style: AppTextStyles.heading3,
                            ),
                          ),
                          SizedBox(
                            height: 120,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: summary.specialties.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (context, index) {
                                final s = summary.specialties[index];
                                return SpecialtyChip(
                                  name: s.name,
                                  iconUrl: s.iconUrl,
                                  onTap: () => context.pushNamed(
                                    'search',
                                    queryParameters: {'specialtyId': s.id},
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ─── Voice Assistant (Accessibility) ───
                  SliverToBoxAdapter(
                    child: BlocBuilder<VoiceAssistantVisibilityCubit, bool>(
                      builder: (_, visible) => visible
                          ? const Padding(
                              padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
                              child: VoiceAssistantCard(),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),

                  // ─── Upcoming Appointment ───
                  if (summary.upcomingAppointment != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        key: _upcomingKey,
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Upcoming Appointment',
                              style: AppTextStyles.heading3,
                            ),
                            const SizedBox(height: 12),
                            UpcomingAppointmentCard(
                              appointment: summary.upcomingAppointment!,
                            ),
                          ],
                        ),
                      ),
                    ),

                  // ─── Health Stats ───
                  SliverToBoxAdapter(
                    child: Padding(
                      key: _healthKey,
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Health Overview',
                            style: AppTextStyles.heading3,
                          ),
                          const SizedBox(height: 12),
                          HealthStatsCard(healthSummary: summary.healthSummary),
                        ],
                      ),
                    ),
                  ),

                  // ─── AI Health Tools ───
                  SliverToBoxAdapter(
                    child: Padding(
                      key: _aiToolsKey,
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Health Tools',
                            style: AppTextStyles.heading3,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _AiToolCard(
                                  title: 'AI Assistant',
                                  subtitle: 'Chat & get guidance',
                                  icon: Icons.auto_awesome,
                                  gradientColors: [
                                    AppColors.gradientStart,
                                    AppColors.gradientMiddle,
                                  ],
                                  onTap: () =>
                                      context.pushNamed(RouteNames.aiChat),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _AiToolCard(
                                  title: 'Symptom Checker',
                                  subtitle: 'Analyze symptoms',
                                  icon: Icons.medical_services_outlined,
                                  gradientColors: [
                                    AppColors.gradientMiddle,
                                    AppColors.gradientEnd,
                                  ],
                                  onTap: () => context.pushNamed(
                                    RouteNames.symptomChecker,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ─── Top Doctors ───
                  SliverToBoxAdapter(
                    child: Container(
                      key: _topDoctorsKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Top Doctors',
                                  style: AppTextStyles.heading3,
                                ),
                                TextButton(
                                  onPressed: () => context.pushNamed('search'),
                                  child: const Text('See All'),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 200,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: summary.topDoctors.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: 14),
                              itemBuilder: (context, index) {
                                final doctor = summary.topDoctors[index];
                                return TopDoctorCard(
                                  doctor: doctor,
                                  onTap: () => context.pushNamed(
                                    'doctorDetails',
                                    pathParameters: {'id': doctor.doctorId},
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ─── Nearby Clinics CTA ───
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: InkWell(
                        onTap: () => context.pushNamed('nearbyClinics'),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.gradientStart,
                                AppColors.gradientEnd,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(40),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Nearby Clinics',
                                      style: AppTextStyles.heading3.copyWith(
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Find clinics around you on the map',
                                      style: AppTextStyles.bodySm.copyWith(
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.white70,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
                ],
              ),
            ),
          },
        ),
        BlocBuilder<PatientHomeCubit, PatientHomeState>(
          builder: (context, state) {
            if (state is! PatientHomeLoaded) return const SizedBox.shrink();
            return Positioned.fill(
              child: HomeHighlightsOverlay(
                steps: _buildSteps(
                  hasUpcoming: state.summary.upcomingAppointment != null,
                ),
              ),
            );
          },
        ),
      ],
    ),
   ),
  );
 }
}

class _AiToolCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const _AiToolCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white70, fontSize: 10),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white60,
                  size: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
