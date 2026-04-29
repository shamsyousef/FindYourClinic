import 'package:flutter/material.dart';

import '../../domain/entities/health_record_entity.dart';

class CategoryTabs extends StatelessWidget {
  final HealthRecordType? activeFilter;
  final ValueChanged<HealthRecordType?> onFilterChanged;

  const CategoryTabs({
    super.key,
    required this.activeFilter,
    required this.onFilterChanged,
  });

  static const _tabs = <String, HealthRecordType?>{
    'All': null,
    'Blood Tests': HealthRecordType.bloodTest,
    'Radiology': HealthRecordType.radiology,
    'Prescriptions': HealthRecordType.prescription,
    'Vitals': HealthRecordType.bloodPressure,
    'Lab Results': HealthRecordType.labResult,
    'Vaccination': HealthRecordType.vaccination,
    'Other': HealthRecordType.other,
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: _tabs.entries.map((entry) {
          final isSelected = activeFilter == entry.value;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(entry.key),
              selected: isSelected,
              onSelected: (_) => onFilterChanged(entry.value),
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }
}
