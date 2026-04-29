import '../../../../core/network/api_result.dart';
import '../entities/appointment_entity.dart';

/// Appointment repository contract.
abstract class AppointmentRepository {
  Future<ApiResult<AppointmentEntity>> bookAppointment({
    required String doctorProfileId,
    required DateTime scheduledAt,
    String? locationName,
  });

  Future<ApiResult<List<AppointmentEntity>>> getPatientAppointments();

  Future<ApiResult<List<AppointmentEntity>>> getDoctorAppointments();

  Future<ApiResult<AppointmentEntity>> getAppointmentById(String id);

  Future<ApiResult<List<DateTime>>> getAvailableSlots({
    required String doctorId,
    required DateTime date,
  });

  Future<ApiResult<void>> cancelAppointment(String id);

  Future<ApiResult<void>> confirmAppointment(String id);

  Future<ApiResult<void>> completeAppointment(String id);
}
