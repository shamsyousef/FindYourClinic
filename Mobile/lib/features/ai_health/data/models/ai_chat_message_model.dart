import '../../domain/entities/ai_chat_message.dart';

class AiChatMessageModel {
  final String role;
  final String content;
  final DateTime createdAt;

  const AiChatMessageModel({
    required this.role,
    required this.content,
    required this.createdAt,
  });

  factory AiChatMessageModel.fromJson(Map<String, dynamic> json) {
    return AiChatMessageModel(
      role: json['role'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
    );
  }

  AiChatMessage toEntity() => AiChatMessage(
        role: role,
        content: content,
        createdAt: createdAt,
      );
}
