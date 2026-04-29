import '../../../../core/network/api_result.dart';
import '../entities/availability_config_entity.dart';
import '../repos/doctor_availability_repository.dart';

class GetMyAvailabilityUseCase {
  final DoctorAvailabilityRepository _repository;
  const GetMyAvailabilityUseCase(this._repository);

  Future<ApiResult<List<AvailabilityConfigEntity>>> call() =>
      _repository.getMyAvailability();
}

class AddAvailabilityUseCase {
  final DoctorAvailabilityRepository _repository;
  const AddAvailabilityUseCase(this._repository);

  Future<ApiResult<AvailabilityConfigEntity>> call({
    required String dayOfWeek,
    required String startTime,
    required String endTime,
  }) =>
      _repository.addAvailability(
        dayOfWeek: dayOfWeek,
        startTime: startTime,
        endTime: endTime,
      );
}

class RemoveAvailabilityUseCase {
  final DoctorAvailabilityRepository _repository;
  const RemoveAvailabilityUseCase(this._repository);

  Future<ApiResult<void>> call(String id) =>
      _repository.removeAvailability(id);
}
