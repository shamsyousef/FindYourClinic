import 'package:dio/dio.dart';

import '../../../../core/network/api_result.dart';
import '../../../../core/network/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/availability_config_entity.dart';
import '../../domain/repos/doctor_availability_repository.dart';
import '../datasources/doctor_availability_remote_datasource.dart';

class DoctorAvailabilityRepositoryImpl implements DoctorAvailabilityRepository {
  final DoctorAvailabilityRemoteDataSource _remoteDataSource;

  const DoctorAvailabilityRepositoryImpl({
    required DoctorAvailabilityRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  @override
  Future<ApiResult<List<AvailabilityConfigEntity>>> getMyAvailability() async {
    try {
      final models = await _remoteDataSource.getMyAvailability();
      final entities = models.map((e) => e.toEntity()).toList();
      return Success(entities);
    } on DioException catch (e) {
      return Error(mapDioException(e));
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<ApiResult<AvailabilityConfigEntity>> addAvailability({
    required String dayOfWeek,
    required String startTime,
    required String endTime,
  }) async {
    try {
      final model = await _remoteDataSource.addAvailability(
        dayOfWeek: dayOfWeek,
        startTime: startTime,
        endTime: endTime,
      );
      return Success(model.toEntity());
    } on DioException catch (e) {
      return Error(mapDioException(e));
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<ApiResult<void>> removeAvailability(String id) async {
    try {
      await _remoteDataSource.removeAvailability(id);
      return const Success(null);
    } on DioException catch (e) {
      return Error(mapDioException(e));
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }
}
