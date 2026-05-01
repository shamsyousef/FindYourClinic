import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../chat/domain/usecases/start_conversation_usecase.dart';
import '../../domain/entities/appointment_entity.dart';
import '../cubits/appointment_cubit.dart';
import '../cubits/appointment_state.dart';
import '../cubits/patient_card_cubit.dart';
import '../widgets/cancel_appointment_sheet.dart';
import '../widgets/patient_info_card.dart';

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
    context
        .read<AppointmentCubit>()
        .loadAppointmentDetail(widget.appointmentId);
  }

  @override
  Widget build(BuildContext context) {
    final body = Scaffold(
      appBar: AppBar(
        title: Text(
            widget.isDoctorView ? 'Appointment Details' : 'My Appointment'),
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
                  backgroundColor: AppColors.success),
            );
            context.pop(true);
          }
          if (state is AppointmentError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error),
            );
          }
        },
        builder: (context, state) {
          if (state is AppointmentLoading ||
              state is AppointmentActionInProgress) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is AppointmentDetailLoaded) {
            if (widget.isDoctorView) {
              // Trigger patient card load on first render
              final cubit = context.read<PatientCardCubit>();
              if (cubit.state is PatientCardInitial) {
                cubit.load(state.appointment.patientId);
              }
            }
            return _AppointmentDetailBody(
              apt: state.appointment,
              isDoctorView: widget.isDoctorView,
            );
          }
          if (state is AppointmentError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: AppColors.error),
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

    if (!widget.isDoctorView) return body;

    return BlocProvider(
      create: (_) => sl<PatientCardCubit>(),
      child: body,
    );
  }
}

class _AppointmentDetailBody extends StatelessWidget {
  final AppointmentEntity apt;
  final bool isDoctorView;

  const _AppointmentDetailBody({
    required this.apt,
    required this.isDoctorView,
  });

  @override
  Widget build(BuildContext context) {
    final endTime = apt.scheduledAt.add(const Duration(minutes: 30));

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Doctor action banner (Accept/Decline/Complete)
          if (isDoctorView) ...[
            _ActionBanner(apt: apt),
            const SizedBox(height: 12),
          ],

          // 2. Info card (Doctor or Patient)
          _InfoCard(
            child: Row(
              children: [
                _Avatar(
                  name: apt.relatedPersonName,
                  imageUrl: apt.relatedPersonImageUrl,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(apt.relatedPersonName,
                          style: AppTextStyles.heading3),
                      if (apt.specialty != null)
                        Text(
                          apt.specialty!,
                          style: AppTextStyles.bodySm
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      if (isDoctorView)
                        Text(
                          'Booking #${apt.id.substring(0, 8).toUpperCase()}',
                          style: AppTextStyles.bodySm
                              .copyWith(color: AppColors.textSecondary),
                        ),
                    ],
                  ),
                ),
                _StatusBadge(status: apt.effectiveStatus, isDoctor: isDoctorView),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 3. Large date/time block
          _InfoCard(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.calendar_today,
                      color: AppColors.primary, size: 32),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE, MMM d').format(apt.scheduledAt),
                      style: AppTextStyles.heading3,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${DateFormat.jm().format(apt.scheduledAt)} — ${DateFormat.jm().format(endTime)}',
                      style: AppTextStyles.bodyMd
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 4. Details
          _InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Details', style: AppTextStyles.label),
                const SizedBox(height: 12),
                if (apt.locationName != null)
                  _InfoRow(Icons.location_on_outlined, 'Location',
                      apt.locationName!),
                _InfoRow(
                    Icons.confirmation_number_outlined,
                    'Booking Ref',
                    '#${apt.id.substring(0, 8).toUpperCase()}'),
                _InfoRow(Icons.event_note_outlined, 'Booked on',
                    DateFormat.yMMMd().format(apt.createdAt)),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 5. Patient info card (doctor only)
          if (isDoctorView) ...[
            const SizedBox(height: 16),
            PatientInfoCard(patientId: apt.patientId),
            const SizedBox(height: 4),
          ],

          // 6. Actions
          if (!isDoctorView)
            OutlinedButton.icon(
              icon: const Icon(Icons.person_outline),
              label: const Text('View Doctor Profile'),
              onPressed: () => context.push(
                '/doctor-details/${apt.doctorUserId}',
                extra: {
                  'canReview': apt.effectiveStatus == AppointmentStatus.completed,
                  'canMessage': apt.effectiveStatus != AppointmentStatus.cancelled,
                },
              ),
            ),

          if (apt.effectiveStatus != AppointmentStatus.completed &&
              apt.effectiveStatus != AppointmentStatus.cancelled) ...[
            if (!isDoctorView) const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () => _startConversation(
                context,
                isDoctorView ? apt.patientId : apt.doctorUserId,
              ),
              icon: const Icon(Icons.chat_bubble_outline),
              label: Text(isDoctorView ? 'Message Patient' : 'Message Doctor'),
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
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Cancel Appointment'),
            ),
          ],
        ],
      ),
    );
  }

  void _startConversation(BuildContext context, String userId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final result = await sl<StartConversationUseCase>()(userId);
      if (context.mounted) Navigator.pop(context);
      switch (result) {
        case Success(:final data):
          if (context.mounted) context.push('/chat/${data.id}');
        case Error(:final failure):
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(failure.message),
                  backgroundColor: AppColors.error),
            );
          }
      }
    } catch (_) {
      if (context.mounted) Navigator.pop(context);
    }
  }
}

