import '../../../../core/network/api_result.dart';
import '../entities/chat_message.dart';
import '../entities/conversation.dart';

abstract interface class IChatRepository {
  Future<ApiResult<List<Conversation>>> getConversations();
  Future<ApiResult<List<ChatMessage>>> getMessages(String conversationId);
  Future<ApiResult<Conversation>> startOrGetConversation(String doctorId);
  Future<ApiResult<ChatMessage>> sendMessage(String conversationId, String content);
  Future<ApiResult<void>> markConversationAsRead(String conversationId);

  // Real-time Streams
  Stream<ChatMessage> get onMessageReceived;
  Stream<String> get onConversationUpdated;
  Stream<String> get onMessagesRead;

  // Real-time connection management
  Future<void> joinConversation(String conversationId);
  Future<void> leaveConversation(String conversationId);
  Future<void> disconnect();
}
