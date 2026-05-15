import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/chat_message.dart';

class ChatInputBar extends StatefulWidget {
  final ChatMessage? replyingTo;
  final VoidCallback onCancelReply;
  final ValueChanged<String> onSendText;
  final ValueChanged<String> onSendImage;
  final ValueChanged<String> onSendVideo;
  final void Function(String filePath, int durationSeconds) onSendVoice;
  final VoidCallback onTypingChanged;

  const ChatInputBar({
    super.key,
    required this.replyingTo,
    required this.onCancelReply,
    required this.onSendText,
    required this.onSendImage,
    required this.onSendVideo,
    required this.onSendVoice,
    required this.onTypingChanged,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _recorder = AudioRecorder();
  final _picker = ImagePicker();

  bool _hasText = false;
  bool _isRecording = false;
  bool _startingRecord = false;
  bool _cancelPendingStart = false;
  DateTime? _recordStart;
  String? _recordingPath;
  double _dragOffset = 0.0;
  bool _isCancelled = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final newHas = _controller.text.trim().isNotEmpty;
      if (newHas != _hasText) {
        setState(() => _hasText = newHas);
      }
      widget.onTypingChanged();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _recorder.dispose();
    super.dispose();
  }

  void _sendText() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSendText(text);
    _controller.clear();
  }

