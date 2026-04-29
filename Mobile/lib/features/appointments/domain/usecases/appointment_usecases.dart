import '../../../../core/network/api_result.dart';
import '../entities/appointment_entity.dart';
import '../repos/appointment_repository.dart';

class BookAppointmentUseCase {
  final AppointmentRepository _repository;
  const BookAppointmentUseCase(this._repository);

  Future<ApiResult<AppointmentEntity>> call({
    required String doctorProfileId,
    required DateTime scheduledAt,
    String? locationName,
  }) =>
      _repository.bookAppointment(
        doctorProfileId: doctorProfileId,
        scheduledAt: scheduledAt,
        locationName: locationName,
      );
}

class GetPatientAppointmentsUseCase {
  final AppointmentRepository _repository;
  const GetPatientAppointmentsUseCase(this._repository);

  Future<ApiResult<List<AppointmentEntity>>> call() =>
      _repository.getPatientAppointments();
}

class GetDoctorAppointmentsUseCase {
  final AppointmentRepository _repository;
  const GetDoctorAppointmentsUseCase(this._repository);

  Future<ApiResult<List<AppointmentEntity>>> call() =>
      _repository.getDoctorAppointments();
}

class GetAppointmentByIdUseCase {
  final AppointmentRepository _repository;
  const GetAppointmentByIdUseCase(this._repository);

  Future<ApiResult<AppointmentEntity>> call(String id) =>
      _repository.getAppointmentById(id);
}

class GetAvailableSlotsUseCase {
  final AppointmentRepository _repository;
  const GetAvailableSlotsUseCase(this._repository);

  Future<ApiResult<List<DateTime>>> call({
    required String doctorId,
    required DateTime date,
  }) =>
      _repository.getAvailableSlots(doctorId: doctorId, date: date);
}

class CancelAppointmentUseCase {
  final AppointmentRepository _repository;
  const CancelAppointmentUseCase(this._repository);

  Future<ApiResult<void>> call(String id) =>
      _repository.cancelAppointment(id);
}

class ConfirmAppointmentUseCase {
  final AppointmentRepository _repository;
  const ConfirmAppointmentUseCase(this._repository);

  Future<ApiResult<void>> call(String id) =>
      _repository.confirmAppointment(id);
}

class CompleteAppointmentUseCase {
  final AppointmentRepository _repository;
  const CompleteAppointmentUseCase(this._repository);

  Future<ApiResult<void>> call(String id) =>
      _repository.completeAppointment(id);
}
