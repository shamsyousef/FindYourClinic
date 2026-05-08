import '../../../../core/network/api_result.dart';
import '../../../appointments/domain/entities/appointment_entity.dart';
import '../entities/doctor_payment_info_entity.dart';
import '../entities/payment_entities.dart';

/// Payment repository contract.
abstract class PaymentRepository {
  Future<ApiResult<PaymentIntentEntity>> initiatePayment({
    required String doctorProfileId,
    required DateTime scheduledAt,
    String? locationName,
    required PaymentMethod paymentMethod,
    String? walletPhone,
  });

  Future<ApiResult<AppointmentEntity>> confirmPayment({
    required String doctorProfileId,
    required DateTime scheduledAt,
    String? locationName,
    required String paymobOrderId,
    required String paymobTransactionId,
    required PaymentMethod paymentMethod,
  });

  Future<ApiResult<List<TransactionEntity>>> getPaymentHistory();

  Future<ApiResult<DoctorEarningsEntity>> getDoctorEarnings();

  Future<ApiResult<void>> markAsPaid(String appointmentId);

  Future<ApiResult<DoctorPaymentInfoEntity?>> getDoctorPaymentInfo();

  Future<ApiResult<void>> saveDoctorPaymentInfo(DoctorPaymentInfoEntity info);
}
