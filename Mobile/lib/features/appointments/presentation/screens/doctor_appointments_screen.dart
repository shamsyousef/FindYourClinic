import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../chat/domain/usecases/start_conversation_usecase.dart';
import '../../domain/entities/appointment_entity.dart';
import '../cubits/appointment_cubit.dart';
import '../cubits/appointment_state.dart';
import '../widgets/appointment_card.dart';

/// Doctor appointments list with gradient header, search bar,
/// and Upcoming / Past / All pill tabs.
class DoctorAppointmentsScreen extends StatefulWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  State<DoctorAppointmentsScreen> createState() =>
      _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState extends State<DoctorAppointmentsScreen> {
  int _selectedTab = 0;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    context.read<AppointmentCubit>().loadDoctorAppointments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
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
          return RefreshIndicator(
            onRefresh: () =>
                context.read<AppointmentCubit>().loadDoctorAppointments(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ─── Gradient Header ───
                SliverToBoxAdapter(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: isDark
                          ? AppTheme.headerGradientDark
                          : AppTheme.headerGradient,
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Appointments',
                              style: AppTextStyles.heading1.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Search bar
                            TextField(
                              controller: _searchController,
                              onChanged: (v) =>
                                  setState(() => _searchQuery = v.trim().toLowerCase()),
                              style: AppTextStyles.bodyMd.copyWith(
                                color: theme.colorScheme.onSurface,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Search patients...',
                                prefixIcon: const Icon(Icons.search),
                                filled: true,
                                fillColor: theme.cardTheme.color,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
  
                // ─── Pill Tab Bar ───
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      children: ['Upcoming', 'Past', 'All']
                          .asMap()
                          .entries
                          .map((e) => _pillTab(e.key, e.value, theme))
                          .toList(),
                    ),
                  ),
                ),
  
                // ─── Content ───
                if (state is AppointmentLoading ||
                    state is AppointmentActionInProgress)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (state is AppointmentListLoaded)
                  _buildList(context, state, theme)
                else if (state is AppointmentError)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline,
                              size: 48, color: AppColors.error),
                          const SizedBox(height: 12),
                          Text(state.message),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => context
                                .read<AppointmentCubit>()
                                .loadDoctorAppointments(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  const SliverFillRemaining(child: SizedBox.shrink()),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _pillTab(int index, String label, ThemeData theme) {
    final isSelected = _selectedTab == index;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _selectedTab = index),
        selectedColor: theme.colorScheme.primary,
        backgroundColor: theme.cardTheme.color,
        labelStyle: AppTextStyles.labelSm.copyWith(
          color: isSelected ? Colors.white : theme.colorScheme.onSurface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        side: BorderSide(
          color: isSelected
              ? theme.colorScheme.primary
              : AppColors.divider,
        ),
        showCheckmark: false,
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    AppointmentListLoaded state,
    ThemeData theme,
  ) {
    final list = switch (_selectedTab) {
      0 => state.upcoming,
      1 => [...state.completed, ...state.cancelled],
      _ => state.all,
    };

    // Filter by search
    final filtered = _searchQuery.isEmpty
        ? list
        : list
            .where((a) =>
                a.relatedPersonName.toLowerCase().contains(_searchQuery))
            .toList();

    if (filtered.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event_busy_outlined,
                  size: 64, color: AppColors.textHint),
              const SizedBox(height: 16),
              Text(
                _searchQuery.isNotEmpty
                    ? 'No patients found'
                    : 'No appointments',
                style: AppTextStyles.heading3.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final apt = filtered[index];
          return AppointmentCard(
            appointment: apt,
            isDoctorView: true,
            onTap: () => context.push('/appointment/${apt.id}?doctor=true'),
            onAccept: apt.effectiveStatus == AppointmentStatus.scheduled
                ? () => context
                    .read<AppointmentCubit>()
                    .confirmAppointment(apt.id)
                : null,
            onReject: apt.effectiveStatus == AppointmentStatus.scheduled
                ? () => context
                    .read<AppointmentCubit>()
                    .cancelAppointment(apt.id)
                : null,
            onComplete: apt.effectiveStatus == AppointmentStatus.confirmed
                ? () => context
                    .read<AppointmentCubit>()
                    .completeAppointment(apt.id)
                : null,
            onMessage: apt.effectiveStatus != AppointmentStatus.cancelled
                ? () => _messagePatient(context, apt.patientId)
                : null,
          );
        },
        childCount: filtered.length,
      ),
    );
  }

  Future<void> _messagePatient(BuildContext ctx, String patientId) async {
    final result = await sl<StartConversationUseCase>()(patientId);
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
}