class _ActionBanner extends StatelessWidget {
  final AppointmentEntity apt;
  const _ActionBanner({required this.apt});

  @override
  Widget build(BuildContext context) {
    if (apt.effectiveStatus == AppointmentStatus.scheduled) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.warning.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.warning.withAlpha(80)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.pending_actions,
                    color: AppColors.warning, size: 20),
                const SizedBox(width: 8),
                Text('Action Required',
                    style: AppTextStyles.label
                        .copyWith(color: AppColors.warning)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                        backgroundColor: AppColors.success),
                    onPressed: () => context
                        .read<AppointmentCubit>()
                        .confirmAppointment(apt.id),
                    child: const Text('Accept'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                    onPressed: () => context
                        .read<AppointmentCubit>()
                        .cancelAppointment(apt.id),
                    child: const Text('Decline'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (apt.effectiveStatus == AppointmentStatus.confirmed) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.success.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.success.withAlpha(80)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle_outline,
                    color: AppColors.success, size: 20),
                const SizedBox(width: 8),
                Text('Appointment Confirmed',
                    style: AppTextStyles.label
                        .copyWith(color: AppColors.success)),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary),
                onPressed: () => context
                    .read<AppointmentCubit>()
                    .completeAppointment(apt.id),
                child: const Text('Mark as Completed'),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

// ─────────────────────────────────────────────
// Shared small widgets
// ─────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final Widget child;
  const _InfoCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline.withAlpha(40)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 4,
              offset: const Offset(0, 1)),
        ],
      ),
      child: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 1),
                Text(value,
                    style: AppTextStyles.bodyMd
                        .copyWith(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final AppointmentStatus status;
  final bool isDoctor;
  const _StatusBadge({required this.status, required this.isDoctor});

  Color get _color => switch (status) {
        AppointmentStatus.scheduled => AppColors.warning,
        AppointmentStatus.confirmed => AppColors.success,
        AppointmentStatus.cancelled => AppColors.error,
        AppointmentStatus.completed => AppColors.textSecondary,
      };

  String get _label => isDoctor ? status.doctorLabel : status.patientLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withAlpha(100)),
      ),
      child: Text(
        _label,
        style: AppTextStyles.labelSm.copyWith(
          color: _color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final String? imageUrl;
  const _Avatar({required this.name, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    const colors = [
      AppColors.primary,
      AppColors.secondary,
      Color(0xFF8B5CF6),
      Color(0xFFEC4899),
      Color(0xFF06B6D4),
    ];
    final bg = colors[initial.codeUnitAt(0) % colors.length];

    return UserAvatar(
      radius: 26,
      imageUrl: imageUrl,
      fullName: name,
      backgroundColor: bg,
      textStyle: AppTextStyles.heading3.copyWith(color: Colors.white),
    );
  }
}
