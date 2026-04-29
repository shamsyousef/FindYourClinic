import '../../../../core/network/api_result.dart';
import '../repositories/i_chat_repository.dart';

class MarkConversationAsReadUseCase {
  final IChatRepository _repository;

  MarkConversationAsReadUseCase(this._repository);

  Future<ApiResult<void>> call(String conversationId) {
    return _repository.markConversationAsRead(conversationId);
  }
}
