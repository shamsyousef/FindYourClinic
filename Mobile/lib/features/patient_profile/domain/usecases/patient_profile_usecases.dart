import '../../../../core/network/api_result.dart';
import '../entities/user_profile_entity.dart';
import '../repos/patient_profile_repository.dart';

class GetPatientProfileUseCase {
  final PatientProfileRepository _repo;
  const GetPatientProfileUseCase(this._repo);

  Future<ApiResult<UserProfileEntity>> call() => _repo.getProfile();
}

class UpdatePatientProfileUseCase {
  final PatientProfileRepository _repo;
  const UpdatePatientProfileUseCase(this._repo);

  Future<ApiResult<UserProfileEntity>> call({
    required String firstName,
    required String lastName,
  }) =>
      _repo.updateProfile(firstName: firstName, lastName: lastName);
}
