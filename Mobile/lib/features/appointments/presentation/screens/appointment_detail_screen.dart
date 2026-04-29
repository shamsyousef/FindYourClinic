import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/appointment_entity.dart';
import '../cubits/appointment_cubit.dart';
import '../cubits/appointment_state.dart';
import '../widgets/cancel_appointment_sheet.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/di/service_locator.dart';
import '../../../chat/domain/usecases/start_conversation_usecase.dart';

/// Appointment detail screen — shows full appointment info
/// with role-based actions and today's alert banner.
class AppointmentDetailScreen extends StatefulWidget {
  final String appointmentId;
  final bool isDoctorView;

  const AppointmentDetailScreen({
    super.key,
    required this.appointmentId,
    this.isDoctorView = false,
  });

  @override
  State<AppointmentDetailScreen> createState() =>
      _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AppointmentCubit>().loadAppointmentDetail(widget.appointmentId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocConsumer<AppointmentCubit, AppointmentState>(
        listener: (context, state) {
          if (state is AppointmentActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
              ),
            );
            context.pop(true);
          }
          if (state is AppointmentError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is AppointmentLoading || state is AppointmentActionInProgress) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is AppointmentDetailLoaded) {
            return _buildDetail(context, state.appointment, theme, isDark);
          }

          if (state is AppointmentError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: 12),
                  Text(state.message),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context
                        .read<AppointmentCubit>()
                        .loadAppointmentDetail(widget.appointmentId),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildDetail(
    BuildContext context,
    AppointmentEntity apt,
    ThemeData theme,
    bool isDark,
  ) {
    final endTime = apt.scheduledAt.add(const Duration(minutes: 30));
    final (statusLabel, statusColor) = switch (apt.status) {
      AppointmentStatus.scheduled => ('Pending', AppColors.warning),
      AppointmentStatus.confirmed => ('Confirmed', AppColors.success),
      AppointmentStatus.cancelled => ('Cancelled', AppColors.error),
      AppointmentStatus.completed => ('Completed', AppColors.textSecondary),
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Today Banner ───
          if (apt.isToday &&
              apt.status != AppointmentStatus.cancelled &&
              apt.status != AppointmentStatus.completed)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule, color: AppColors.warning, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Appointment Today',
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.warning,
                          ),
                        ),
                        Text(
                          'Your appointment is at ${DateFormat.jm().format(apt.scheduledAt)}. Please arrive 10 minutes early.',
                          style: AppTextStyles.bodySm.copyWith(
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // ─── Person Info Card ───
          _card(
            theme,
            isDark,
            child: Row(
              children: [
                _buildAvatar(apt),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        apt.relatedPersonName,
                        style: AppTextStyles.heading3.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      if (apt.specialty != null)
                        Text(
                          apt.specialty!,
                          style: AppTextStyles.bodyMd.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: statusColor.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    statusLabel,
                    style: AppTextStyles.labelSm.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ─── Appointment Information ───
          _card(
            theme,
            isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Appointment Information',
                  style: AppTextStyles.label.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                _infoTile(
                  Icons.calendar_today_outlined,
                  'Date',
                  DateFormat.yMMMMEEEEd().format(apt.scheduledAt),
                  theme,
                ),
                _infoTile(
                  Icons.access_time_outlined,
                  'Time',
                  '${DateFormat.jm().format(apt.scheduledAt)} — ${DateFormat.jm().format(endTime)} (30 minutes)',
                  theme,
                ),
                if (apt.locationName != null)
                  _infoTile(
                    Icons.location_on_outlined,
                    'Location',
                    apt.locationName!,
                    theme,
                  ),
                // Booking ID — hidden from patient
                if (widget.isDoctorView)
                  _infoTile(
                    Icons.tag,
                    'Booking ID',
                    apt.id.substring(0, 8).toUpperCase(),
                    theme,
                  ),
                _infoTile(
                  Icons.event_note_outlined,
                  'Booked on',
                  DateFormat.yMMMd().format(apt.createdAt),
                  theme,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ─── Actions ───
          _buildActions(context, apt, theme),
        ],
      ),
    );
  }

  Widget _card(ThemeData theme, bool isDark, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkSurfaceAlt : AppColors.divider,
          width: 0.5,
        ),
      ),
      child: child,
    );
  }

  Widget _buildAvatar(AppointmentEntity apt) {
    final name = apt.relatedPersonName;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
      const Color(0xFF06B6D4),
    ];
    final bgColor = colors[initial.codeUnitAt(0) % colors.length];

    if (apt.relatedPersonImageUrl != null &&
        apt.relatedPersonImageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 28,
        backgroundImage: NetworkImage(apt.relatedPersonImageUrl!),
        backgroundColor: bgColor,
      );
    }

