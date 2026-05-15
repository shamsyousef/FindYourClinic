import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/routing/app_router.dart';
import '../cubits/health_record_cubit.dart';
import '../cubits/health_record_state.dart';

class HealthRecordDetailScreen extends StatelessWidget {
  final String recordId;

  const HealthRecordDetailScreen({super.key, required this.recordId});

  static const _typeLabels = {
    'bloodPressure': 'Blood Pressure',
    'heartRate': 'Heart Rate',
    'labResult': 'Lab Result',
    'prescription': 'Prescription',
    'other': 'Other',
    'bloodTest': 'Blood Test',
    'radiology': 'Radiology',
    'vaccination': 'Vaccination',
    'bloodSugar': 'Blood Sugar',
    'temperature': 'Temperature',
    'weight': 'Weight',
    'spO2': 'SpO2',
  };

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Detail'),
        actions: [
          BlocBuilder<HealthRecordCubit, HealthRecordState>(
            builder: (context, state) {
              if (state is! HealthRecordDetailLoaded) return const SizedBox();
              final record = state.record;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Semantics(
                    label: 'Edit ${record.title}',
                    child: IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Edit',
                      onPressed: () async {
                        await context.pushNamed(
                          RouteNames.addHealthRecord,
                          extra: record,
                        );
                        if (context.mounted) {
                          context
                              .read<HealthRecordCubit>()
                              .loadRecordDetail(recordId);
                        }
                      },
                    ),
                  ),
                  Semantics(
                    label: 'Delete ${record.title}',
                    child: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Delete',
                      color: Colors.red.shade400,
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete record?'),
                            content: Text(
                                'Remove "${record.title}" permanently?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: Text(
                                  'Delete',
                                  style:
                                      TextStyle(color: Colors.red.shade400),
                                ),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true && context.mounted) {
                          await context
                              .read<HealthRecordCubit>()
                              .deleteRecord(record.id);
                          if (context.mounted) context.pop();
                        }
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ],
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
            return Center(child: Text(state.message));
          }

          if (state is HealthRecordDetailLoaded) {
            final record = state.record;
            final typeLabel = _typeLabels[record.type.name] ?? record.type.name;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      typeLabel,
                      style: textTheme.labelMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    record.title,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (record.value != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          record.value!,
                          style: textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                        if (record.unit != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            record.unit!,
                            style: textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  _DetailRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Recorded',
                    value: DateFormat('MMMM d, y')
                        .format(record.recordedAt.toLocal()),
                  ),
                  if (record.notes != null && record.notes!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Notes',
                      style: textTheme.labelLarge?.copyWith(
                        color:
                            colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(record.notes!, style: textTheme.bodyMedium),
                  ],
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

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Icon(icon, size: 18, color: colorScheme.onSurface.withValues(alpha: 0.5)),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        Text(value, style: textTheme.bodyMedium),
      ],
    );
  }
}
