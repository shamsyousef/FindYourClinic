import '../../../../core/network/api_result.dart';
import '../entities/availability_config_entity.dart';

abstract class DoctorAvailabilityRepository {
  Future<ApiResult<List<AvailabilityConfigEntity>>> getMyAvailability();

  Future<ApiResult<AvailabilityConfigEntity>> addAvailability({
    required String dayOfWeek,
    required String startTime,
    required String endTime,
  });

  Future<ApiResult<void>> removeAvailability(String id);
}
