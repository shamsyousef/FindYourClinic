import '../../domain/entities/conversation.dart';

class ConversationModel extends Conversation {
  const ConversationModel({
    required super.id,
    required super.patientId,
    required super.doctorId,
    required super.lastMessageAt,
    super.lastMessage,
    super.counterpartyName,
    required super.unreadCount,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['conversationId'] as String,
      patientId: json['patientId'] as String,
      doctorId: json['doctorId'] as String,
      lastMessageAt: DateTime.parse(json['lastMessageAt'] as String),
      lastMessage: json['lastMessage'] as String?,
      counterpartyName: json['counterpartyName'] as String?,
      unreadCount: json['unreadCount'] as int,
    );
  }
}
