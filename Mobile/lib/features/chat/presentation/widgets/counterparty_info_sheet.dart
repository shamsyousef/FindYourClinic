import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/token_storage.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../appointments/domain/entities/appointment_entity.dart';
import '../../../appointments/domain/usecases/appointment_usecases.dart';

class CounterpartyInfoSheet extends StatefulWidget {
  /// The user id of the counterparty (other side of the conversation).
  final String counterpartyUserId;
  final String counterpartyName;
  final String? counterpartyImageUrl;

  const CounterpartyInfoSheet({
    super.key,
    required this.counterpartyUserId,
    required this.counterpartyName,
    this.counterpartyImageUrl,
  });

  @override
  State<CounterpartyInfoSheet> createState() => _CounterpartyInfoSheetState();
}

class _CounterpartyInfoSheetState extends State<CounterpartyInfoSheet> {
  bool _loading = true;
  String? _role;
  List<AppointmentEntity> _shared = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final role = await sl<TokenStorage>().getUserRole();

    List<AppointmentEntity> all = const [];
    if (role == 'Patient') {
      final result = await sl<GetPatientAppointmentsUseCase>()();
      if (result is Success<List<AppointmentEntity>>) {
        all = result.data
            .where((a) => a.doctorUserId == widget.counterpartyUserId)
            .toList();
      }
    } else if (role == 'Doctor') {
      final result = await sl<GetDoctorAppointmentsUseCase>()();
      if (result is Success<List<AppointmentEntity>>) {
        all = result.data
            .where((a) => a.patientId == widget.counterpartyUserId)
            .toList();
      }
    }

    all.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));

    if (!mounted) return;
    setState(() {
      _role = role;
      _shared = all;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final roleLabel = _role == 'Doctor' ? 'Patient' : 'Doctor';

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBackground : AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            UserAvatar(
              radius: 44,
              imageUrl: widget.counterpartyImageUrl,
              fullName: widget.counterpartyName,
            ),
            const SizedBox(height: 12),
            Text(
              widget.counterpartyName,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                roleLabel,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    'Appointments together',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Text(
                    '${_shared.length}',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _shared.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'No shared appointments yet.',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                        )
                      : ListView.separated(
                          controller: scrollCtrl,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _shared.length,
                          separatorBuilder: (_, _) =>
                              const Divider(height: 0, indent: 72),
                          itemBuilder: (_, i) {
                            final a = _shared[i];
                            return _AppointmentTile(
                              appointment: a,
                              isDoctorView: _role == 'Doctor',
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppointmentTile extends StatelessWidget {
  final AppointmentEntity appointment;
  final bool isDoctorView;

  const _AppointmentTile({
    required this.appointment,
    required this.isDoctorView,
  });

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('EEE, MMM d · y');
    final timeFmt = DateFormat.jm();
    final status = appointment.effectiveStatus;
    final color = switch (status) {
      AppointmentStatus.confirmed => AppColors.success,
      AppointmentStatus.completed => AppColors.info,
      AppointmentStatus.cancelled => AppColors.error,
      AppointmentStatus.pendingPayment => AppColors.warning,
      AppointmentStatus.scheduled => AppColors.warning,
    };
    final label =
        isDoctorView ? status.doctorLabel : status.patientLabel;

    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.event_note_rounded, color: color),
      ),
      title: Text(
        dateFmt.format(appointment.scheduledAt.toLocal()),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(timeFmt.format(appointment.scheduledAt.toLocal())),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
      ),
      onTap: () {
        Navigator.of(context).pop();
        context.pushNamed(
          RouteNames.appointmentDetail,
          pathParameters: {'id': appointment.id},
          queryParameters: isDoctorView ? {'doctor': 'true'} : const {},
        );
      },
    );
  }
}
