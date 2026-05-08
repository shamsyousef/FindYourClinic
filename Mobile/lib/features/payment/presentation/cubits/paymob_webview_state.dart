sealed class PaymobWebViewState {
  const PaymobWebViewState();
}

class PaymobWebViewLoading extends PaymobWebViewState {
  const PaymobWebViewLoading();
}

class PaymobWebViewReady extends PaymobWebViewState {
  final String iframeUrl;
  const PaymobWebViewReady(this.iframeUrl);
}

class PaymobWebViewConfirming extends PaymobWebViewState {
  const PaymobWebViewConfirming();
}

class PaymobWebViewSuccess extends PaymobWebViewState {
  final String appointmentId;
  final String doctorName;
  final DateTime scheduledAt;
  const PaymobWebViewSuccess({
    required this.appointmentId,
    required this.doctorName,
    required this.scheduledAt,
  });
}

class PaymobWebViewFailure extends PaymobWebViewState {
  final String message;
  const PaymobWebViewFailure(this.message);
}
