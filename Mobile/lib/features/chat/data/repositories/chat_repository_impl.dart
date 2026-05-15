import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/network/failure.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/repositories/i_chat_repository.dart';
import '../datasources/chat_remote_datasource.dart';
import '../datasources/chat_signalr_datasource.dart';

class ChatRepositoryImpl implements IChatRepository {
  final ChatRemoteDataSource _remoteDataSource;
  final ChatSignalRDataSource _signalRDataSource;

  ChatRepositoryImpl(this._remoteDataSource, this._signalRDataSource);

  @override
  Stream<ChatMessage> get onMessageReceived =>
      _signalRDataSource.onMessageReceived;

  @override
  Stream<String> get onConversationUpdated =>
      _signalRDataSource.onConversationUpdated;

  @override
  Stream<String> get onMessagesRead => _signalRDataSource.onMessagesRead;

  @override
  Stream<bool> get onTyping => _signalRDataSource.onTyping;

  @override
  Stream<ReactionUpdate> get onReactionUpdated =>
      _signalRDataSource.onReactionUpdated;

  @override
  Future<ApiResult<List<Conversation>>> getConversations() async {
    try {
      await _signalRDataSource.connect();
      final result = await _remoteDataSource.getConversations();
      return Success(result);
    } on DioException catch (e) {
      return Error(mapDioException(e));
    } catch (_) {
      return const Error(UnknownFailure());
    }
  }

  @override
  Future<ApiResult<List<ChatMessage>>> getMessages(
      String conversationId) async {
    try {
      final result = await _remoteDataSource.getMessages(conversationId);
      return Success(result);
    } on DioException catch (e) {
      return Error(mapDioException(e));
    } catch (_) {
      return const Error(UnknownFailure());
    }
  }

  @override
  Future<ApiResult<Conversation>> startOrGetConversation(
      String doctorId) async {
    try {
      final result =
          await _remoteDataSource.startOrGetConversation(doctorId);
      return Success(result);
    } on DioException catch (e) {
      return Error(mapDioException(e));
    } catch (_) {
      return const Error(UnknownFailure());
    }
  }

  @override
  Future<ApiResult<ChatMessage>> sendMessage(
    String conversationId,
    String content, {
    String? replyToMessageId,
  }) async {
    try {
      final result = await _remoteDataSource.sendMessage(
        conversationId,
        content,
        replyToMessageId: replyToMessageId,
      );
      return Success(result);
    } on DioException catch (e) {
      return Error(mapDioException(e));
    } catch (_) {
      return const Error(UnknownFailure());
    }
  }

  @override
  Future<ApiResult<ChatMessage>> sendImage(
    String conversationId,
    String filePath, {
    String? caption,
    String? replyToMessageId,
  }) async {
    try {
      final result = await _remoteDataSource.sendImage(
        conversationId,
        filePath,
        caption: caption,
        replyToMessageId: replyToMessageId,
      );
      return Success(result);
    } on DioException catch (e) {
      return Error(mapDioException(e));
    } catch (_) {
      return const Error(UnknownFailure());
    }
  }

  @override
  Future<ApiResult<ChatMessage>> sendVideo(
    String conversationId,
    String filePath, {
    String? caption,
    String? replyToMessageId,
  }) async {
    try {
      final result = await _remoteDataSource.sendVideo(
        conversationId,
        filePath,
        caption: caption,
        replyToMessageId: replyToMessageId,
      );
      return Success(result);
    } on DioException catch (e) {
      return Error(mapDioException(e));
    } catch (_) {
      return const Error(UnknownFailure());
    }
  }

  @override
  Future<ApiResult<ChatMessage>> sendVoice(
    String conversationId,
    String filePath, {
    int? durationSeconds,
    String? replyToMessageId,
  }) async {
    try {
      final result = await _remoteDataSource.sendVoice(
        conversationId,
        filePath,
        durationSeconds: durationSeconds,
        replyToMessageId: replyToMessageId,
      );
      return Success(result);
    } on DioException catch (e) {
      return Error(mapDioException(e));
    } catch (_) {
      return const Error(UnknownFailure());
    }
  }

  @override
  Future<ApiResult<List<MessageReaction>>> reactToMessage(
    String messageId,
    String emoji,
  ) async {
    try {
      final raw = await _remoteDataSource.reactToMessage(messageId, emoji);
      final reactions = raw
          .map((m) => MessageReaction(
                userId: m['userId'] ?? '',
                emoji: m['emoji'] ?? '',
              ))
          .toList(growable: false);
      return Success(reactions);
    } on DioException catch (e) {
      return Error(mapDioException(e));
    } catch (_) {
      return const Error(UnknownFailure());
    }
  }

  @override
  Future<ApiResult<void>> markConversationAsRead(String conversationId) async {
    try {
      await _remoteDataSource.markConversationAsRead(conversationId);
      return const Success(null);
    } on DioException catch (e) {
      return Error(mapDioException(e));
    } catch (_) {
      return const Error(UnknownFailure());
    }
  }

  @override
  Future<void> joinConversation(String conversationId) async {
    await _signalRDataSource.connect();
    await _signalRDataSource.joinConversation(conversationId);
  }

  @override
  Future<void> leaveConversation(String conversationId) async {
    await _signalRDataSource.leaveConversation(conversationId);
  }

  @override
  Future<void> disconnect() async {
    await _signalRDataSource.disconnect();
  }

  @override
  Future<void> sendTypingStarted(String conversationId) async {
    await _signalRDataSource.sendTypingStarted(conversationId);
  }

  @override
  Future<void> sendTypingStopped(String conversationId) async {
    await _signalRDataSource.sendTypingStopped(conversationId);
  }
}
