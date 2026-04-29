import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../notifications/presentation/cubits/notification_badge_cubit.dart';
import '../../../notifications/presentation/cubits/notification_badge_state.dart';
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
  @override
  void initState() {
    super.initState();
    context.read<PatientHomeCubit>().loadDashboard();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<PatientHomeCubit, PatientHomeState>(
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
                            child: BlocBuilder<NotificationBadgeCubit,
                                NotificationBadgeState>(
                              builder: (context, badgeState) {
                                final count = badgeState
                                        is NotificationBadgeLoaded
                                    ? badgeState.unreadCount
                                    : 0;
                                return GreetingHeader(
                                  unreadNotificationCount: count,
                                  onNotificationTap: () => context
                                      .pushNamed('notifications')
                                      .then((_) {
                                    if (context.mounted) {
                                      context
                                          .read<NotificationBadgeCubit>()
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
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness ==
                                    Brightness.dark
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
                              Icon(Icons.search,
                                  color: AppColors.textHint, size: 22),
                              const SizedBox(width: 12),
                              Text(
                                'Search doctors, specialties...',
                                style: AppTextStyles.bodyMd
                                    .copyWith(color: AppColors.textHint),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ─── Specialties ───
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                      child: Text('Specialties', style: AppTextStyles.heading3),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 100,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: summary.specialties.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final s = summary.specialties[index];
                          return SpecialtyChip(
                            name: s.name,
                            iconUrl: s.iconUrl,
                            onTap: () => context.pushNamed('search',
                                queryParameters: {'specialtyId': s.id}),
                          );
                        },
                      ),
                    ),
                  ),

                  // ─── Upcoming Appointment ───
                  if (summary.upcomingAppointment != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Upcoming Appointment',
                                style: AppTextStyles.heading3),
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
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Health Overview',
                              style: AppTextStyles.heading3),
                          const SizedBox(height: 12),
                          HealthStatsCard(
                              healthSummary: summary.healthSummary),
                        ],
                      ),
                    ),
                  ),

                  // ─── Top Doctors ───
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Top Doctors', style: AppTextStyles.heading3),
                          TextButton(
                            onPressed: () => context.pushNamed('search'),
                            child: const Text('See All'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 200,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: summary.topDoctors.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 14),
                        itemBuilder: (context, index) {
                          final doctor = summary.topDoctors[index];
                          return TopDoctorCard(
                            doctor: doctor,
                            onTap: () => context.pushNamed('doctorDetails',
                                pathParameters: {'id': doctor.doctorId}),
                          );
                        },
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
                                child: const Icon(Icons.location_on,
                                    color: Colors.white, size: 28),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Nearby Clinics',
                                      style: AppTextStyles.heading3
                                          .copyWith(color: Colors.white),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Find clinics around you on the map',
                                      style: AppTextStyles.bodySm
                                          .copyWith(color: Colors.white70),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios,
                                  color: Colors.white70, size: 18),
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
    );
  }
}
