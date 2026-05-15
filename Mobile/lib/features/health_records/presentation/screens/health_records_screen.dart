import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/routing/app_router.dart';
import '../../domain/entities/health_record_entity.dart';
import '../cubits/health_record_cubit.dart';
import '../cubits/health_record_state.dart';
import '../widgets/allergy_alert_banner.dart';
import '../widgets/category_tabs.dart';
import '../widgets/empty_records_view.dart';
import '../widgets/record_list_tile.dart';
import '../widgets/vital_card.dart';

// TASK 2.4 — Date filter enum (client-side, no API call)
enum _DateFilter { thisMonth, last3Months, thisYear, all }

class HealthRecordsScreen extends StatefulWidget {
  const HealthRecordsScreen({super.key});

  @override
  State<HealthRecordsScreen> createState() => _HealthRecordsScreenState();
}

class _HealthRecordsScreenState extends State<HealthRecordsScreen> {
  _DateFilter _dateFilter = _DateFilter.all;

  static const _vitalMeta = [
    (
      key: 'bloodPressure',
      label: 'Blood Pressure',
      icon: Icons.favorite_outline,
      color: Colors.red
    ),
    (
      key: 'heartRate',
      label: 'Heart Rate',
      icon: Icons.monitor_heart_outlined,
      color: Colors.pink
    ),
    (
      key: 'bloodSugar',
      label: 'Blood Sugar',
      icon: Icons.water_drop_outlined,
      color: Colors.orange
    ),
    (
      key: 'temperature',
      label: 'Temperature',
      icon: Icons.thermostat_outlined,
      color: Colors.amber
    ),
    (
      key: 'weight',
      label: 'Weight',
      icon: Icons.fitness_center_outlined,
      color: Colors.green
    ),
    (
      key: 'spO2',
      label: 'SpO2',
      icon: Icons.air_outlined,
      color: Colors.blue
    ),
  ];

  VitalEntity? _vitalFor(HealthSummaryEntity summary, String key) =>
      switch (key) {
        'bloodPressure' => summary.bloodPressure,
        'heartRate' => summary.heartRate,
        'bloodSugar' => summary.bloodSugar,
        'temperature' => summary.temperature,
        'weight' => summary.weight,
        'spO2' => summary.spO2,
        _ => null,
      };

  List<HealthRecordEntity> _applyDateFilter(List<HealthRecordEntity> records) {
    final now = DateTime.now();
    return records.where((r) {
      return switch (_dateFilter) {
        _DateFilter.thisMonth =>
          r.recordedAt.isAfter(now.subtract(const Duration(days: 30))),
        _DateFilter.last3Months =>
          r.recordedAt.isAfter(now.subtract(const Duration(days: 90))),
        _DateFilter.thisYear => r.recordedAt.year == now.year,
        _DateFilter.all => true,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Records')),
      // TASK 1.6 — Persistent bottom bar instead of FAB
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: () async {
              await context.pushNamed(RouteNames.addHealthRecord);
              if (context.mounted) {
                context.read<HealthRecordCubit>().loadRecords();
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Add New Record'),
          ),
        ),
      ),
      body: BlocConsumer<HealthRecordCubit, HealthRecordState>(
        listener: (context, state) {
          if (state is HealthRecordActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is HealthRecordLoading || state is HealthRecordInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is HealthRecordError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () =>
                        context.read<HealthRecordCubit>().loadRecords(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is HealthRecordListLoaded) {
            final allergies = state.records
                .where((r) => r.type == HealthRecordType.allergy)
                .toList();
            final filtered = _applyDateFilter(state.records);

            return RefreshIndicator(
              onRefresh: () => context
                  .read<HealthRecordCubit>()
                  .loadRecords(type: state.activeFilter),
              child: CustomScrollView(
                slivers: [
                  // TASK 1.5 — Allergy alert banner (always first)
                  SliverToBoxAdapter(
                    child: AllergyAlertBanner(allergies: allergies),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 0, 8),
                      child: Text(
                        'Vitals Summary',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 130,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: _vitalMeta
                            .map(
                              (m) => VitalCard(
                                label: m.label,
                                vital: _vitalFor(state.summary, m.key),
                                icon: m.icon,
                                color: m.color,
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                  SliverToBoxAdapter(
                    child: CategoryTabs(
                      activeFilter: state.activeFilter,
                      onFilterChanged: (type) => context
                          .read<HealthRecordCubit>()
                          .loadRecords(type: type),
                    ),
                  ),

                  // TASK 2.4 — Date filter chips (client-side)
                  SliverToBoxAdapter(
                    child: _DateFilterBar(
                      current: _dateFilter,
                      onChanged: (f) => setState(() => _dateFilter = f),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 8)),
                  if (filtered.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyRecordsView(),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final record = filtered[index];
                          // TASK 2.5 — Semantic labels for accessibility
                          return Semantics(
                            label:
                                'Health record: ${record.title}, '
                                'type: ${record.type.name}, '
                                'recorded on ${DateFormat('MMMM d, y').format(record.recordedAt.toLocal())}. '
                                'Swipe left to delete.',
                            child: RecordListTile(
                              record: record,
                              onTap: () => context.pushNamed(
                                RouteNames.healthRecordDetail,
                                pathParameters: {'id': record.id},
                              ),
                              onDelete: () => context
                                  .read<HealthRecordCubit>()
                                  .deleteRecord(record.id),
                            ),
                          );
                        },
                        childCount: filtered.length,
                      ),
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
}

// ─── Date Filter Bar ───
class _DateFilterBar extends StatelessWidget {
  final _DateFilter current;
  final ValueChanged<_DateFilter> onChanged;

  const _DateFilterBar({required this.current, required this.onChanged});

  static const _options = [
    (_DateFilter.thisMonth, 'This Month'),
    (_DateFilter.last3Months, 'Last 3 Months'),
    (_DateFilter.thisYear, 'This Year'),
    (_DateFilter.all, 'All Time'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: _options.map((opt) {
          final isSelected = current == opt.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(opt.$2),
              selected: isSelected,
              onSelected: (_) => onChanged(opt.$1),
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }
}
