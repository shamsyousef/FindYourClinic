import 'package:flutter/material.dart';

import '../../domain/entities/health_record_entity.dart';

/// Pinned red-accented banner showing the patient's active allergies.
/// Renders nothing if [allergies] is empty.
class AllergyAlertBanner extends StatelessWidget {
  final List<HealthRecordEntity> allergies;

  const AllergyAlertBanner({super.key, required this.allergies});

  @override
  Widget build(BuildContext context) {
    if (allergies.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.red.shade900.withValues(alpha: 0.3)
            : Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.red.shade300,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded,
              color: Colors.red.shade600, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Allergy Alert',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: allergies
                      .map((a) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Text(
                              a.title,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.red.shade800,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
