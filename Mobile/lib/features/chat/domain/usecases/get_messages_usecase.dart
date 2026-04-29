import '../../../../core/network/api_result.dart';
import '../entities/chat_message.dart';
import '../repositories/i_chat_repository.dart';

class GetMessagesUseCase {
  final IChatRepository _repository;

  GetMessagesUseCase(this._repository);

  Future<ApiResult<List<ChatMessage>>> call(String conversationId) {
    return _repository.getMessages(conversationId);
  }
}
