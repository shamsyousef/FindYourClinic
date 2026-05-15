import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../models/chat_message_model.dart';
import '../models/conversation_model.dart';

abstract class ChatRemoteDataSource {
  Future<List<ConversationModel>> getConversations();
  Future<List<ChatMessageModel>> getMessages(String conversationId);
  Future<ConversationModel> startOrGetConversation(String doctorId);
  Future<ChatMessageModel> sendMessage(
    String conversationId,
    String content, {
    String? replyToMessageId,
  });
  Future<ChatMessageModel> sendImage(
    String conversationId,
    String filePath, {
    String? caption,
    String? replyToMessageId,
  });
  Future<ChatMessageModel> sendVideo(
    String conversationId,
    String filePath, {
    String? caption,
    String? replyToMessageId,
  });
  Future<ChatMessageModel> sendVoice(
    String conversationId,
    String filePath, {
    int? durationSeconds,
    String? replyToMessageId,
  });
  Future<List<Map<String, String>>> reactToMessage(
    String messageId,
    String emoji,
  );
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
    final response = await _apiClient.dio
        .get('/api/messages/conversations/$conversationId');
    final data = response.data['data'] as List;
    return data.map((e) => ChatMessageModel.fromJson(e)).toList();
  }

  @override
  Future<ConversationModel> startOrGetConversation(String doctorId) async {
    final response =
        await _apiClient.dio.post('/api/messages/conversations/$doctorId');
    return ConversationModel.fromJson(response.data['data']);
  }

  @override
  Future<ChatMessageModel> sendMessage(
    String conversationId,
    String content, {
    String? replyToMessageId,
  }) async {
    final response = await _apiClient.dio.post(
      '/api/messages/conversations/$conversationId/send',
      data: {
        'content': content,
        if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
      },
    );
    return ChatMessageModel.fromJson(response.data['data']);
  }

  @override
  Future<ChatMessageModel> sendImage(
    String conversationId,
    String filePath, {
    String? caption,
    String? replyToMessageId,
  }) async {
    final form = FormData.fromMap({
      'image': await MultipartFile.fromFile(filePath),
      if (caption != null && caption.isNotEmpty) 'caption': caption,
      if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
    });
    final response = await _apiClient.dio.post(
      '/api/messages/conversations/$conversationId/send-image',
      data: form,
    );
    return ChatMessageModel.fromJson(response.data['data']);
  }

  @override
  Future<ChatMessageModel> sendVideo(
    String conversationId,
    String filePath, {
    String? caption,
    String? replyToMessageId,
  }) async {
    final form = FormData.fromMap({
      'video': await MultipartFile.fromFile(filePath),
      if (caption != null && caption.isNotEmpty) 'caption': caption,
      if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
    });
    final response = await _apiClient.dio.post(
      '/api/messages/conversations/$conversationId/send-video',
      data: form,
    );
    return ChatMessageModel.fromJson(response.data['data']);
  }

  @override
  Future<ChatMessageModel> sendVoice(
    String conversationId,
    String filePath, {
    int? durationSeconds,
    String? replyToMessageId,
  }) async {
    final form = FormData.fromMap({
      'audio': await MultipartFile.fromFile(filePath),
      if (durationSeconds != null) 'durationSeconds': durationSeconds,
      if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
    });
    final response = await _apiClient.dio.post(
      '/api/messages/conversations/$conversationId/send-voice',
      data: form,
    );
    return ChatMessageModel.fromJson(response.data['data']);
  }

  @override
  Future<List<Map<String, String>>> reactToMessage(
    String messageId,
    String emoji,
  ) async {
    final response = await _apiClient.dio.post(
      '/api/messages/messages/$messageId/react',
      data: {'emoji': emoji},
    );
    final data = response.data['data'] as List;
    return data
        .map((r) => {
              'userId': (r['userId']).toString(),
              'emoji': (r['emoji'] ?? '').toString(),
            })
        .toList();
  }

  @override
  Future<void> markConversationAsRead(String conversationId) async {
    await _apiClient.dio
        .put('/api/messages/conversations/$conversationId/read');
  }
}
