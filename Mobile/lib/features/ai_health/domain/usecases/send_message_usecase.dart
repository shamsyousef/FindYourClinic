import '../../../../core/network/api_result.dart';
import '../entities/ai_chat_message.dart';
import '../repos/ai_health_repository.dart';

class SendMessageUseCase {
  final AiHealthRepository _repository;
  const SendMessageUseCase(this._repository);

  Future<ApiResult<AiChatMessage>> call(String content) =>
      _repository.sendMessage(content);
}
