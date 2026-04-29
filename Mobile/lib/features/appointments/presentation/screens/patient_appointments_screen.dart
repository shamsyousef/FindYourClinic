import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/appointment_entity.dart';
import '../cubits/appointment_cubit.dart';
import '../cubits/appointment_state.dart';
import '../widgets/appointment_card.dart';
import '../widgets/cancel_appointment_sheet.dart';

/// Patient appointments list with Upcoming / Completed / Cancelled tabs.
class PatientAppointmentsScreen extends StatefulWidget {
  const PatientAppointmentsScreen({super.key});

  @override
  State<PatientAppointmentsScreen> createState() =>
      _PatientAppointmentsScreenState();
}

class _PatientAppointmentsScreenState extends State<PatientAppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    context.read<AppointmentCubit>().loadPatientAppointments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Appointments',
          style: AppTextStyles.heading2.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: theme.colorScheme.primary,
          labelStyle: AppTextStyles.label,
          unselectedLabelStyle: AppTextStyles.bodyMd,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
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

          if (state is AppointmentListLoaded) {
            return TabBarView(
              controller: _tabController,
              children: [
                _buildTab(context, state.upcoming, 'upcoming'),
                _buildTab(context, state.completed, 'completed'),
                _buildTab(context, state.cancelled, 'cancelled'),
              ],
            );
          }

          if (state is AppointmentError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(state.message, style: AppTextStyles.bodyMd),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        context.read<AppointmentCubit>().loadPatientAppointments(),
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

  Widget _buildTab(
    BuildContext context,
    List<AppointmentEntity> appointments,
    String type,
  ) {
    if (appointments.isEmpty) {
      return _buildEmptyState(context, type);
    }

    return RefreshIndicator(
      onRefresh: () =>
          context.read<AppointmentCubit>().loadPatientAppointments(),
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 12, bottom: 80),
        itemCount: appointments.length,
        itemBuilder: (context, index) {
          final apt = appointments[index];
          return AppointmentCard(
            appointment: apt,
            onTap: () => context.push(
              '/appointment/${apt.id}',
            ),
            onCancel: (apt.status == AppointmentStatus.scheduled ||
                    apt.status == AppointmentStatus.confirmed)
                ? () => CancelAppointmentSheet.show(
                      context,
                      personName: apt.relatedPersonName,
                      onCancel: () => context
                          .read<AppointmentCubit>()
                          .cancelAppointment(apt.id),
                    )
                : null,
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String type) {
    final theme = Theme.of(context);
    final (icon, title, subtitle) = switch (type) {
      'upcoming' => (
          Icons.calendar_today_outlined,
          'No Upcoming Appointments',
          'Book your first appointment with a doctor\nto get started on your health journey.',
        ),
      'completed' => (
          Icons.check_circle_outline,
          'No Completed Appointments',
          'Your completed appointments will appear here.',
        ),
      _ => (
          Icons.cancel_outlined,
          'No Cancelled Appointments',
          'No cancelled appointments to show.',
        ),
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 72, color: AppColors.textHint),
            const SizedBox(height: 20),
            Text(
              title,
              style: AppTextStyles.heading3.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (type == 'upcoming') ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.push('/search'),
                icon: const Icon(Icons.search),
                label: const Text('Find a Doctor'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
