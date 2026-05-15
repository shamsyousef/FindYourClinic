import 'package:equatable/equatable.dart';

enum ChatMessageType { text, image, video, voice }

ChatMessageType chatMessageTypeFromInt(int value) {
  switch (value) {
    case 1:
      return ChatMessageType.image;
    case 2:
      return ChatMessageType.video;
    case 3:
      return ChatMessageType.voice;
    default:
      return ChatMessageType.text;
  }
}

class ReactionUpdate extends Equatable {
  final String conversationId;
  final String messageId;
  final List<MessageReaction> reactions;

  const ReactionUpdate({
    required this.conversationId,
    required this.messageId,
    required this.reactions,
  });

  @override
  List<Object?> get props => [conversationId, messageId, reactions];
}

class MessageReaction extends Equatable {
  final String userId;
  final String emoji;

  const MessageReaction({required this.userId, required this.emoji});

  @override
  List<Object?> get props => [userId, emoji];
}

class ReplyPreview extends Equatable {
  final String id;
  final String senderId;
  final String content;
  final ChatMessageType type;

  const ReplyPreview({
    required this.id,
    required this.senderId,
    required this.content,
    required this.type,
  });

  @override
  List<Object?> get props => [id, senderId, content, type];
}

class ChatMessage extends Equatable {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime sentAt;
  final bool isRead;

  final ChatMessageType type;
  final String? mediaUrl;
  final String? mediaThumbnailUrl;
  final int? mediaDurationSeconds;

  final String? replyToMessageId;
  final ReplyPreview? replyPreview;

  final List<MessageReaction> reactions;

  // Local-only: set to true while an outgoing media upload is in flight.
  final bool isPending;
  // Local-only: set when an outgoing send failed and can be retried.
  final bool hasFailed;
  // Local-only: file path of media being uploaded (used by the optimistic bubble).
  final String? localMediaPath;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.sentAt,
    required this.isRead,
    this.type = ChatMessageType.text,
    this.mediaUrl,
    this.mediaThumbnailUrl,
    this.mediaDurationSeconds,
    this.replyToMessageId,
    this.replyPreview,
    this.reactions = const [],
    this.isPending = false,
    this.hasFailed = false,
    this.localMediaPath,
  });

  ChatMessage copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? senderName,
    String? content,
    DateTime? sentAt,
    bool? isRead,
    ChatMessageType? type,
    String? mediaUrl,
    String? mediaThumbnailUrl,
    int? mediaDurationSeconds,
    String? replyToMessageId,
    ReplyPreview? replyPreview,
    List<MessageReaction>? reactions,
    bool? isPending,
    bool? hasFailed,
    String? localMediaPath,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      content: content ?? this.content,
      sentAt: sentAt ?? this.sentAt,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaThumbnailUrl: mediaThumbnailUrl ?? this.mediaThumbnailUrl,
      mediaDurationSeconds: mediaDurationSeconds ?? this.mediaDurationSeconds,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      replyPreview: replyPreview ?? this.replyPreview,
      reactions: reactions ?? this.reactions,
      isPending: isPending ?? this.isPending,
      hasFailed: hasFailed ?? this.hasFailed,
      localMediaPath: localMediaPath ?? this.localMediaPath,
    );
  }

  @override
  List<Object?> get props => [
        id,
        conversationId,
        senderId,
        senderName,
        content,
        sentAt,
        isRead,
        type,
        mediaUrl,
        mediaThumbnailUrl,
        mediaDurationSeconds,
        replyToMessageId,
        replyPreview,
        reactions,
        isPending,
        hasFailed,
        localMediaPath,
      ];
}
