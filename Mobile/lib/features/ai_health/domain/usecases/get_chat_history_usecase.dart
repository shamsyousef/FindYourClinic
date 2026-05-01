import '../../../../core/network/api_result.dart';
import '../entities/ai_chat_message.dart';
import '../repos/ai_health_repository.dart';

class GetChatHistoryUseCase {
  final AiHealthRepository _repository;
  const GetChatHistoryUseCase(this._repository);

  Future<ApiResult<List<AiChatMessage>>> call() =>
      _repository.getChatHistory();
}