  Future<void> _openAttachments() async {
    HapticFeedback.selectionClick();
    final action = await showModalBottomSheet<_AttachAction>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Photo from gallery'),
              onTap: () => Navigator.pop(ctx, _AttachAction.photoGallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take photo'),
              onTap: () => Navigator.pop(ctx, _AttachAction.photoCamera),
            ),
            ListTile(
              leading: const Icon(Icons.videocam_outlined),
              title: const Text('Video from gallery'),
              onTap: () => Navigator.pop(ctx, _AttachAction.videoGallery),
            ),
          ],
        ),
      ),
    );
    if (action == null || !mounted) return;

    XFile? file;
    switch (action) {
      case _AttachAction.photoGallery:
        file = await _picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
        );
        if (file != null) widget.onSendImage(file.path);
        break;
      case _AttachAction.photoCamera:
        file = await _picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
        );
        if (file != null) widget.onSendImage(file.path);
        break;
      case _AttachAction.videoGallery:
        file = await _picker.pickVideo(source: ImageSource.gallery);
        if (file != null) widget.onSendVideo(file.path);
        break;
    }
  }

  Future<void> _startRecording() async {
    if (_startingRecord || _isRecording) return;
    _startingRecord = true;
    _cancelPendingStart = false;
    _isCancelled = false;
    _dragOffset = 0.0;

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      _startingRecord = false;
      return;
    }
    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    try {
      await _recorder.start(const RecordConfig(), path: path);
    } catch (_) {
      _startingRecord = false;
      return;
    }

    HapticFeedback.mediumImpact();
    final start = DateTime.now();
    _startingRecord = false;

    // If the user already released the gesture while start() was awaiting,
    // immediately stop and (optionally) send.
    if (_cancelPendingStart) {
      _cancelPendingStart = false;
      final stoppedPath = await _recorder.stop();
      final secs = DateTime.now().difference(start).inSeconds;
      if (secs >= 1) {
        widget.onSendVoice(stoppedPath ?? path, secs);
      }
      return;
    }

    if (!mounted) return;
    setState(() {
      _isRecording = true;
      _recordingPath = path;
      _recordStart = start;
    });
  }

  Future<void> _stopRecording({required bool send}) async {
    // If start() is still in flight, defer the stop until it finishes.
    if (_startingRecord) {
      _cancelPendingStart = !send; // if not sending, just discard
      if (send) {
        // Wait briefly for start() to complete, then stop+send.
        while (_startingRecord) {
          await Future<void>.delayed(const Duration(milliseconds: 30));
        }
      } else {
        return;
      }
    }
    if (!_isRecording) return;

    final pathFromRecorder = await _recorder.stop();
    final start = _recordStart;
    final path = pathFromRecorder ?? _recordingPath;
    if (mounted) {
      setState(() {
        _isRecording = false;
        _recordStart = null;
        _recordingPath = null;
        _dragOffset = 0.0;
      });
    } else {
      _isRecording = false;
      _recordStart = null;
      _recordingPath = null;
      _dragOffset = 0.0;
    }
    if (send && path != null && start != null) {
      final secs = DateTime.now().difference(start).inSeconds;
      if (secs >= 1) {
        widget.onSendVoice(path, secs);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inputBg = isDark ? AppColors.darkSurface : Colors.white;
    final iconColor = isDark ? Colors.white70 : Colors.black54;

    return Container(
      color: isDark ? AppColors.darkBackground : AppColors.scaffoldLight,
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        top: 8,
        bottom: 8 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.replyingTo != null)
            _ReplyBanner(
              message: widget.replyingTo!,
              onCancel: widget.onCancelReply,
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _isRecording
                    ? _RecordingBanner(
                        startedAt: _recordStart ?? DateTime.now(),
                        dragOffset: _dragOffset,
                        inputBg: inputBg,
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: inputBg,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.add_circle_outline_rounded,
                                color: iconColor,
                              ),
                              onPressed: _openAttachments,
                              tooltip: 'Attach',
                            ),
                            Expanded(
                              child: TextField(
                                controller: _controller,
                                focusNode: _focusNode,
                                minLines: 1,
                                maxLines: 5,
                                textInputAction: TextInputAction.send,
                                onSubmitted: (_) => _sendText(),
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Message',
                                  hintStyle: TextStyle(color: iconColor),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 4,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(width: 8),
              Transform.translate(
                offset: Offset(_dragOffset, 0),
                child: Transform.scale(
                  scale: _isRecording ? 1.2 : 1.0,
                  child: _SendOrMicButton(
                    hasText: _hasText,
                    onSend: _sendText,
                    onStartRecord: _startRecording,
                    onRecordMove: (details) {
                      if (!_isRecording || _isCancelled) return;
                      setState(() {
                        final dx = details.offsetFromOrigin.dx;
                        if (dx < 0) {
                          _dragOffset = dx;
                          if (_dragOffset < -100) {
                            _isCancelled = true;
                            _dragOffset = 0.0;
                            _stopRecording(send: false);
                            HapticFeedback.lightImpact();
                          }
                        }
                      });
                    },
                    onStopRecord: () {
                      if (!_isCancelled) {
                        _stopRecording(send: true);
                      }
                      setState(() {
                        _dragOffset = 0.0;
                        _isCancelled = false;
                      });
                    },
                    onCancelRecord: () {
                      if (!_isCancelled) {
                        _stopRecording(send: false);
                      }
                      setState(() {
                        _dragOffset = 0.0;
                        _isCancelled = false;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SendOrMicButton extends StatelessWidget {
  final bool hasText;
  final VoidCallback onSend;
  final VoidCallback onStartRecord;
  final VoidCallback onStopRecord;
  final ValueChanged<LongPressMoveUpdateDetails>? onRecordMove;
  final VoidCallback onCancelRecord;

  const _SendOrMicButton({
    required this.hasText,
    required this.onSend,
    required this.onStartRecord,
    required this.onStopRecord,
    required this.onRecordMove,
    required this.onCancelRecord,
  });

  @override
  Widget build(BuildContext context) {
    if (hasText) {
      return _CircleButton(icon: Icons.send_rounded, onTap: onSend);
    }
    return GestureDetector(
      onLongPressStart: (_) => onStartRecord(),
      onLongPressMoveUpdate: onRecordMove,
      onLongPressEnd: (_) => onStopRecord(),
      onLongPressCancel: onCancelRecord,
      child: const _CircleButton(icon: Icons.mic_rounded),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _CircleButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primaryLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}

class _ReplyBanner extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback onCancel;

  const _ReplyBanner({required this.message, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final summary = switch (message.type) {
      ChatMessageType.image => '📷 Photo',
      ChatMessageType.video => '🎥 Video',
      ChatMessageType.voice => '🎙 Voice message',
      ChatMessageType.text =>
        message.content.isEmpty ? 'Message' : message.content,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceAlt : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: const Border(
          left: BorderSide(color: AppColors.primary, width: 3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Replying',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  summary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: onCancel,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _RecordingBanner extends StatefulWidget {
  final DateTime startedAt;
  final double dragOffset;
  final Color inputBg;

  const _RecordingBanner({
    required this.startedAt,
    required this.dragOffset,
    required this.inputBg,
  });

  @override
  State<_RecordingBanner> createState() => _RecordingBannerState();
}

class _RecordingBannerState extends State<_RecordingBanner>
    with SingleTickerProviderStateMixin {
  late Stream<DateTime> _ticker;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _ticker = Stream.periodic(
      const Duration(milliseconds: 500),
      (_) => DateTime.now(),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String _format(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final opacity = (1.0 - (widget.dragOffset.abs() / 100.0)).clamp(0.0, 1.0);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: widget.inputBg,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          FadeTransition(
            opacity: _pulseController,
            child: const Icon(Icons.mic, color: Colors.redAccent, size: 20),
          ),
          const SizedBox(width: 8),
          StreamBuilder<DateTime>(
            stream: _ticker,
            builder: (_, _) {
              final d = DateTime.now().difference(widget.startedAt);
              return Text(
                _format(d),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              );
            },
          ),
          const Spacer(),
          Opacity(
            opacity: opacity,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.chevron_left,
                  color: isDark ? Colors.white54 : Colors.black45,
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  'Slide to cancel',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                ),
                const SizedBox(
                  width: 16,
                ), // space so it's not right up against the mic
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _AttachAction { photoGallery, photoCamera, videoGallery }
