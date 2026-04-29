import '../../../../core/network/api_result.dart';
import '../entities/chat_message.dart';
import '../repositories/i_chat_repository.dart';

class SendMessageUseCase {
  final IChatRepository _repository;

  SendMessageUseCase(this._repository);

  Future<ApiResult<ChatMessage>> call(String conversationId, String content) {
    return _repository.sendMessage(conversationId, content);
  }
}
