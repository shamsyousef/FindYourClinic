import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../cubits/voice_assistant_state.dart';
import 'voice_assistant_card.dart';

/// State-driven inner content for [VoiceAssistantCard]. Kept in its own widget
/// so the [BlocBuilder] rebuild scope is small (per CLAUDE.md §B.7).
class VoiceAssistantCardContent extends StatelessWidget {
  final VoiceAssistantState state;
  const VoiceAssistantCardContent({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    // Exclude semantics if not idle. TTS handles the actual output, 
    // and STT transcript changes too rapidly for a screen reader.
    return ExcludeSemantics(
      excluding: state is! VoiceAssistantIdle,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _LeadingIcon(state: state),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Voice Assistant',
                  style: AppTextStyles.heading3.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                _StateMessage(state: state),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LeadingIcon extends StatefulWidget {
  final VoiceAssistantState state;
  const _LeadingIcon({required this.state});

  @override
  State<_LeadingIcon> createState() => _LeadingIconState();
}

class _LeadingIconState extends State<_LeadingIcon>
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
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.18).animate(
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
    final state = widget.state;
    final iconData = switch (state) {
      VoiceAssistantSpoken() => Icons.volume_up_rounded,
      VoiceAssistantError() => Icons.mic_off_rounded,
      VoiceAssistantThinking() => Icons.hourglass_top_rounded,
      _ => Icons.mic_rounded,
    };
    final extraScale = state is VoiceAssistantListening
        ? state.soundLevel * 0.25
        : 0.0;

    final circle = Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.gradientStart, AppColors.gradientEnd],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 14,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(iconData, color: Colors.white, size: 30),
    );

    if (state is VoiceAssistantListening) {
      return RepaintBoundary(
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (_, child) => Transform.scale(
            scale: _pulseAnimation.value + extraScale,
            child: child,
          ),
          child: circle,
        ),
      );
    }
    return circle;
  }
}

class _StateMessage extends StatelessWidget {
  final VoiceAssistantState state;
  const _StateMessage({required this.state});

  @override
  Widget build(BuildContext context) {
    final s = state;
    if (s is VoiceAssistantIdle) {
      return Text(
        'Tap anywhere to talk',
        style: AppTextStyles.bodyMd.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      );
    }
    if (s is VoiceAssistantListening) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Listening…',
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (s.partialTranscript.isNotEmpty) ...[
            const SizedBox(height: 4),
            VoiceAssistantCaption(s.partialTranscript),
          ],
        ],
      );
    }
    if (s is VoiceAssistantThinking) {
      return Row(
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Got it…',
              style: AppTextStyles.bodyMd
                  .copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      );
    }
    if (s is VoiceAssistantSpoken) {
      return VoiceAssistantCaption(s.spokenText);
    }
    if (s is VoiceAssistantError) {
      return Text(
        s.message,
        style: AppTextStyles.bodySm.copyWith(color: AppColors.error),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      );
    }
    return const SizedBox.shrink();
  }
}
