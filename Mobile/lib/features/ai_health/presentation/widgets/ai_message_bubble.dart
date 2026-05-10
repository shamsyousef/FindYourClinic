import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/ai_chat_message.dart';

class AiMessageBubble extends StatelessWidget {
  final AiChatMessage message;

  /// Whether TTS is currently reading this message.
  final bool isSpeaking;

  /// Callback when the speaker icon is tapped (AI messages only).
  final VoidCallback? onSpeakerTap;

  const AiMessageBubble({
    super.key,
    required this.message,
    this.isSpeaking = false,
    this.onSpeakerTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAssistant = message.role == 'assistant';

    final timeStr = _formatTime(message.createdAt);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isAssistant ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (isAssistant) ...[
            _AvatarCircle(),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isAssistant
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.end,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.72,
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isAssistant
                        ? (isDark ? AppColors.darkSurface : Colors.white)
                        : (isDark
                            ? AppColors.primaryLight.withValues(alpha: 0.2)
                            : AppColors.primary.withValues(alpha: 0.12)),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(12),
                      topRight: const Radius.circular(12),
                      bottomLeft: Radius.circular(isAssistant ? 4 : 12),
                      bottomRight: Radius.circular(isAssistant ? 12 : 4),
                    ),
                    boxShadow: isAssistant
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    message.content,
                    style: AppTextStyles.bodyMd.copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      timeStr,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    // Speaker button for AI messages
                    if (isAssistant && onSpeakerTap != null) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: onSpeakerTap,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSpeaking
                                ? AppColors.primary.withValues(alpha: 0.15)
                                : Colors.transparent,
                          ),
                          child: Icon(
                            isSpeaking
                                ? Icons.volume_up_rounded
                                : Icons.volume_up_outlined,
                            size: 16,
                            color: isSpeaking
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}

class _AvatarCircle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [AppColors.gradientStart, AppColors.gradientMiddle],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(
        Icons.auto_awesome,
        color: Colors.white,
        size: 16,
      ),
    );
  }
}
