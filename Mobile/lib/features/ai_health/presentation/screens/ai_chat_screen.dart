import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/services/tts_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../cubits/ai_chat_cubit.dart';
import '../cubits/ai_chat_state.dart';
import '../cubits/voice_input_cubit.dart';
import '../cubits/voice_input_state.dart';
import '../widgets/ai_message_bubble.dart';
import '../widgets/voice_recording_indicator.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final VoiceInputCubit _voiceCubit;
  late final TtsService _ttsService;

  @override
  void initState() {
    super.initState();
    _voiceCubit = sl<VoiceInputCubit>();
    _ttsService = sl<TtsService>();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _voiceCubit.close();
    _ttsService.stop();
    super.dispose();
  }

  void _sendMessage() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    _inputController.clear();
    context.read<AiChatCubit>().sendMessage(text);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _voiceCubit),
      ],
      child: Scaffold(
        backgroundColor: isDark
            ? AppColors.darkBackground
            : AppColors.scaffoldLight,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.gradientStart, AppColors.gradientMiddle],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () {
              _ttsService.stop();
              context.pop();
            },
          ),
          title: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AI Health Assistant',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Voice enabled • Gemini AI',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            _buildDisclaimer(isDark),
            Expanded(
              child: BlocConsumer<AiChatCubit, AiChatState>(
                listener: (context, state) {
                  if (state is AiChatLoaded || state is AiChatSending) {
                    _scrollToBottom();
                  }
                  // Auto-read AI response aloud
                  if (state is AiChatLoaded && state.messages.isNotEmpty) {
                    final lastMsg = state.messages.last;
                    if (lastMsg.role == 'assistant') {
                      _ttsService.speak(lastMsg.content,
                          messageId: lastMsg.createdAt.toIso8601String());
                    }
                  }
                },
                builder: (context, state) {
                  if (state is AiChatLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary),
                    );
                  }

                  if (state is AiChatError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: AppColors.error,
                              size: 48,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              state.message,
                              style: AppTextStyles.bodyMd.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton(
                              onPressed: () =>
                                  context.read<AiChatCubit>().loadHistory(),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(
                                    color: AppColors.primary),
                              ),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final messages = switch (state) {
                    AiChatLoaded(:final messages) => messages,
                    AiChatSending(:final messages) => messages,
                    _ => <dynamic>[],
                  };
                  final isSending = state is AiChatSending;

                  return StreamBuilder<bool>(
                    stream: _ttsService.isSpeaking,
                    initialData: false,
                    builder: (context, snapshot) {
                      final speakingMessageId =
                          _ttsService.currentMessageId;

                      return ListView(
                        controller: _scrollController,
                        padding: const EdgeInsets.only(top: 8, bottom: 12),
                        children: [
                          if (messages.isEmpty && !isSending)
                            _buildWelcomeArea(isDark),
                          ...messages.map((msg) => AiMessageBubble(
                                message: msg,
                                isSpeaking: msg.role == 'assistant' &&
                                    speakingMessageId ==
                                        msg.createdAt.toIso8601String(),
                                onSpeakerTap: msg.role == 'assistant'
                                    ? () => _onSpeakerTap(msg.content,
                                        msg.createdAt.toIso8601String())
                                    : null,
                                // TASK 3.2 — Find doctors CTA
                                onFindDoctors: msg.role == 'assistant'
                                    ? () => context.pushNamed('search')
                                    : null,
                              )),
                          if (isSending) _buildTypingIndicator(isDark),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            // Voice recording indicator OR text input bar
            BlocConsumer<VoiceInputCubit, VoiceInputState>(
              listener: (context, state) {
                if (state is VoiceResult) {
                  // Auto-send the recognized text
                  if (state.text.isNotEmpty) {
                    context.read<AiChatCubit>().sendMessage(state.text);
                    _scrollToBottom();
                  }
                }
                if (state is VoiceError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is VoiceListening) {
                  return VoiceRecordingIndicator(
                    soundLevel: state.soundLevel,
                    transcript: state.transcript,
                    onStop: () => _voiceCubit.stopListening(),
                    onCancel: () => _voiceCubit.cancelListening(),
                  );
                }
                return _buildInputBar(isDark);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _onSpeakerTap(String text, String messageId) {
    if (_ttsService.isSpeakingNow &&
        _ttsService.currentMessageId == messageId) {
      _ttsService.stop();
    } else {
      _ttsService.speak(text, messageId: messageId);
    }
  }

  Widget _buildDisclaimer(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D2500) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(8),
        border: const Border(
          left: BorderSide(color: AppColors.warning, width: 3),
        ),
      ),
      child: Text(
        '⚠ AI suggestions are not a substitute for professional medical advice.',
        style: TextStyle(
          fontSize: 11,
          color: isDark ? const Color(0xFFD4A017) : const Color(0xFF92400E),
        ),
      ),
    );
  }

  Widget _buildWelcomeArea(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.mic, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                'Tap the mic to speak, or type your message',
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              'I have a headache',
              'Find a cardiologist',
              'Check my symptoms',
              'Health tips',
            ].map((text) => _buildQuickReplyChip(text)).toList(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildQuickReplyChip(String text) {
    return OutlinedButton(
      onPressed: () {
        context.read<AiChatCubit>().sendMessage(text);
        _scrollToBottom();
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      ),
      child: Text(text, style: AppTextStyles.bodySm),
    );
  }

  Widget _buildTypingIndicator(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Container(
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
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
                bottomRight: Radius.circular(12),
                bottomLeft: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              '...',
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.textSecondary,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        border: const Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _inputController,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                onChanged: (_) => setState(() {}),
                style: AppTextStyles.bodyMd.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Type your message...',
                  hintStyle: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.textHint,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? AppColors.darkSurfaceAlt
                      : AppColors.scaffoldLight,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),

            // ─── Mic Button (shown when text field is empty) ───
            if (_inputController.text.trim().isEmpty)
              GestureDetector(
                onTap: () => _voiceCubit.startListening(),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.1),
                  ),
                  child: const Icon(
                    Icons.mic_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
              ),

            // ─── Send Button (shown when text field has content) ───
            if (_inputController.text.trim().isNotEmpty)
              GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.gradientMiddle,
                        AppColors.gradientEnd,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(
                    Icons.send,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
