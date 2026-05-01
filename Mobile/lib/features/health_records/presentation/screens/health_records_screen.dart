import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router.dart';
import '../../domain/entities/health_record_entity.dart';
import '../cubits/health_record_cubit.dart';
import '../cubits/health_record_state.dart';
import '../widgets/category_tabs.dart';
import '../widgets/empty_records_view.dart';
import '../widgets/record_list_tile.dart';
import '../widgets/vital_card.dart';

class HealthRecordsScreen extends StatelessWidget {
  const HealthRecordsScreen({super.key});

  static const _vitalMeta = [
    (key: 'bloodPressure', label: 'Blood Pressure', icon: Icons.favorite_outline, color: Colors.red),
    (key: 'heartRate', label: 'Heart Rate', icon: Icons.monitor_heart_outlined, color: Colors.pink),
    (key: 'bloodSugar', label: 'Blood Sugar', icon: Icons.water_drop_outlined, color: Colors.orange),
    (key: 'temperature', label: 'Temperature', icon: Icons.thermostat_outlined, color: Colors.amber),
    (key: 'weight', label: 'Weight', icon: Icons.fitness_center_outlined, color: Colors.green),
    (key: 'spO2', label: 'SpO2', icon: Icons.air_outlined, color: Colors.blue),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Records')),
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
            return RefreshIndicator(
              onRefresh: () => context
                  .read<HealthRecordCubit>()
                  .loadRecords(type: state.activeFilter),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 0, 8),
                      child: Text(
                        'Vitals Summary',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
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
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),
                  if (state.records.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyRecordsView(),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final record = state.records[index];
                          return RecordListTile(
                            record: record,
                            onTap: () => context.pushNamed(
                              RouteNames.healthRecordDetail,
                              pathParameters: {'id': record.id},
                            ),
                            onDelete: () => context
                                .read<HealthRecordCubit>()
                                .deleteRecord(record.id),
                          );
                        },
                        childCount: state.records.length,
                      ),
                    ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.pushNamed(RouteNames.addHealthRecord);
          if (context.mounted) {
            context.read<HealthRecordCubit>().loadRecords();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
