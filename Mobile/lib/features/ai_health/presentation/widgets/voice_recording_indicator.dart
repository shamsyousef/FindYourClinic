import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Pulsing microphone indicator shown during voice recording.
class VoiceRecordingIndicator extends StatefulWidget {
  final double soundLevel;
  final String transcript;
  final VoidCallback onStop;
  final VoidCallback onCancel;

  const VoiceRecordingIndicator({
    super.key,
    required this.soundLevel,
    required this.transcript,
    required this.onStop,
    required this.onCancel,
  });

  @override
  State<VoiceRecordingIndicator> createState() =>
      _VoiceRecordingIndicatorState();
}

class _VoiceRecordingIndicatorState extends State<VoiceRecordingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        border: const Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Transcript
            if (widget.transcript.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  widget.transcript,
                  style: TextStyle(
                    fontSize: 15,
                    fontStyle: FontStyle.italic,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Cancel button
                IconButton(
                  onPressed: widget.onCancel,
                  icon: Icon(
                    Icons.close,
                    color: AppColors.error,
                  ),
                  tooltip: 'Cancel',
                ),
                const SizedBox(width: 16),

                // Pulsing mic
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    final scale = _pulseAnimation.value +
                        (widget.soundLevel * 0.3);
                    return Transform.scale(
                      scale: scale,
                      child: child,
                    );
                  },
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [AppColors.gradientStart, AppColors.gradientEnd],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.mic,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Stop button
                IconButton(
                  onPressed: widget.onStop,
                  icon: Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                    size: 28,
                  ),
                  tooltip: 'Done',
                ),
              ],
            ),

            const SizedBox(height: 4),
            Text(
              'Listening...',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
