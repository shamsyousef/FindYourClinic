import '../../../../core/network/api_result.dart';
import '../entities/user_profile_entity.dart';

abstract interface class PatientProfileRepository {
  Future<ApiResult<UserProfileEntity>> getProfile();
  Future<ApiResult<UserProfileEntity>> updateProfile({
    required String firstName,
    required String lastName,
  });
}
