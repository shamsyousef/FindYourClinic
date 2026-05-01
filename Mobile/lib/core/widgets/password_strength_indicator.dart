import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Shared password strength widget showing checklist-style rules.
/// Used on SignUpScreen and ResetPasswordScreen.
class PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const PasswordStrengthIndicator({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();

    final rules = _buildRules(password);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Compact progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _strength(rules),
            minHeight: 4,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(_strengthColor(rules)),
          ),
        ),
        const SizedBox(height: 10),
        // Rule checklist
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: rules
              .map((r) => _RuleRow(label: r.label, isMet: r.isMet))
              .toList(),
        ),
      ],
    );
  }

  static List<_Rule> _buildRules(String pw) => [
        _Rule('8+ characters', pw.length >= 8),
        _Rule('Uppercase', RegExp(r'[A-Z]').hasMatch(pw)),
        _Rule('Number', RegExp(r'[0-9]').hasMatch(pw)),
        _Rule('Special char', RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(pw)),
      ];

  static double _strength(List<_Rule> rules) {
    final met = rules.where((r) => r.isMet).length;
    return met / rules.length;
  }

  static Color _strengthColor(List<_Rule> rules) {
    final s = _strength(rules);
    if (s <= 0.25) return AppColors.error;
    if (s <= 0.50) return Colors.orange;
    if (s <= 0.75) return Colors.amber;
    return AppColors.success;
  }
}

class _Rule {
  final String label;
  final bool isMet;
  const _Rule(this.label, this.isMet);
}

class _RuleRow extends StatelessWidget {
  final String label;
  final bool isMet;
  const _RuleRow({required this.label, required this.isMet});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isMet ? Icons.check_circle_rounded : Icons.cancel_rounded,
          size: 14,
          color: isMet ? AppColors.success : Colors.grey.shade400,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.labelSm.copyWith(
            color: isMet 
                ? Theme.of(context).colorScheme.onSurface 
                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
