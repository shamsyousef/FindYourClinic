import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_styles.dart';

class GreetingHeader extends StatelessWidget {
  final VoidCallback? onNotificationTap;
  final int unreadNotificationCount;

  const GreetingHeader({
    super.key,
    this.onNotificationTap,
    this.unreadNotificationCount = 0,
  });

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$_greeting 👋',
                style: AppTextStyles.heading2.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                'How are you feeling today?',
                style: AppTextStyles.bodyMd.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onNotificationTap,
          icon: Badge(
            isLabelVisible: unreadNotificationCount > 0,
            label: Text(
              unreadNotificationCount > 99
                  ? '99+'
                  : unreadNotificationCount.toString(),
            ),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.notifications_outlined,
                  color: Colors.white, size: 24),
            ),
          ),
        ),
      ],
    );
  }
}
