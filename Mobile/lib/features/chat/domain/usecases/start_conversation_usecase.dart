import '../../../../core/network/api_result.dart';
import '../entities/conversation.dart';
import '../repositories/i_chat_repository.dart';

class StartConversationUseCase {
  final IChatRepository _repository;

  StartConversationUseCase(this._repository);

  Future<ApiResult<Conversation>> call(String doctorId) {
    return _repository.startOrGetConversation(doctorId);
  }
}
