import '../../../../core/network/api_result.dart';
import '../entities/onboarding_entities.dart';
import '../repos/onboarding_repository.dart';

class GetMyDocumentsUseCase {
  final OnboardingRepository _repository;
  const GetMyDocumentsUseCase(this._repository);

  Future<ApiResult<List<UploadedDocument>>> call() => _repository.getMyDocuments();
}
