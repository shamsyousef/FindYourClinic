import '../../../../core/network/api_result.dart';
import '../entities/doctor_profile_entities.dart';

/// Doctor profile repository contract.
abstract class DoctorProfileRepository {
  Future<ApiResult<DoctorDetails>> getDoctorDetails(String doctorId);
  Future<ApiResult<List<DoctorReview>>> getDoctorReviews(String doctorId);
  Future<ApiResult<List<AvailabilitySlot>>> getDoctorAvailability(String doctorId);
  Future<ApiResult<void>> updateDoctorProfile(UpdateDoctorProfileParams params);
  Future<ApiResult<void>> addReview(String doctorId, int rating, String? comment);
}