    return CircleAvatar(
      radius: 28,
      backgroundColor: bgColor,
      child: Text(
        initial,
        style: AppTextStyles.heading3.copyWith(
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _infoTile(
    IconData icon,
    String label,
    String value,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.bodyMd.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(
    BuildContext context,
    AppointmentEntity apt,
    ThemeData theme,
  ) {
    if (widget.isDoctorView) {
      // Doctor — no actions for completed or cancelled
      if (apt.status == AppointmentStatus.completed ||
          apt.status == AppointmentStatus.cancelled) {
        return const SizedBox.shrink();
      }
      if (apt.status == AppointmentStatus.scheduled) {
        return Column(
          children: [
            ElevatedButton(
              onPressed: () => context
                  .read<AppointmentCubit>()
                  .confirmAppointment(apt.id),
              child: const Text('Accept Appointment'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => context
                  .read<AppointmentCubit>()
                  .cancelAppointment(apt.id),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
              ),
              child: const Text('Reject'),
            ),
          ],
        );
      }
      if (apt.status == AppointmentStatus.confirmed) {
        return Column(
          children: [
            ElevatedButton(
              onPressed: () => context
                  .read<AppointmentCubit>()
                  .completeAppointment(apt.id),
              child: const Text('Mark Complete'),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => CancelAppointmentSheet.show(
                context,
                personName: apt.relatedPersonName,
                onCancel: () => context
                    .read<AppointmentCubit>()
                    .cancelAppointment(apt.id),
              ),
              child: Text(
                'Cancel Appointment',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        );
      }
      return const SizedBox.shrink();
    }

    // Patient view — always show "View Doctor Profile"; conditionally show messaging/cancel
    return Column(
      children: [
        if (apt.status != AppointmentStatus.completed &&
            apt.status != AppointmentStatus.cancelled) ...[
          ElevatedButton.icon(
            onPressed: () => _startConversation(context, apt.doctorUserId),
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('Message Doctor'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => CancelAppointmentSheet.show(
              context,
              personName: apt.relatedPersonName,
              onCancel: () => context
                  .read<AppointmentCubit>()
                  .cancelAppointment(apt.id),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
            ),
            child: const Text('Cancel Appointment'),
          ),
          const SizedBox(height: 10),
        ],
        OutlinedButton.icon(
          icon: const Icon(Icons.person_outline),
          label: const Text('View Doctor Profile'),
          onPressed: () => context.push(
            '/doctor-details/${apt.doctorUserId}',
            extra: {
              'canReview': apt.status == AppointmentStatus.completed,
              'canMessage': apt.status != AppointmentStatus.cancelled,
            },
          ),
        ),
      ],
    );
  }

  void _startConversation(BuildContext context, String counterpartyId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final startUc = sl<StartConversationUseCase>();
      final result = await startUc(counterpartyId);
      
      if (context.mounted) Navigator.pop(context);

      switch (result) {
        case Success(:final data):
          if (context.mounted) {
            context.push('/chat/${data.id}');
          }
        case Error(:final failure):
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(failure.message), backgroundColor: AppColors.error),
            );
          }
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
    }
  }
}
