import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/network/failure.dart';
import '../../domain/entities/health_record_entity.dart';
import '../../domain/repos/health_record_repository.dart';
import '../models/health_record_model.dart';
import '../models/health_summary_model.dart';

class HealthRecordRepositoryImpl implements HealthRecordRepository {
  final ApiClient _apiClient;

  const HealthRecordRepositoryImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<ApiResult<List<HealthRecordEntity>>> getRecords({
    HealthRecordType? type,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.healthRecords,
        queryParameters: type != null ? {'type': type.index} : null,
      );
      final data = response.data['data'] as List;
      return Success(
        data.map((e) => HealthRecordModel.fromJson(e).toEntity()).toList(),
      );
    } on DioException catch (e) {
      return Error(mapDioException(e));
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<ApiResult<HealthRecordEntity>> getRecordById(String id) async {
    try {
      final response =
          await _apiClient.dio.get(ApiEndpoints.healthRecord(id));
      final data = response.data['data'] as Map<String, dynamic>;
      return Success(HealthRecordModel.fromJson(data).toEntity());
    } on DioException catch (e) {
      return Error(mapDioException(e));
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<ApiResult<HealthSummaryEntity>> getSummary() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.healthSummary);
      final data = response.data['data'] as Map<String, dynamic>;
      return Success(HealthSummaryModel.fromJson(data).toEntity());
    } on DioException catch (e) {
      return Error(mapDioException(e));
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<ApiResult<HealthRecordEntity>> createRecord({
    required String title,
    required HealthRecordType type,
    String? value,
    String? unit,
    required DateTime recordedAt,
    String? notes,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.healthRecords,
        data: {
          'title': title,
          'type': type.index,
          'value': ?value,
          'unit': ?unit,
          'recordedAt': recordedAt.toUtc().toIso8601String(),
          'notes': ?notes,
        },
      );
      final data = response.data['data'] as Map<String, dynamic>;
      return Success(HealthRecordModel.fromJson(data).toEntity());
    } on DioException catch (e) {
      return Error(mapDioException(e));
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<ApiResult<HealthRecordEntity>> updateRecord({
    required String id,
    required String title,
    required HealthRecordType type,
    String? value,
    String? unit,
    required DateTime recordedAt,
    String? notes,
  }) async {
    try {
      final response = await _apiClient.dio.put(
        ApiEndpoints.healthRecord(id),
        data: {
          'title': title,
          'type': type.index,
          'value': ?value,
          'unit': ?unit,
          'recordedAt': recordedAt.toUtc().toIso8601String(),
          'notes': ?notes,
        },
      );
      final data = response.data['data'] as Map<String, dynamic>;
      return Success(HealthRecordModel.fromJson(data).toEntity());
    } on DioException catch (e) {
      return Error(mapDioException(e));
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<ApiResult<void>> deleteRecord(String id) async {
    try {
      await _apiClient.dio.delete(ApiEndpoints.healthRecord(id));
      return const Success(null);
    } on DioException catch (e) {
      return Error(mapDioException(e));
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }
}
