import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/health_record_entity.dart';

class RecordListTile extends StatelessWidget {
  final HealthRecordEntity record;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const RecordListTile({
    super.key,
    required this.record,
    required this.onTap,
    required this.onDelete,
  });

  static IconData _iconFor(HealthRecordType type) => switch (type) {
        HealthRecordType.bloodPressure => Icons.favorite_outline,
        HealthRecordType.heartRate => Icons.monitor_heart_outlined,
        HealthRecordType.bloodSugar => Icons.water_drop_outlined,
        HealthRecordType.temperature => Icons.thermostat_outlined,
        HealthRecordType.weight => Icons.fitness_center_outlined,
        HealthRecordType.spO2 => Icons.air_outlined,
        HealthRecordType.bloodTest => Icons.biotech_outlined,
        HealthRecordType.radiology => Icons.medical_information_outlined,
        HealthRecordType.labResult => Icons.science_outlined,
        HealthRecordType.prescription => Icons.medication_outlined,
        HealthRecordType.vaccination => Icons.vaccines_outlined,
        HealthRecordType.other => Icons.note_outlined,
      };

  static Color _colorFor(HealthRecordType type) => switch (type) {
        HealthRecordType.bloodPressure => Colors.red,
        HealthRecordType.heartRate => Colors.pink,
        HealthRecordType.bloodSugar => Colors.orange,
        HealthRecordType.temperature => Colors.amber,
        HealthRecordType.weight => Colors.green,
        HealthRecordType.spO2 => Colors.blue,
        HealthRecordType.bloodTest => Colors.purple,
        HealthRecordType.radiology => Colors.teal,
        HealthRecordType.labResult => Colors.indigo,
        HealthRecordType.prescription => Colors.cyan,
        HealthRecordType.vaccination => Colors.lightGreen,
        HealthRecordType.other => Colors.grey,
      };

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(record.type);
    final icon = _iconFor(record.type);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Dismissible(
      key: ValueKey(record.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red.shade700,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete record?'),
            content: Text('Remove "${record.title}" permanently?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  'Delete',
                  style: TextStyle(color: Colors.red.shade400),
                ),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete(),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          record.title,
          style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: record.value != null
            ? Text(
                '${record.value}${record.unit != null ? ' ${record.unit}' : ''}',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (record.fileUrl != null)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(
                  Icons.attach_file,
                  size: 16,
                  color: colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            Text(
              DateFormat('MMM d, y').format(record.recordedAt.toLocal()),
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
