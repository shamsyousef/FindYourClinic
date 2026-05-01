import '../../../../core/network/api_result.dart';
import '../entities/symptom_analysis.dart';
import '../repos/ai_health_repository.dart';

class AnalyzeSymptomsUseCase {
  final AiHealthRepository _repository;
  const AnalyzeSymptomsUseCase(this._repository);

  Future<ApiResult<SymptomAnalysis>> call(List<String> symptoms) =>
      _repository.analyzeSymptoms(symptoms);
}
