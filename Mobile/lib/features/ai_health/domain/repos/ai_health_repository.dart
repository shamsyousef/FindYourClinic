import '../../../../core/network/api_result.dart';
import '../entities/ai_chat_message.dart';
import '../entities/symptom_analysis.dart';

abstract interface class AiHealthRepository {
  Future<ApiResult<AiChatMessage>> sendMessage(String content);
  Future<ApiResult<List<AiChatMessage>>> getChatHistory();
  Future<ApiResult<SymptomAnalysis>> analyzeSymptoms(List<String> symptoms);
}
