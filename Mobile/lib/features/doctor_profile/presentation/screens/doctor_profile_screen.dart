import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../accessibility/domain/entities/screen_context.dart';
import '../../../accessibility/presentation/cubits/voice_assistant_cubit.dart';
import '../../../chat/domain/usecases/start_conversation_usecase.dart';
import '../../domain/entities/doctor_profile_entities.dart';
import '../cubits/doctor_profile_cubit.dart';
import '../cubits/doctor_profile_state.dart';
import '../widgets/add_review_bottom_sheet.dart';

class DoctorProfileScreen extends StatefulWidget {
  final String doctorId;
  final bool canReview;
  final bool canMessage;

  const DoctorProfileScreen({
    super.key,
    required this.doctorId,
    this.canReview = false,
    this.canMessage = false,
  });

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    context.read<DoctorProfileCubit>().loadProfile(widget.doctorId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Bare context — gets enriched with doctor data once the profile loads
      // (see _publishContextFromLoaded in build()).
      context.read<VoiceAssistantCubit>().setScreenContext(
            const ScreenContext(screen: PatientScreen.doctorProfile),
            summary: _buildScreenSummary,
          );
    });
  }

  /// Re-registers the screen context once the doctor's data is available so
  /// commands like "book appointment" can read the doctor profile id and the
  /// next available slot directly from the cubit's screen context.
  void _publishContextFromLoaded(DoctorProfileLoaded loaded) {
    final d = loaded.details;
    context.read<VoiceAssistantCubit>().setScreenContext(
      ScreenContext(
        screen: PatientScreen.doctorProfile,
        data: {
          ScreenContextKeys.doctorProfileId: d.doctorProfileId,
          ScreenContextKeys.doctorUserId: d.doctorId,
          ScreenContextKeys.doctorName: d.fullName,
          ScreenContextKeys.doctorSpecialty: d.specialty,
          ScreenContextKeys.consultationFee: d.consultationFee,
          if (d.clinicName != null) ScreenContextKeys.clinicName: d.clinicName,
          if (d.nextAvailableSlot != null)
            ScreenContextKeys.nextAvailableSlotIso:
                d.nextAvailableSlot!.toIso8601String(),
        },
      ),
      summary: _buildScreenSummary,
    );
  }

  String _buildScreenSummary() {
    final state = context.read<DoctorProfileCubit>().state;
    final loaded = switch (state) {
      DoctorProfileLoaded() => state,
      DoctorProfileReviewSuccess(:final loaded) => loaded,
      DoctorProfileReviewError(:final loaded) => loaded,
      _ => null,
    };
    if (loaded == null) return 'Doctor profile. Still loading.';
    final d = loaded.details;
    final fee = d.consultationFee.toStringAsFixed(0);
    final rating = d.avgRating > 0
        ? '${d.avgRating.toStringAsFixed(1)} stars from ${d.reviewsCount} reviews. '
        : 'No reviews yet. ';
    return 'Doctor ${d.fullName}, ${d.specialty}. '
        '$rating'
        'Consultation fee $fee. '
        "Say 'book appointment' to book, or 'go back' to return.";
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _startConversation(BuildContext ctx) async {
    final result = await sl<StartConversationUseCase>()(widget.doctorId);
    if (!ctx.mounted) return;
    switch (result) {
      case Success(:final data):
        ctx.push('/chat/${data.id}');
      case Error(:final failure):
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            backgroundColor: AppColors.error,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DoctorProfileCubit, DoctorProfileState>(
      listenWhen: (prev, curr) =>
          curr is DoctorProfileLoaded ||
          curr is DoctorProfileReviewSuccess ||
          curr is DoctorProfileReviewError,
      listener: (_, state) {
        final loaded = switch (state) {
          DoctorProfileLoaded() => state,
          DoctorProfileReviewSuccess(:final loaded) => loaded,
          DoctorProfileReviewError(:final loaded) => loaded,
          _ => null,
        };
        if (loaded != null) _publishContextFromLoaded(loaded);
      },
      builder: (context, state) {
        if (state is DoctorProfileLoading || state is DoctorProfileInitial) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is DoctorProfileError) {
          return Scaffold(
            body: ErrorView(
              message: state.message,
              onRetry: () => context
                  .read<DoctorProfileCubit>()
                  .loadProfile(widget.doctorId),
            ),
          );
        }

        final loaded = switch (state) {
          DoctorProfileLoaded() => state,
          DoctorProfileReviewSuccess(:final loaded) => loaded,
          DoctorProfileReviewError(:final loaded) => loaded,
          _ => null,
        };

        if (loaded == null) {
          return const Scaffold(
            body: Center(child: Text('Unexpected state')),
          );
        }

        final details = loaded.details;
        final reviews = loaded.reviews;
        final availability = loaded.availability;

        return Scaffold(
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              // ─── Header ───
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: AppColors.primary,
                actions: [
                  if (widget.canMessage)
                    IconButton(
                      icon: const Icon(Icons.message_outlined,
                          color: Colors.white),
                      tooltip: 'Message Doctor',
                      onPressed: () => _startConversation(context),
                    ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.gradientStart,
                          AppColors.gradientEnd,
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 16),
                          UserAvatar(
                            radius: 44,
                            imageUrl: details.profileImageUrl,
                            fullName: details.fullName,
                            backgroundColor: Colors.white.withAlpha(40),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Dr. ${details.fullName}',
                            style: AppTextStyles.heading2
                                .copyWith(color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            details.specialty,
                            style: AppTextStyles.bodyMd
                                .copyWith(color: Colors.white70),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _HeaderStat(
                                  icon: Icons.star,
                                  value: details.avgRating.toStringAsFixed(1),
                                  label: 'Rating'),
                              const SizedBox(width: 24),
                              _HeaderStat(
                                  icon: Icons.reviews,
                                  value: '${details.reviewsCount}',
                                  label: 'Reviews'),
                              const SizedBox(width: 24),
                              _HeaderStat(
                                  icon: Icons.work,
                                  value: '${details.experienceYears}',
                                  label: 'Years'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // ─── Tab Bar ───
              SliverPersistentHeader(
                pinned: true,
                delegate: _TabBarDelegate(
                  tabBar: TabBar(
                    controller: _tabController,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textHint,
                    indicatorColor: AppColors.primary,
                    tabs: const [
                      Tab(text: 'About'),
                      Tab(text: 'Schedule'),
                      Tab(text: 'Reviews'),
                      Tab(text: 'Location'),
                    ],
                  ),
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _AboutTab(details: details),
                _ScheduleTab(slots: availability),
                _ReviewsTab(
                  reviews: reviews,
                  canReview: widget.canReview,
                  doctorId: widget.doctorId,
                ),
                _LocationTab(details: details),
              ],
            ),
          ),
          // ─── Book Button ───
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: AppButton(
                text:
                    'Book Appointment — \$${details.consultationFee.toStringAsFixed(0)}',
                onPressed: () {
                  context.push('/book-appointment', extra: {
                    'doctorProfileId': details.doctorProfileId,
                    'doctorUserId': details.doctorId,
                    'doctorName': 'Dr. ${details.fullName}',
                    'specialty': details.specialty,
                    'consultationFee':
                        '\$${details.consultationFee.toStringAsFixed(0)}',
                    'clinicName': details.clinicName,
                    'doctorImageUrl': details.profileImageUrl,
                  });
                },
              ),
            ),
          ),
        );
      },
    );

  }
}

// ─── Header Stat Widget ───
class _HeaderStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _HeaderStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(height: 4),
        Text(value,
            style: AppTextStyles.label.copyWith(color: Colors.white)),
        Text(label,
            style: AppTextStyles.caption.copyWith(color: Colors.white60)),
      ],
    );
  }
}

