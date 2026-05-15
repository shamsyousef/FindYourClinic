import 'package:flutter/material.dart';

/// Horizontal step indicator with numbered circles connected by lines.
/// Active: filled primary color. Done: checkmark. Future: outlined.
class StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String> stepLabels;

  const StepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.stepLabels = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final onPrimary = theme.colorScheme.onPrimary;
    final surfaceVariant = theme.colorScheme.surfaceContainerHighest;
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: List.generate(totalSteps * 2 - 1, (i) {
          if (i.isOdd) {
            // Connector line
            final stepIndex = i ~/ 2;
            final isDone = stepIndex < currentStep;
            return Expanded(
              child: Container(
                height: 2,
                color: isDone ? primary : surfaceVariant,
              ),
            );
          }
          final stepIndex = i ~/ 2;
          final isDone = stepIndex < currentStep;
          final isActive = stepIndex == currentStep;
          final label =
              stepLabels.length > stepIndex ? stepLabels[stepIndex] : null;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone || isActive ? primary : Colors.transparent,
                  border: Border.all(
                    color: isDone || isActive ? primary : surfaceVariant,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: isDone
                      ? Icon(Icons.check, size: 16, color: onPrimary)
                      : Text(
                          '${stepIndex + 1}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isActive ? onPrimary : onSurfaceVariant,
                          ),
                        ),
                ),
              ),
              if (label != null) ...[
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: isActive ? primary : onSurfaceVariant,
                    fontWeight:
                        isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ],
          );
        }),
      ),
    );
  }
}
