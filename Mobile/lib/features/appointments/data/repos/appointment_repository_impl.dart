import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/date_utils.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/network/failure.dart';
import '../../domain/entities/appointment_entity.dart';
import '../../domain/repos/appointment_repository.dart';
import '../models/appointment_model.dart';

class AppointmentRepositoryImpl implements AppointmentRepository {
  final ApiClient _apiClient;

  const AppointmentRepositoryImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<ApiResult<AppointmentEntity>> bookAppointment({
    required String doctorProfileId,
    required DateTime scheduledAt,
    String? locationName,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.appointments,
        data: {
          'doctorProfileId': doctorProfileId,
          'scheduledAt': scheduledAt.toUtc().toIso8601String(),
          // ignore: use_null_aware_elements`n          if (locationName != null) 'locationName': locationName,
        },
      );
      final data = response.data['data'] as Map<String, dynamic>;
      return Success(AppointmentModel.fromJson(data).toEntity());
    } on DioException catch (e) {
      return Error(mapDioException(e));
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<ApiResult<List<AppointmentEntity>>> getPatientAppointments() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.myAppointments);
      final data = response.data['data'] as List;
      final items =
          data.map((e) => AppointmentModel.fromJson(e).toEntity()).toList();
      return Success(items);
    } on DioException catch (e) {
      return Error(mapDioException(e));
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<ApiResult<List<AppointmentEntity>>> getDoctorAppointments() async {
    try {
      final response =
          await _apiClient.dio.get(ApiEndpoints.doctorAppointments);
      final data = response.data['data'] as List;
      final items =
          data.map((e) => AppointmentModel.fromJson(e).toEntity()).toList();
      return Success(items);
    } on DioException catch (e) {
      return Error(mapDioException(e));
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<ApiResult<AppointmentEntity>> getAppointmentById(String id) async {
    try {
      final response =
          await _apiClient.dio.get(ApiEndpoints.appointmentById(id));
      final data = response.data['data'] as Map<String, dynamic>;
      return Success(AppointmentModel.fromJson(data).toEntity());
    } on DioException catch (e) {
      return Error(mapDioException(e));
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<ApiResult<List<DateTime>>> getAvailableSlots({
    required String doctorId,
    required DateTime date,
  }) async {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final response = await _apiClient.dio.get(
        ApiEndpoints.doctorSlots(doctorId),
        queryParameters: {'date': dateStr},
      );
      final data = response.data['data'] as List;
      final slots = data.map((e) => parseServerDateTime(e as String)).toList();
      return Success(slots);
    } on DioException catch (e) {
      return Error(mapDioException(e));
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<ApiResult<void>> cancelAppointment(String id) async {
    try {
      await _apiClient.dio.put(ApiEndpoints.cancelAppointment(id));
      return const Success(null);
    } on DioException catch (e) {
      return Error(mapDioException(e));
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<ApiResult<void>> confirmAppointment(String id) async {
    try {
      await _apiClient.dio.put(ApiEndpoints.confirmAppointment(id));
      return const Success(null);
    } on DioException catch (e) {
      return Error(mapDioException(e));
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<ApiResult<void>> completeAppointment(String id) async {
    try {
      await _apiClient.dio.put(ApiEndpoints.completeAppointment(id));
      return const Success(null);
    } on DioException catch (e) {
      return Error(mapDioException(e));
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }
}
