import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../domain/entities/appointment_entity.dart';

/// Reusable appointment card used in both patient and doctor list screens.
class AppointmentCard extends StatelessWidget {
  final AppointmentEntity appointment;
  final bool isDoctorView;
  final VoidCallback? onTap;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onComplete;
  final VoidCallback? onCancel;
  final VoidCallback? onMessage;

  const AppointmentCard({
    super.key,
    required this.appointment,
    this.isDoctorView = false,
    this.onTap,
    this.onAccept,
    this.onReject,
    this.onComplete,
    this.onCancel,
    this.onMessage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.darkSurfaceAlt : AppColors.divider,
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Header: Avatar + Name + Status Badge ───
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  _buildAvatar(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appointment.relatedPersonName,
                          style: AppTextStyles.label.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        if (appointment.specialty != null)
                          Text(
                            appointment.specialty!,
                            style: AppTextStyles.bodySm.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(),
                ],
              ),
            ),

            // ─── Today banner ───
            if (appointment.isToday &&
                appointment.effectiveStatus != AppointmentStatus.cancelled &&
                appointment.effectiveStatus != AppointmentStatus.completed)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 16,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your appointment is today at ${DateFormat.jm().format(appointment.scheduledAt)}',
                        style: AppTextStyles.bodySm.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ─── Info rows: Date, Time, Location ───
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                children: [
                  _infoRow(
                    Icons.calendar_today_outlined,
                    DateFormat.yMMMEd().format(appointment.scheduledAt),
                    theme,
                  ),
                  const SizedBox(height: 4),
                  _infoRow(
                    Icons.access_time_outlined,
                    DateFormat.jm().format(appointment.scheduledAt),
                    theme,
                  ),
                  if (appointment.locationName != null) ...[
                    const SizedBox(height: 4),
                    _infoRow(
                      Icons.location_on_outlined,
                      appointment.locationName!,
                      theme,
                    ),
                  ],
                ],
              ),
            ),

            // ─── Action buttons ───
            if (_hasActions) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: _buildActions(theme),
              ),
            ] else
              const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return UserAvatar(
      radius: 22,
      imageUrl: appointment.relatedPersonImageUrl,
      fullName: appointment.relatedPersonName,
      backgroundColor: _avatarColor(appointment.relatedPersonName.isNotEmpty
          ? appointment.relatedPersonName[0].toUpperCase()
          : '?'),
      textStyle: AppTextStyles.label.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildStatusBadge() {
    final label = isDoctorView
        ? appointment.effectiveStatus.doctorLabel
        : appointment.effectiveStatus.patientLabel;
    final color = switch (appointment.effectiveStatus) {
      AppointmentStatus.scheduled => AppColors.warning,
      AppointmentStatus.confirmed => AppColors.success,
      AppointmentStatus.cancelled => AppColors.error,
      AppointmentStatus.completed => AppColors.textSecondary,
      AppointmentStatus.pendingPayment => AppColors.info,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, ThemeData theme) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodySm.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  bool get _hasActions {
    if (isDoctorView) {
      return appointment.effectiveStatus == AppointmentStatus.scheduled ||
          appointment.effectiveStatus == AppointmentStatus.confirmed ||
          onMessage != null;
    }
    return appointment.effectiveStatus == AppointmentStatus.scheduled ||
        appointment.effectiveStatus == AppointmentStatus.confirmed;
  }

  Widget _buildActions(ThemeData theme) {
    if (isDoctorView) {
      if (appointment.effectiveStatus == AppointmentStatus.scheduled) {
        return Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 40,
                child: ElevatedButton(
                  onPressed: onAccept,
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Text('Accept'),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 40,
                child: OutlinedButton(
                  onPressed: onReject,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Text('Reject'),
                ),
              ),
            ),
            if (onMessage != null) ...[
              const SizedBox(width: 10),
              SizedBox(
                height: 40,
                child: OutlinedButton(
                  onPressed: onMessage,
                  style: OutlinedButton.styleFrom(minimumSize: Size.zero),
                  child: const Icon(Icons.message_outlined, size: 18),
                ),
              ),
            ],
          ],
        );
      }
      if (appointment.effectiveStatus == AppointmentStatus.confirmed) {
        return Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 40,
                child: OutlinedButton(
                  onPressed: onComplete,
                  style: OutlinedButton.styleFrom(minimumSize: Size.zero),
                  child: const Text('Complete'),
                ),
              ),
            ),
            if (onMessage != null) ...[
              const SizedBox(width: 10),
              SizedBox(
                height: 40,
                child: OutlinedButton(
                  onPressed: onMessage,
                  style: OutlinedButton.styleFrom(minimumSize: Size.zero),
                  child: const Icon(Icons.message_outlined, size: 18),
                ),
              ),
            ],
          ],
        );
      }
      if (onMessage != null) {
        return SizedBox(
          height: 40,
          child: OutlinedButton.icon(
            onPressed: onMessage,
            icon: const Icon(Icons.message_outlined, size: 18),
            label: const Text('Message'),
            style: OutlinedButton.styleFrom(minimumSize: Size.zero),
          ),
        );
      }
    }

    // Patient view — Cancel button
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.info_outline, size: 18),
          label: const Text('View Details'),
        ),
        TextButton.icon(
          onPressed: onCancel,
          icon: Icon(Icons.close, size: 18, color: AppColors.error),
          label: Text(
            'Cancel',
            style: TextStyle(color: AppColors.error),
          ),
        ),
      ],
    );
  }

  Color _avatarColor(String initial) {
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
      const Color(0xFF06B6D4),
      const Color(0xFFF97316),
    ];
    return colors[initial.codeUnitAt(0) % colors.length];
  }
}
