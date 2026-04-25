import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/network/failure.dart';
import '../../domain/entities/specialty_entity.dart';
import '../../domain/repos/specialty_repository.dart';

class SpecialtyRepositoryImpl implements SpecialtyRepository {
  final ApiClient _apiClient;

  const SpecialtyRepositoryImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<ApiResult<List<Specialty>>> getActiveSpecialties() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.specialties);
      final body = response.data as Map<String, dynamic>;
      if (body['success'] != true) {
        return Error(
            ServerFailure(body['message'] as String? ?? 'Failed to load specialties'));
      }
      final list = (body['data'] as List<dynamic>)
          .map((e) => Specialty(
                id: e['id'] as String,
                name: e['name'] as String,
                iconUrl: e['iconUrl'] as String?,
              ))
          .toList();
      return Success(list);
    } on DioException catch (e) {
      return Error(mapDioException(e));
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }
}
