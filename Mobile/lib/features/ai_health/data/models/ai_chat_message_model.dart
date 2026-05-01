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
    final raw = json['createdAt'] as String;
    final normalized =
        (raw.endsWith('Z') || raw.contains('+')) ? raw : '${raw}Z';
    return AiChatMessageModel(
      role: json['role'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(normalized).toLocal(),
    );
  }

  AiChatMessage toEntity() => AiChatMessage(
        role: role,
        content: content,
        createdAt: createdAt,
      );
}
