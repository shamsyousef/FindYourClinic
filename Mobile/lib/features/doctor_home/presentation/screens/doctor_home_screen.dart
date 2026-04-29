import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../notifications/presentation/cubits/notification_badge_cubit.dart';
import '../../../notifications/presentation/cubits/notification_badge_state.dart';
import '../cubits/doctor_home_cubit.dart';
import '../cubits/doctor_home_state.dart';
import '../widgets/next_appointment_card.dart';
import '../widgets/performance_card.dart';
import '../widgets/schedule_item_card.dart';
import '../widgets/stat_card.dart';

class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({super.key});

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DoctorHomeCubit>().loadDashboard();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<DoctorHomeCubit, DoctorHomeState>(
        builder: (context, state) => switch (state) {
          DoctorHomeInitial() || DoctorHomeLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
          DoctorHomeError(:final message) => ErrorView(
              message: message,
              onRetry: () => context.read<DoctorHomeCubit>().loadDashboard(),
            ),
          DoctorHomeLoaded(:final dashboard) => RefreshIndicator(
              onRefresh: () => context.read<DoctorHomeCubit>().loadDashboard(),
              child: CustomScrollView(
                slivers: [
                  // ─── App Bar ───
                  SliverAppBar(
                    expandedHeight: 130,
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Dashboard',
                                            style: AppTextStyles.heading2
                                                .copyWith(color: Colors.white),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            DateFormat('EEEE, MMMM d')
                                                .format(DateTime.now()),
                                            style: AppTextStyles.bodyMd
                                                .copyWith(
                                                    color: Colors.white70),
                                          ),
                                        ],
                                      ),
                                    ),
                                    BlocBuilder<NotificationBadgeCubit,
                                        NotificationBadgeState>(
                                      builder: (context, badgeState) {
                                        final count = badgeState
                                                is NotificationBadgeLoaded
                                            ? badgeState.unreadCount
                                            : 0;
                                        return IconButton(
                                          onPressed: () => context
                                              .pushNamed('notifications')
                                              .then((_) {
                                            if (context.mounted) {
                                              context
                                                  .read<NotificationBadgeCubit>()
                                                  .loadUnreadCount();
                                            }
                                          }),
                                          icon: Badge(
                                            isLabelVisible: count > 0,
                                            label: Text(
                                              count > 99
                                                  ? '99+'
                                                  : count.toString(),
                                            ),
                                            child: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color:
                                                    Colors.white.withAlpha(30),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: const Icon(
                                                Icons.notifications_outlined,
                                                color: Colors.white,
                                                size: 24,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ─── Quick Stats ───
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Quick Stats', style: AppTextStyles.heading3),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: StatCard(
                                  label: 'Total',
                                  value: '${dashboard.quickStats.totalToday}',
                                  icon: Icons.people,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: StatCard(
                                  label: 'Completed',
                                  value: '${dashboard.quickStats.completed}',
                                  icon: Icons.check_circle,
                                  color: AppColors.success,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: StatCard(
                                  label: 'Pending',
                                  value: '${dashboard.quickStats.pending}',
                                  icon: Icons.schedule,
                                  color: AppColors.warning,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: StatCard(
                                  label: 'Cancelled',
                                  value: '${dashboard.quickStats.cancelled}',
                                  icon: Icons.cancel,
                                  color: AppColors.error,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ─── Next Appointment ───
                  if (dashboard.nextAppointment != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Next Appointment',
                                style: AppTextStyles.heading3),
                            const SizedBox(height: 12),
                            DoctorNextAppointmentCard(
                              appointment: dashboard.nextAppointment!,
                            ),
                          ],
                        ),
                      ),
                    ),

                  // ─── Performance Summary ───
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Performance Summary',
                              style: AppTextStyles.heading3),
                          const SizedBox(height: 12),
                          PerformanceCard(
                              performance: dashboard.performance),
                        ],
                      ),
                    ),
                  ),

                  // ─── View Insights CTA ───
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // Navigate to Insights tab (index 3 in doctor shell)
                          final shell = StatefulNavigationShell.maybeOf(context);
                          shell?.goBranch(3);
                        },
                        icon: const Icon(Icons.insights),
                        label: const Text('View Insights — Check your performance analytics'),
                      ),
                    ),
                  ),

                  // ─── Today's Schedule ───
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Today's Schedule",
                              style: AppTextStyles.heading3),
                          TextButton.icon(
                            onPressed: () => context.push('/doctor/home/availability'),
                            icon: const Icon(Icons.edit_calendar, size: 18),
                            label: const Text('Manage'),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (dashboard.todaySchedule.isEmpty)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: EmptyStateView(
                          icon: Icons.event_available,
                          title: 'No Appointments Today',
                          subtitle:
                              'Your schedule is clear for today. Enjoy your day!',
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList.separated(
                        itemCount: dashboard.todaySchedule.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          return ScheduleItemCard(
                            item: dashboard.todaySchedule[index],
                          );
                        },
                      ),
                    ),

                  const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
                ],
              ),
            ),
        },
      ),
    );
  }
}
