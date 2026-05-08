import '../../domain/entities/payment_entities.dart';

sealed class CheckoutState {}

class CheckoutInitial extends CheckoutState {}

class CheckoutLoading extends CheckoutState {}

class CheckoutPaymentReady extends CheckoutState {
  final PaymentIntentEntity intent;
  CheckoutPaymentReady(this.intent);
}

class CheckoutCashSuccess extends CheckoutState {
  final String appointmentId;
  final String message;
  CheckoutCashSuccess({required this.appointmentId, required this.message});
}

class CheckoutPaymentSuccess extends CheckoutState {
  final String message;
  CheckoutPaymentSuccess(this.message);
}

class CheckoutError extends CheckoutState {
  final String message;
  CheckoutError(this.message);
}
