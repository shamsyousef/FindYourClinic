import '../../../../core/network/api_result.dart';
import '../entities/chat_message.dart';
import '../repositories/i_chat_repository.dart';

class SendMessageUseCase {
  final IChatRepository _repository;

  SendMessageUseCase(this._repository);

  Future<ApiResult<ChatMessage>> call(
    String conversationId,
    String content, {
    String? replyToMessageId,
  }) {
    return _repository.sendMessage(
      conversationId,
      content,
      replyToMessageId: replyToMessageId,
    );
  }
}

class SendImageMessageUseCase {
  final IChatRepository _repository;

  SendImageMessageUseCase(this._repository);

  Future<ApiResult<ChatMessage>> call(
    String conversationId,
    String filePath, {
    String? caption,
    String? replyToMessageId,
  }) {
    return _repository.sendImage(
      conversationId,
      filePath,
      caption: caption,
      replyToMessageId: replyToMessageId,
    );
  }
}

class SendVideoMessageUseCase {
  final IChatRepository _repository;

  SendVideoMessageUseCase(this._repository);

  Future<ApiResult<ChatMessage>> call(
    String conversationId,
    String filePath, {
    String? caption,
    String? replyToMessageId,
  }) {
    return _repository.sendVideo(
      conversationId,
      filePath,
      caption: caption,
      replyToMessageId: replyToMessageId,
    );
  }
}

class SendVoiceMessageUseCase {
  final IChatRepository _repository;

  SendVoiceMessageUseCase(this._repository);

  Future<ApiResult<ChatMessage>> call(
    String conversationId,
    String filePath, {
    int? durationSeconds,
    String? replyToMessageId,
  }) {
    return _repository.sendVoice(
      conversationId,
      filePath,
      durationSeconds: durationSeconds,
      replyToMessageId: replyToMessageId,
    );
  }
}

class ReactToMessageUseCase {
  final IChatRepository _repository;

  ReactToMessageUseCase(this._repository);

  Future<ApiResult<List<MessageReaction>>> call(String messageId, String emoji) {
    return _repository.reactToMessage(messageId, emoji);
  }
}
