import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/network/failure.dart';
import '../../domain/entities/user_profile_entity.dart';
import '../../domain/repos/patient_profile_repository.dart';
import '../models/user_profile_model.dart';

class PatientProfileRepositoryImpl implements PatientProfileRepository {
  final ApiClient _apiClient;

  const PatientProfileRepositoryImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<ApiResult<UserProfileEntity>> getProfile() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.userProfile);
      final data = response.data['data'] as Map<String, dynamic>;
      return Success(UserProfileModel.fromJson(data).toEntity());
    } on DioException catch (e) {
      return Error(mapDioException(e));
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<ApiResult<UserProfileEntity>> updateProfile({
    required String firstName,
    required String lastName,
  }) async {
    try {
      final response = await _apiClient.dio.put(
        ApiEndpoints.userProfile,
        data: {'firstName': firstName, 'lastName': lastName},
      );
      final data = response.data['data'] as Map<String, dynamic>;
      return Success(UserProfileModel.fromJson(data).toEntity());
    } on DioException catch (e) {
      return Error(mapDioException(e));
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }
}
