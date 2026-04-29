import '../../../../core/network/api_result.dart';
import '../entities/conversation.dart';
import '../repositories/i_chat_repository.dart';

class GetConversationsUseCase {
  final IChatRepository _repository;

  GetConversationsUseCase(this._repository);

  Future<ApiResult<List<Conversation>>> call() {
    return _repository.getConversations();
  }
}
