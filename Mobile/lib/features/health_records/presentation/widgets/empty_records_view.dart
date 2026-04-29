import 'package:flutter/material.dart';

class EmptyRecordsView extends StatelessWidget {
  const EmptyRecordsView({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 72,
              color: colorScheme.onSurface.withValues(alpha: 0.25),
            ),
            const SizedBox(height: 16),
            Text(
              'No records yet',
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tap + to add your first health record',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.35),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
