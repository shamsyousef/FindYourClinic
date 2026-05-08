import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/network/failure.dart';
import '../../../appointments/data/models/appointment_model.dart';
import '../../../appointments/domain/entities/appointment_entity.dart';
import '../../domain/entities/doctor_payment_info_entity.dart';
import '../../domain/entities/payment_entities.dart';
import '../../domain/repos/payment_repository.dart';
import '../models/doctor_payment_info_model.dart';
import '../models/payment_models.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final ApiClient _apiClient;

  const PaymentRepositoryImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<ApiResult<PaymentIntentEntity>> initiatePayment({
    required String doctorProfileId,
    required DateTime scheduledAt,
    String? locationName,
    required PaymentMethod paymentMethod,
    String? walletPhone,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.paymentInitiate,
        data: {
          'doctorProfileId': doctorProfileId,
          'scheduledAt': scheduledAt.toUtc().toIso8601String(),
          if (locationName != null) 'locationName': locationName,
          'paymentMethod': paymentMethod.index,
          if (walletPhone != null) 'walletPhone': walletPhone,
        },
        // Paymob's auth + order + payment_key chain can take 25+ seconds on a
        // cold start — override the global 30s receive timeout for this call.
        options: Options(
          receiveTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 30),
        ),
      );
      final data = response.data['data'] as Map<String, dynamic>;
      final entity = PaymentIntentModel.fromJson(data).toEntity();
      return Success(entity.copyWithMessage(response.data['message']));
    } on DioException catch (e) {
      return Error(mapDioException(e));
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<ApiResult<AppointmentEntity>> confirmPayment({
    required String doctorProfileId,
    required DateTime scheduledAt,
    String? locationName,
    required String paymobOrderId,
    required String paymobTransactionId,
    required PaymentMethod paymentMethod,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.paymentConfirm,
        data: {
          'doctorProfileId': doctorProfileId,
          'scheduledAt': scheduledAt.toUtc().toIso8601String(),
          if (locationName != null) 'locationName': locationName,
          'paymobOrderId': paymobOrderId,
          'paymobTransactionId': paymobTransactionId,
          'paymentMethod': paymentMethod.index,
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
  Future<ApiResult<List<TransactionEntity>>> getPaymentHistory() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.paymentHistory);
      final data = response.data['data'] as List;
      final items =
          data.map((e) => TransactionModel.fromJson(e).toEntity()).toList();
      return Success(items);
    } on DioException catch (e) {
      return Error(mapDioException(e));
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<ApiResult<DoctorEarningsEntity>> getDoctorEarnings() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.paymentEarnings);
      final data = response.data['data'] as Map<String, dynamic>;
      return Success(DoctorEarningsModel.fromJson(data).toEntity());
    } on DioException catch (e) {
      return Error(mapDioException(e));
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<ApiResult<void>> markAsPaid(String appointmentId) async {
    try {
      await _apiClient.dio.put(ApiEndpoints.markAsPaid(appointmentId));
      return const Success(null);
    } on DioException catch (e) {
      return Error(mapDioException(e));
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<ApiResult<DoctorPaymentInfoEntity?>> getDoctorPaymentInfo() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.doctorPaymentInfo);
      final data = response.data['data'];
      if (data == null) return const Success(null);
      return Success(DoctorPaymentInfoModel.fromJson(data as Map<String, dynamic>).toEntity());
    } on DioException catch (e) {
      return Error(mapDioException(e));
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<ApiResult<void>> saveDoctorPaymentInfo(DoctorPaymentInfoEntity info) async {
    try {
      await _apiClient.dio.put(
        ApiEndpoints.doctorPaymentInfo,
        data: DoctorPaymentInfoModel.fromEntity(info).toJson(),
      );
      return const Success(null);
    } on DioException catch (e) {
      return Error(mapDioException(e));
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }
}
