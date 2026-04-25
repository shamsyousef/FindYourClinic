import '../../../../core/network/api_result.dart';
import '../entities/specialty_entity.dart';
import '../repos/specialty_repository.dart';

class GetSpecialtiesUseCase {
  final SpecialtyRepository _repository;
  const GetSpecialtiesUseCase(this._repository);

  Future<ApiResult<List<Specialty>>> call() =>
      _repository.getActiveSpecialties();
}
