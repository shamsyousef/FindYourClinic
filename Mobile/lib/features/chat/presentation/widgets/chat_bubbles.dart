import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/chat_message.dart';
import 'fullscreen_image_viewer.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final VoidCallback? onLongPress;
  final VoidCallback? onReactTap;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.onLongPress,
    this.onReactTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bubbleColor = isMe
        ? AppColors.primary
        : (isDark ? AppColors.darkSurface : AppColors.surface);
    final textColor = isMe
        ? Colors.white
        : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary);
    final timeColor = isMe
        ? Colors.white70
        : (isDark ? Colors.white54 : Colors.black45);

    final radius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(isMe ? 18 : 4),
      bottomRight: Radius.circular(isMe ? 4 : 18),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onLongPress: onLongPress,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.78,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: radius,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: radius,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (message.replyPreview != null)
                          _ReplyPreviewStrip(
                            preview: message.replyPreview!,
                            onLightBubble: !isMe,
                          ),
                        _BubbleBody(
                          message: message,
                          isMe: isMe,
                          textColor: textColor,
                          timeColor: timeColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (message.reactions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
                child: _ReactionChips(
                  reactions: message.reactions,
                  onTap: onReactTap,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BubbleBody extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final Color textColor;
  final Color timeColor;

  const _BubbleBody({
    required this.message,
    required this.isMe,
    required this.textColor,
    required this.timeColor,
  });

  @override
  Widget build(BuildContext context) {
    switch (message.type) {
      case ChatMessageType.image:
        return _ImageContent(
          message: message,
          isMe: isMe,
          textColor: textColor,
          timeColor: timeColor,
        );
      case ChatMessageType.video:
        return _VideoContent(
          message: message,
          isMe: isMe,
          textColor: textColor,
          timeColor: timeColor,
        );
      case ChatMessageType.voice:
        return Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
          child: _VoiceContent(
            message: message,
            isMe: isMe,
            textColor: textColor,
            timeColor: timeColor,
          ),
        );
      case ChatMessageType.text:
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
          child: _TextContent(
            message: message,
            isMe: isMe,
            textColor: textColor,
            timeColor: timeColor,
          ),
        );
    }
  }
}

class _TextContent extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final Color textColor;
  final Color timeColor;

  const _TextContent({
    required this.message,
    required this.isMe,
    required this.textColor,
    required this.timeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Text(
            message.content,
            style: TextStyle(color: textColor, fontSize: 15, height: 1.3),
          ),
        ),
        _StatusRow(message: message, isMe: isMe, timeColor: timeColor),
      ],
    );
  }
}

class _ImageContent extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final Color textColor;
  final Color timeColor;

  const _ImageContent({
    required this.message,
    required this.isMe,
    required this.textColor,
    required this.timeColor,
  });

  @override
  Widget build(BuildContext context) {
    final url = message.mediaUrl;
    final localPath = message.localMediaPath;
    final heroTag = 'chat-image-${message.id}';

    final image = ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (url != null)
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => FullscreenImageViewer(
                      imageUrl: url,
                      heroTag: heroTag,
                    ),
                  ),
                ),
                child: Hero(
                  tag: heroTag,
                  child: CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => Container(color: Colors.black12),
                    errorWidget: (_, _, _) =>
                        const Icon(Icons.broken_image_outlined),
                  ),
                ),
              )
            else if (localPath != null)
              Image.file(File(localPath), fit: BoxFit.cover)
            else
              Container(color: Colors.black12),
            if (message.isPending)
              Container(
                color: Colors.black38,
                alignment: Alignment.center,
                child: const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.white,
                  ),
                ),
              ),
            if (message.hasFailed)
              Container(
                color: Colors.black54,
                alignment: Alignment.center,
                child: const Icon(Icons.error_outline,
                    color: Colors.white, size: 36),
              ),
          ],
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        image,
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (message.content.isNotEmpty)
                Flexible(
                  child: Text(
                    message.content,
                    style: TextStyle(color: textColor, fontSize: 14),
                  ),
                ),
              const SizedBox(width: 8),
              _StatusRow(message: message, isMe: isMe, timeColor: timeColor),
            ],
          ),
        ),
      ],
    );
  }
}

