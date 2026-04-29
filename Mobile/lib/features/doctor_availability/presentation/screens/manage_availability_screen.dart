import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/availability_config_entity.dart';
import '../cubits/manage_availability_cubit.dart';
import '../cubits/manage_availability_state.dart';
import '../widgets/add_availability_sheet.dart';

class ManageAvailabilityScreen extends StatefulWidget {
  const ManageAvailabilityScreen({super.key});

  @override
  State<ManageAvailabilityScreen> createState() => _ManageAvailabilityScreenState();
}

class _ManageAvailabilityScreenState extends State<ManageAvailabilityScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ManageAvailabilityCubit>().loadAvailability();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Schedule'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: BlocConsumer<ManageAvailabilityCubit, ManageAvailabilityState>(
        listener: (context, state) {
          if (state is ManageAvailabilityError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ManageAvailabilityInitial || state is ManageAvailabilityLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ManageAvailabilityLoaded) {
            final slots = state.slots;

            if (slots.isEmpty) {
              return const EmptyStateView(
                icon: Icons.event_available,
                title: 'No Availability Set',
                subtitle: 'Tap the + button to add your working hours.',
              );
            }

            final grouped = _groupSlotsByDay(slots);
            final daysOrder = [
              'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
            ];

            return Stack(
              children: [
                ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80, top: 16),
                  itemCount: daysOrder.length,
                  itemBuilder: (context, index) {
                    final day = daysOrder[index];
                    final daySlots = grouped[day] ?? [];

                    if (daySlots.isEmpty) return const SizedBox.shrink();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          child: Text(
                            day,
                            style: AppTextStyles.heading3.copyWith(color: AppColors.primary),
                          ),
                        ),
                        ...daySlots.map((slot) => _SlotCard(
                              slot: slot,
                              onRemove: () => context
                                  .read<ManageAvailabilityCubit>()
                                  .removeSlot(slot.id),
                            )),
                        const Divider(height: 32),
                      ],
                    );
                  },
                ),
                if (state is ManageAvailabilityOperationInProgress)
                  Container(
                    color: Colors.black12,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => AddAvailabilitySheet(
              onAdd: (dayOfWeek, startTime, endTime) {
                context.read<ManageAvailabilityCubit>().addSlot(
                      dayOfWeek: dayOfWeek,
                      startTime: startTime,
                      endTime: endTime,
                    );
              },
            ),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Map<String, List<AvailabilityConfigEntity>> _groupSlotsByDay(
      List<AvailabilityConfigEntity> slots) {
    final map = <String, List<AvailabilityConfigEntity>>{};
    for (final slot in slots) {
      if (!map.containsKey(slot.dayOfWeek)) {
        map[slot.dayOfWeek] = [];
      }
      map[slot.dayOfWeek]!.add(slot);
    }
    // Sort times within each day
    for (final list in map.values) {
      list.sort((a, b) => a.startTime.compareTo(b.startTime));
    }
    return map;
  }
}

class _SlotCard extends StatelessWidget {
  final AvailabilityConfigEntity slot;
  final VoidCallback onRemove;

  const _SlotCard({required this.slot, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Use the app's established dark surface color for consistency
    final cardColor = isDark ? AppColors.darkSurface : Colors.white;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final borderColor = isDark ? Colors.white12 : AppColors.divider;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0x141A6B52), // AppColors.primary at ~8% opacity
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.access_time,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '${slot.startTime} — ${slot.endTime}',
                style: AppTextStyles.bodyLg.copyWith(
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            tooltip: 'Remove Slot',
          ),
        ],
      ),
    );
  }
}