// ─── Tab Bar Delegate ───
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _TabBarDelegate({required this.tabBar});

  @override
  Widget build(context, shrinkOffset, overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;
  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => false;
}

// ─── About Tab ───
class _AboutTab extends StatelessWidget {
  final DoctorDetails details;
  const _AboutTab({required this.details});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (details.bio != null && details.bio!.isNotEmpty) ...[
          Text('About', style: AppTextStyles.heading3),
          const SizedBox(height: 8),
          Text(details.bio!, style: AppTextStyles.bodyMd),
          const SizedBox(height: 20),
        ],
        _InfoRow(icon: Icons.local_hospital, label: 'Clinic', value: details.clinicName ?? 'N/A'),
        _InfoRow(icon: Icons.location_on, label: 'Address', value: details.clinicAddress ?? 'N/A'),
        _InfoRow(icon: Icons.attach_money, label: 'Consultation Fee', value: '\$${details.consultationFee.toStringAsFixed(0)}'),
        _InfoRow(icon: Icons.work_outline, label: 'Experience', value: '${details.experienceYears} years'),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textHint)),
              Text(value, style: AppTextStyles.label),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Schedule Tab ───
class _ScheduleTab extends StatelessWidget {
  final List<AvailabilitySlot> slots;
  const _ScheduleTab({required this.slots});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    const daysOfWeek = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: daysOfWeek.length,
      separatorBuilder: (context, i) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final day = daysOfWeek[index];
        final daySlots = slots.where((s) => s.dayOfWeek == day).toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));

        final hasSlots = daySlots.isNotEmpty;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: hasSlots
                ? theme.colorScheme.primary.withAlpha(isDark ? 25 : 10)
                : (isDark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasSlots
                  ? theme.colorScheme.primary.withAlpha(isDark ? 60 : 40)
                  : (isDark ? AppColors.darkSurfaceAlt : AppColors.divider),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 90,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: hasSlots
                      ? theme.colorScheme.primary.withAlpha(isDark ? 40 : 20)
                      : (isDark ? AppColors.darkSurface : AppColors.divider.withAlpha(50)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  day,
                  style: AppTextStyles.labelSm.copyWith(
                    color: hasSlots
                        ? theme.colorScheme.primary
                        : (isDark ? AppColors.darkTextSecondary : AppColors.textHint),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 14),
              if (hasSlots) ...[
                Icon(Icons.access_time,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textHint,
                    size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: daySlots.map((slot) {
                      return Text(
                        '${slot.startTime} - ${slot.endTime}',
                        style: AppTextStyles.bodyMd.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ] else ...[
                Icon(Icons.block,
                    color: (isDark ? AppColors.darkTextSecondary : AppColors.textHint).withAlpha(150),
                    size: 16),
                const SizedBox(width: 6),
                Text(
                  'Not Available',
                  style: AppTextStyles.bodyMd.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textHint,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ─── Reviews Tab ───
class _ReviewsTab extends StatelessWidget {
  final List<DoctorReview> reviews;
  final bool canReview;
  final String doctorId;

  const _ReviewsTab({
    required this.reviews,
    required this.canReview,
    required this.doctorId,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (canReview) ...[
          OutlinedButton.icon(
            icon: const Icon(Icons.star_outline),
            label: const Text('Write a Review'),
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => BlocProvider.value(
                value: context.read<DoctorProfileCubit>(),
                child: AddReviewBottomSheet(doctorId: doctorId),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (reviews.isEmpty)
          const SizedBox(
            height: 200,
            child: EmptyStateView(
              icon: Icons.rate_review,
              title: 'No Reviews Yet',
              subtitle: 'Be the first to review this doctor.',
            ),
          )
        else
          for (int i = 0; i < reviews.length; i++) ...[
            if (i > 0) const Divider(height: 24),
            _ReviewItem(review: reviews[i]),
          ],
      ],
    );
  }
}

class _ReviewItem extends StatelessWidget {
  final DoctorReview review;
  const _ReviewItem({required this.review});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            UserAvatar(
              radius: 18,
              imageUrl: review.patientImageUrl,
              fullName: review.patientName,
              backgroundColor: AppColors.primary.withAlpha(20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(review.patientName, style: AppTextStyles.label),
                  Text(
                    DateFormat('MMM d, yyyy').format(review.createdAt),
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textHint),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                5,
                (i) => Icon(
                  i < review.rating ? Icons.star : Icons.star_border,
                  color: AppColors.starRating,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
        if (review.comment != null && review.comment!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(review.comment!, style: AppTextStyles.bodyMd),
        ],
      ],
    );
  }
}

// ─── Location Tab ───
class _LocationTab extends StatelessWidget {
  final DoctorDetails details;
  const _LocationTab({required this.details});

  @override
  Widget build(BuildContext context) {
    if (details.latitude == null || details.longitude == null) {
      return const EmptyStateView(
        icon: Icons.location_off,
        title: 'Location Not Available',
        subtitle: 'This clinic has not set up their location yet.',
      );
    }

    final clinicLatLng = LatLng(details.latitude!, details.longitude!);

    return Column(
      children: [
        Expanded(
          child: FlutterMap(
            options: MapOptions(
              initialCenter: clinicLatLng,
              initialZoom: 15,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.findyourclinic.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: clinicLatLng,
                    width: 50,
                    height: 50,
                    child: const Icon(Icons.location_on,
                        color: AppColors.error, size: 40),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(details.clinicName ?? 'Clinic', style: AppTextStyles.heading3),
              const SizedBox(height: 4),
              Text(
                details.clinicAddress ?? 'Address not available',
                style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