class _VideoContent extends StatefulWidget {
  final ChatMessage message;
  final bool isMe;
  final Color textColor;
  final Color timeColor;

  const _VideoContent({
    required this.message,
    required this.isMe,
    required this.textColor,
    required this.timeColor,
  });

  @override
  State<_VideoContent> createState() => _VideoContentState();
}

class _VideoContentState extends State<_VideoContent> {
  @override
  Widget build(BuildContext context) {
    final thumb = widget.message.mediaThumbnailUrl ?? widget.message.mediaUrl;
    final duration = widget.message.mediaDurationSeconds;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: 16 / 10,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (thumb != null)
                CachedNetworkImage(
                  imageUrl: thumb,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => Container(color: Colors.black54),
                  errorWidget: (_, _, _) =>
                      Container(color: Colors.black87),
                )
              else
                Container(color: Colors.black87),
              GestureDetector(
                onTap: widget.message.mediaUrl == null
                    ? null
                    : () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => _VideoPlayerScreen(
                              videoUrl: widget.message.mediaUrl!,
                            ),
                          ),
                        ),
                child: Container(
                  color: Colors.black26,
                  alignment: Alignment.center,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow_rounded,
                        color: Colors.white, size: 36),
                  ),
                ),
              ),
              if (widget.message.isPending)
                Container(
                  color: Colors.black54,
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(color: Colors.white),
                ),
              if (duration != null)
                Positioned(
                  left: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _formatDuration(duration),
                      style: const TextStyle(
                          color: Colors.white, fontSize: 11),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.message.content.isNotEmpty)
                Flexible(
                  child: Text(
                    widget.message.content,
                    style:
                        TextStyle(color: widget.textColor, fontSize: 14),
                  ),
                ),
              const SizedBox(width: 8),
              _StatusRow(
                message: widget.message,
                isMe: widget.isMe,
                timeColor: widget.timeColor,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  const _VideoPlayerScreen({required this.videoUrl});

  @override
  State<_VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<_VideoPlayerScreen> {
  late final VideoPlayerController _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _controller =
        VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    _controller.initialize().then((_) {
      if (!mounted) return;
      setState(() => _ready = true);
      _controller.play();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black54,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: GestureDetector(
        onTap: () {
          setState(() {
            _controller.value.isPlaying
                ? _controller.pause()
                : _controller.play();
          });
        },
        child: Center(
          child: _ready
              ? AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      VideoPlayer(_controller),
                      if (!_controller.value.isPlaying)
                        Container(
                          width: 70,
                          height: 70,
                          decoration: const BoxDecoration(
                            color: Colors.black45,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.play_arrow,
                              color: Colors.white, size: 48),
                        ),
                    ],
                  ),
                )
              : const CircularProgressIndicator(color: Colors.white),
        ),
      ),
    );
  }
}

class _VoiceContent extends StatefulWidget {
  final ChatMessage message;
  final bool isMe;
  final Color textColor;
  final Color timeColor;

  const _VoiceContent({
    required this.message,
    required this.isMe,
    required this.textColor,
    required this.timeColor,
  });

  @override
  State<_VoiceContent> createState() => _VoiceContentState();
}

class _VoiceContentState extends State<_VoiceContent> {
  AudioPlayer? _player;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  AudioPlayer get _ensurePlayer {
    final p = _player ??= AudioPlayer();
    return p;
  }

