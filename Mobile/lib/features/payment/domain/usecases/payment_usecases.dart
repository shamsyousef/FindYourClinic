import '../../../../core/network/api_result.dart';
import '../../../appointments/domain/entities/appointment_entity.dart';
import '../entities/doctor_payment_info_entity.dart';
import '../entities/payment_entities.dart';
import '../repos/payment_repository.dart';

class InitiatePaymentUseCase {
  final PaymentRepository _repository;
  const InitiatePaymentUseCase(this._repository);

  Future<ApiResult<PaymentIntentEntity>> call({
    required String doctorProfileId,
    required DateTime scheduledAt,
    String? locationName,
    required PaymentMethod paymentMethod,
    String? walletPhone,
  }) =>
      _repository.initiatePayment(
        doctorProfileId: doctorProfileId,
        scheduledAt: scheduledAt,
        locationName: locationName,
        paymentMethod: paymentMethod,
        walletPhone: walletPhone,
      );
}

class ConfirmPaymentUseCase {
  final PaymentRepository _repository;
  const ConfirmPaymentUseCase(this._repository);

  Future<ApiResult<AppointmentEntity>> call({
    required String doctorProfileId,
    required DateTime scheduledAt,
    String? locationName,
    required String paymobOrderId,
    required String paymobTransactionId,
    required PaymentMethod paymentMethod,
  }) =>
      _repository.confirmPayment(
        doctorProfileId: doctorProfileId,
        scheduledAt: scheduledAt,
        locationName: locationName,
        paymobOrderId: paymobOrderId,
        paymobTransactionId: paymobTransactionId,
        paymentMethod: paymentMethod,
      );
}

class GetPaymentHistoryUseCase {
  final PaymentRepository _repository;
  const GetPaymentHistoryUseCase(this._repository);

  Future<ApiResult<List<TransactionEntity>>> call() =>
      _repository.getPaymentHistory();
}

class GetDoctorEarningsUseCase {
  final PaymentRepository _repository;
  const GetDoctorEarningsUseCase(this._repository);

  Future<ApiResult<DoctorEarningsEntity>> call() =>
      _repository.getDoctorEarnings();
}

class MarkAsPaidUseCase {
  final PaymentRepository _repository;
  const MarkAsPaidUseCase(this._repository);

  Future<ApiResult<void>> call(String appointmentId) =>
      _repository.markAsPaid(appointmentId);
}

class GetDoctorPaymentInfoUseCase {
  final PaymentRepository _repository;
  const GetDoctorPaymentInfoUseCase(this._repository);

  Future<ApiResult<DoctorPaymentInfoEntity?>> call() =>
      _repository.getDoctorPaymentInfo();
}

class SaveDoctorPaymentInfoUseCase {
  final PaymentRepository _repository;
  const SaveDoctorPaymentInfoUseCase(this._repository);

  Future<ApiResult<void>> call(DoctorPaymentInfoEntity info) =>
      _repository.saveDoctorPaymentInfo(info);
}
