// Domain entity for AI chat messages.
// Pure Dart — no Flutter imports.

class AiChatMessage {
  final String role; // "user" or "assistant"
  final String content;
  final DateTime createdAt;

  const AiChatMessage({
    required this.role,
    required this.content,
    required this.createdAt,
  });
}
