import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_result.dart';
import '../../domain/entities/payment_entities.dart';
import '../../domain/usecases/payment_usecases.dart';
import 'paymob_webview_state.dart';

class PaymobWebViewCubit extends Cubit<PaymobWebViewState> {
  final ConfirmPaymentUseCase _confirmPayment;

  PaymobWebViewCubit({required ConfirmPaymentUseCase confirmPayment})
      : _confirmPayment = confirmPayment,
        super(const PaymobWebViewLoading());

  /// Resolves the URL to open and emits Ready.
  /// Deferred via microtask so BlocConsumer subscribes before the state fires.
  void load(PaymentIntentEntity intent) {
    Future.microtask(() {
      if (isClosed) return;

      // Wallet payments: backend already called Paymob's wallet pay API and
      // returned the provider redirect URL directly.
      if (intent.redirectUrl != null) {
        if (intent.redirectUrl!.isEmpty) {
          emit(const PaymobWebViewFailure(
              'Wallet payment could not be initiated. Please check your wallet phone number and try again.'));
          return;
        }
        emit(PaymobWebViewReady(intent.redirectUrl!));
        return;
      }

      // Card payments: build the standard iframe URL.
      if (intent.iframeId == null || intent.paymentKey == null) {
        emit(const PaymobWebViewFailure(
            'Payment session is incomplete. Please try again.'));
        return;
      }
      final url =
          'https://accept.paymob.com/api/acceptance/iframes/${intent.iframeId}'
          '?payment_token=${intent.paymentKey}';
      emit(PaymobWebViewReady(url));
    });
  }

  /// Called by the WebView when Paymob redirects with payment result params.
  /// Returns true if the URL was a Paymob result callback (handled).
  Future<void> handleRedirect({
    required Uri uri,
    required String doctorProfileId,
    required DateTime scheduledAt,
    String? locationName,
    required PaymentMethod paymentMethod,
  }) async {
    final params = uri.queryParameters;

    // Paymob signals failure with success=false or txn_response_code != APPROVED.
    final success = params['success']?.toLowerCase() == 'true';
    final responseCode = params['txn_response_code']?.toUpperCase();
    final orderId = params['order'];
    final txnId = params['id'];

    // Card success: APPROVED. Wallet success: 200.
    final isApproved = responseCode == 'APPROVED' || responseCode == '200';

    if (!success || !isApproved) {
      final reason = params['data.message'] ?? 'Payment was not approved.';
      emit(PaymobWebViewFailure(reason));
      return;
    }

    if (orderId == null || txnId == null) {
      emit(const PaymobWebViewFailure(
          'Payment confirmation failed: missing transaction reference.'));
      return;
    }

    emit(const PaymobWebViewConfirming());

    final result = await _confirmPayment(
      doctorProfileId: doctorProfileId,
      scheduledAt: scheduledAt,
      locationName: locationName,
      paymobOrderId: orderId,
      paymobTransactionId: txnId,
      paymentMethod: paymentMethod,
    );

    switch (result) {
      case Success(:final data):
        emit(PaymobWebViewSuccess(
          appointmentId: data.id,
          doctorName: data.relatedPersonName,
          scheduledAt: data.scheduledAt,
        ));
      case Error(failure: final failure):
        emit(PaymobWebViewFailure(failure.message));
    }
  }
}
