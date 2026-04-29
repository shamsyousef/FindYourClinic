import '../../../../core/network/api_client.dart';
import '../models/chat_message_model.dart';
import '../models/conversation_model.dart';

abstract class ChatRemoteDataSource {
  Future<List<ConversationModel>> getConversations();
  Future<List<ChatMessageModel>> getMessages(String conversationId);
  Future<ConversationModel> startOrGetConversation(String doctorId);
  Future<ChatMessageModel> sendMessage(String conversationId, String content);
  Future<void> markConversationAsRead(String conversationId);
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final ApiClient _apiClient;

  ChatRemoteDataSourceImpl(this._apiClient);

  @override
  Future<List<ConversationModel>> getConversations() async {
    final response = await _apiClient.dio.get('/api/messages/conversations');
    final data = response.data['data'] as List;
    return data.map((e) => ConversationModel.fromJson(e)).toList();
  }

  @override
  Future<List<ChatMessageModel>> getMessages(String conversationId) async {
    final response = await _apiClient.dio.get('/api/messages/conversations/$conversationId');
    final data = response.data['data'] as List;
    return data.map((e) => ChatMessageModel.fromJson(e)).toList();
  }

  @override
  Future<ConversationModel> startOrGetConversation(String doctorId) async {
    final response = await _apiClient.dio.post('/api/messages/conversations/$doctorId');
    return ConversationModel.fromJson(response.data['data']);
  }

  @override
  Future<ChatMessageModel> sendMessage(String conversationId, String content) async {
    final response = await _apiClient.dio.post(
      '/api/messages/conversations/$conversationId/send',
      data: {'content': content},
    );
    return ChatMessageModel.fromJson(response.data['data']);
  }

  @override
  Future<void> markConversationAsRead(String conversationId) async {
    await _apiClient.dio.put('/api/messages/conversations/$conversationId/read');
  }
}
