import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_result.dart';
import '../../domain/entities/payment_entities.dart';
import '../../domain/usecases/payment_usecases.dart';
import 'checkout_state.dart';

class CheckoutCubit extends Cubit<CheckoutState> {
  final InitiatePaymentUseCase _initiatePayment;
  final ConfirmPaymentUseCase _confirmPayment;

  CheckoutCubit({
    required InitiatePaymentUseCase initiatePayment,
    required ConfirmPaymentUseCase confirmPayment,
  })  : _initiatePayment = initiatePayment,
        _confirmPayment = confirmPayment,
        super(CheckoutInitial());

  Future<void> initiate({
    required String doctorProfileId,
    required DateTime scheduledAt,
    String? locationName,
    required PaymentMethod paymentMethod,
    String? walletPhone,
  }) async {
    emit(CheckoutLoading());

    final result = await _initiatePayment(
      doctorProfileId: doctorProfileId,
      scheduledAt: scheduledAt,
      locationName: locationName,
      paymentMethod: paymentMethod,
      walletPhone: walletPhone,
    );

    switch (result) {
      case Success(data: final intent):
        if (!intent.requiresPayment) {
          // Cash — appointment created directly
          emit(CheckoutCashSuccess(
            appointmentId: intent.appointmentId ?? '',
            message: intent.message ?? 'Appointment booked. Waiting for doctor approval.',
          ));
        } else {
          // Card/Wallet — need payment
          emit(CheckoutPaymentReady(intent));
        }
      case Error(failure: final failure):
        emit(CheckoutError(failure.message));
    }
  }

  Future<void> confirmOnlinePayment({
    required String doctorProfileId,
    required DateTime scheduledAt,
    String? locationName,
    required String paymobOrderId,
    required String paymobTransactionId,
    required PaymentMethod paymentMethod,
  }) async {
    emit(CheckoutLoading());

    final result = await _confirmPayment(
      doctorProfileId: doctorProfileId,
      scheduledAt: scheduledAt,
      locationName: locationName,
      paymobOrderId: paymobOrderId,
      paymobTransactionId: paymobTransactionId,
      paymentMethod: paymentMethod,
    );

    switch (result) {
      case Success():
        emit(CheckoutPaymentSuccess('Payment confirmed. Appointment booked!'));
      case Error(failure: final failure):
        emit(CheckoutError(failure.message));
    }
  }
}
