import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/network/failure.dart';
import '../../domain/entities/doctor_profile_entities.dart';
import '../../domain/repos/doctor_profile_repository.dart';
import '../models/doctor_profile_models.dart';

class DoctorProfileRepositoryImpl implements DoctorProfileRepository {
  final ApiClient _apiClient;

  const DoctorProfileRepositoryImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<ApiResult<DoctorDetails>> getDoctorDetails(String doctorId) async {
    try {
      final response =
          await _apiClient.dio.get(ApiEndpoints.doctorDetails(doctorId));
      final data = response.data['data'] as Map<String, dynamic>;
      return Success(DoctorDetailsModel.fromJson(data).toEntity());
    } on DioException catch (e) {
      return Error(mapDioException(e));
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<ApiResult<List<DoctorReview>>> getDoctorReviews(
      String doctorId) async {
    try {
      final response =
          await _apiClient.dio.get(ApiEndpoints.doctorReviews(doctorId));
      final data = response.data['data'] as List;
      final reviews =
          data.map((e) => DoctorReviewModel.fromJson(e).toEntity()).toList();
      return Success(reviews);
    } on DioException catch (e) {
      return Error(mapDioException(e));
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<ApiResult<List<AvailabilitySlot>>> getDoctorAvailability(
      String doctorId) async {
    try {
      final response = await _apiClient.dio
          .get(ApiEndpoints.doctorWeeklySchedule(doctorId));
      final data = response.data['data'] as List;
      final slots = data
          .map((e) => AvailabilitySlotModel.fromJson(e).toEntity())
          .toList();
      return Success(slots);
    } on DioException catch (e) {
      return Error(mapDioException(e));
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<ApiResult<void>> updateDoctorProfile(
      UpdateDoctorProfileParams params) async {
    try {
      await _apiClient.dio.put(ApiEndpoints.updateDoctorProfile, data: {
        if (params.bio != null) 'bio': params.bio,
        if (params.clinicName != null) 'clinicName': params.clinicName,
        if (params.clinicAddress != null) 'clinicAddress': params.clinicAddress,
        if (params.latitude != null) 'latitude': params.latitude,
        if (params.longitude != null) 'longitude': params.longitude,
        if (params.consultationFee != null)
          'consultationFee': params.consultationFee,
        if (params.experienceYears != null)
          'experienceYears': params.experienceYears,
      });
      return const Success(null);
    } on DioException catch (e) {
      return Error(mapDioException(e));
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<ApiResult<void>> addReview(
      String doctorId, int rating, String? comment) async {
    try {
      await _apiClient.dio.post(
        ApiEndpoints.doctorReviews(doctorId),
        data: {
          'rating': rating,
          if (comment != null && comment.isNotEmpty) 'comment': comment,
        },
      );
      return const Success(null);
    } on DioException catch (e) {
      return Error(mapDioException(e));
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }
}
