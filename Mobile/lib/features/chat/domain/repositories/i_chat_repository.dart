import '../../../../core/network/api_result.dart';
import '../entities/chat_message.dart';
import '../entities/conversation.dart';

abstract interface class IChatRepository {
  Future<ApiResult<List<Conversation>>> getConversations();
  Future<ApiResult<List<ChatMessage>>> getMessages(String conversationId);
  Future<ApiResult<Conversation>> startOrGetConversation(String doctorId);

  Future<ApiResult<ChatMessage>> sendMessage(
    String conversationId,
    String content, {
    String? replyToMessageId,
  });
  Future<ApiResult<ChatMessage>> sendImage(
    String conversationId,
    String filePath, {
    String? caption,
    String? replyToMessageId,
  });
  Future<ApiResult<ChatMessage>> sendVideo(
    String conversationId,
    String filePath, {
    String? caption,
    String? replyToMessageId,
  });
  Future<ApiResult<ChatMessage>> sendVoice(
    String conversationId,
    String filePath, {
    int? durationSeconds,
    String? replyToMessageId,
  });

  Future<ApiResult<List<MessageReaction>>> reactToMessage(
    String messageId,
    String emoji,
  );

  Future<ApiResult<void>> markConversationAsRead(String conversationId);

  // Real-time Streams
  Stream<ChatMessage> get onMessageReceived;
  Stream<String> get onConversationUpdated;
  Stream<String> get onMessagesRead;
  Stream<bool> get onTyping;
  Stream<ReactionUpdate> get onReactionUpdated;

  // Real-time connection management
  Future<void> joinConversation(String conversationId);
  Future<void> leaveConversation(String conversationId);
  Future<void> disconnect();

  Future<void> sendTypingStarted(String conversationId);
  Future<void> sendTypingStopped(String conversationId);
}
