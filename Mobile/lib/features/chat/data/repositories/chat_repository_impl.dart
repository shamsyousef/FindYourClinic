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
  Stream<ChatMessage> get onMessageReceived => _signalRDataSource.onMessageReceived;

  @override
  Stream<String> get onConversationUpdated => _signalRDataSource.onConversationUpdated;

  @override
  Stream<String> get onMessagesRead => _signalRDataSource.onMessagesRead;

  @override
  Future<ApiResult<List<Conversation>>> getConversations() async {
    try {
      await _signalRDataSource.connect(); // Ensure we connect to listen to updates on the list
      final result = await _remoteDataSource.getConversations();
      return Success(result);
    } on DioException catch (e) {
      return Error(mapDioException(e));
    } catch (e) {
      return const Error(UnknownFailure());
    }
  }

  @override
  Future<ApiResult<List<ChatMessage>>> getMessages(String conversationId) async {
    try {
      final result = await _remoteDataSource.getMessages(conversationId);
      return Success(result);
    } on DioException catch (e) {
      return Error(mapDioException(e));
    } catch (e) {
      return const Error(UnknownFailure());
    }
  }

  @override
  Future<ApiResult<Conversation>> startOrGetConversation(String doctorId) async {
    try {
      final result = await _remoteDataSource.startOrGetConversation(doctorId);
      return Success(result);
    } on DioException catch (e) {
      return Error(mapDioException(e));
    } catch (e) {
      return const Error(UnknownFailure());
    }
  }

  @override
  Future<ApiResult<ChatMessage>> sendMessage(String conversationId, String content) async {
    try {
      final result = await _remoteDataSource.sendMessage(conversationId, content);
      return Success(result);
    } on DioException catch (e) {
      return Error(mapDioException(e));
    } catch (e) {
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
    } catch (e) {
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
}