  Future<void> _togglePlay() async {
    final url = widget.message.mediaUrl ?? widget.message.localMediaPath;
    if (url == null) return;

    final player = _ensurePlayer;
    if (_isPlaying) {
      await player.pause();
      return;
    }

    if (player.duration == null) {
      try {
        if (widget.message.mediaUrl != null) {
          await player.setUrl(widget.message.mediaUrl!);
        } else {
          await player.setFilePath(widget.message.localMediaPath!);
        }
        player.durationStream.listen((d) {
          if (mounted && d != null) setState(() => _duration = d);
        });
        player.positionStream.listen((p) {
          if (mounted) setState(() => _position = p);
        });
        player.playerStateStream.listen((s) {
          if (!mounted) return;
          setState(() => _isPlaying = s.playing);
          if (s.processingState == ProcessingState.completed) {
            player.seek(Duration.zero);
            player.pause();
            setState(() => _position = Duration.zero);
          }
        });
      } catch (_) {
        return;
      }
    }
    player.play();
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = _duration.inSeconds > 0
        ? _duration.inSeconds
        : (widget.message.mediaDurationSeconds ?? 0);
    final played = _position.inSeconds;
    final progress = total == 0 ? 0.0 : (played / total).clamp(0.0, 1.0);
    final iconBg =
        widget.isMe ? Colors.white24 : AppColors.primary.withValues(alpha: 0.12);
    final iconColor = widget.isMe ? Colors.white : AppColors.primary;

    return SizedBox(
      width: 220,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          InkWell(
            onTap: widget.message.isPending ? null : _togglePlay,
            customBorder: const CircleBorder(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconBg,
              ),
              child: widget.message.isPending
                  ? Padding(
                      padding: const EdgeInsets.all(8),
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: iconColor,
                      ),
                    )
                  : Icon(
                      _isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: iconColor,
                      size: 24,
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: widget.isMe
                      ? Colors.white24
                      : Colors.black.withValues(alpha: 0.08),
                  valueColor: AlwaysStoppedAnimation(
                    widget.isMe ? Colors.white : AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      _formatDuration(played > 0 ? played : total),
                      style: TextStyle(color: widget.timeColor, fontSize: 11),
                    ),
                    const Spacer(),
                    _StatusRow(
                      message: widget.message,
                      isMe: widget.isMe,
                      timeColor: widget.timeColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final Color timeColor;

  const _StatusRow({
    required this.message,
    required this.isMe,
    required this.timeColor,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat.jm();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          fmt.format(message.sentAt.toLocal()),
          style: TextStyle(color: timeColor, fontSize: 11),
        ),
        if (isMe) ...[
          const SizedBox(width: 4),
          if (message.isPending)
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: timeColor,
              ),
            )
          else if (message.hasFailed)
            Icon(Icons.error_outline, size: 14, color: Colors.red[200])
          else
            Icon(
              message.isRead ? Icons.done_all : Icons.check,
              size: 15,
              color: message.isRead ? Colors.lightBlueAccent : timeColor,
            ),
        ],
      ],
    );
  }
}

class _ReplyPreviewStrip extends StatelessWidget {
  final ReplyPreview preview;
  final bool onLightBubble;

  const _ReplyPreviewStrip({
    required this.preview,
    required this.onLightBubble,
  });

  @override
  Widget build(BuildContext context) {
    final bg = onLightBubble
        ? Colors.black.withValues(alpha: 0.04)
        : Colors.white.withValues(alpha: 0.18);
    final textColor = onLightBubble ? AppColors.textPrimary : Colors.white;
    final accent =
        onLightBubble ? AppColors.primary : Colors.white;

    final summary = switch (preview.type) {
      ChatMessageType.image => '📷 Photo',
      ChatMessageType.video => '🎥 Video',
      ChatMessageType.voice => '🎙 Voice message',
      ChatMessageType.text =>
        preview.content.isEmpty ? 'Message' : preview.content,
    };

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: accent, width: 3)),
      ),
      child: Text(
        summary,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: textColor, fontSize: 12),
      ),
    );
  }
}

class _ReactionChips extends StatelessWidget {
  final List<MessageReaction> reactions;
  final VoidCallback? onTap;

  const _ReactionChips({required this.reactions, this.onTap});

  @override
  Widget build(BuildContext context) {
    final grouped = <String, int>{};
    for (final r in reactions) {
      grouped[r.emoji] = (grouped[r.emoji] ?? 0) + 1;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceAlt : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: grouped.entries
              .map(
                (e) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Text(
                    e.value > 1 ? '${e.key} ${e.value}' : e.key,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

String _formatDuration(int seconds) {
  if (seconds <= 0) return '0:00';
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}
