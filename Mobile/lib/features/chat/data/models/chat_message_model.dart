import '../../../../core/utils/date_utils.dart';
import '../../domain/entities/chat_message.dart';

class ChatMessageModel extends ChatMessage {
  const ChatMessageModel({
    required super.id,
    required super.conversationId,
    required super.senderId,
    required super.senderName,
    required super.content,
    required super.sentAt,
    required super.isRead,
    super.type,
    super.mediaUrl,
    super.mediaThumbnailUrl,
    super.mediaDurationSeconds,
    super.replyToMessageId,
    super.replyPreview,
    super.reactions,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    final replyJson = json['replyPreview'] as Map<String, dynamic>?;
    final reactionsJson = json['reactions'] as List<dynamic>?;

    return ChatMessageModel(
      id: json['id'].toString(),
      conversationId: json['conversationId'].toString(),
      senderId: json['senderId'].toString(),
      senderName: (json['senderName'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      sentAt: parseServerDateTime(json['sentAt'].toString()),
      isRead: json['isRead'] as bool? ?? false,
      type: chatMessageTypeFromInt((json['type'] as num?)?.toInt() ?? 0),
      mediaUrl: json['mediaUrl'] as String?,
      mediaThumbnailUrl: json['mediaThumbnailUrl'] as String?,
      mediaDurationSeconds: (json['mediaDurationSeconds'] as num?)?.toInt(),
      replyToMessageId: json['replyToMessageId']?.toString(),
      replyPreview: replyJson == null
          ? null
          : ReplyPreview(
              id: replyJson['id'].toString(),
              senderId: replyJson['senderId'].toString(),
              content: (replyJson['content'] ?? '').toString(),
              type: chatMessageTypeFromInt(
                  (replyJson['type'] as num?)?.toInt() ?? 0),
            ),
      reactions: reactionsJson == null
          ? const []
          : reactionsJson
              .map((r) {
                final m = r as Map<String, dynamic>;
                return MessageReaction(
                  userId: m['userId'].toString(),
                  emoji: (m['emoji'] ?? '').toString(),
                );
              })
              .toList(growable: false),
    );
  }
}
