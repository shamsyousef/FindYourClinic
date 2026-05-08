import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/payment_entities.dart';
import '../cubits/paymob_webview_cubit.dart';
import '../cubits/paymob_webview_state.dart';


class PaymobWebViewScreen extends StatelessWidget {
  final PaymentIntentEntity intent;
  final String doctorProfileId;
  final DateTime scheduledAt;
  final String? locationName;
  final PaymentMethod paymentMethod;

  const PaymobWebViewScreen({
    super.key,
    required this.intent,
    required this.doctorProfileId,
    required this.scheduledAt,
    this.locationName,
    required this.paymentMethod,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<PaymobWebViewCubit>()..load(intent),
      child: _PaymobWebViewBody(
        doctorProfileId: doctorProfileId,
        scheduledAt: scheduledAt,
        locationName: locationName,
        paymentMethod: paymentMethod,
      ),
    );
  }
}

class _PaymobWebViewBody extends StatefulWidget {
  final String doctorProfileId;
  final DateTime scheduledAt;
  final String? locationName;
  final PaymentMethod paymentMethod;

  const _PaymobWebViewBody({
    required this.doctorProfileId,
    required this.scheduledAt,
    this.locationName,
    required this.paymentMethod,
  });

  @override
  State<_PaymobWebViewBody> createState() => _PaymobWebViewBodyState();
}

class _PaymobWebViewBodyState extends State<_PaymobWebViewBody> {
  WebViewController? _controller;
  bool _redirectHandled = false;
  int _loadProgress = 0;

  void _initController(String iframeUrl) {
    if (_controller != null) return;
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) => setState(() => _loadProgress = p),
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri != null && _isPaymobResult(uri)) {
              _handleResult(uri);
              // Block the WebView from actually loading the post-pay page.
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onUrlChange: (change) {
            final uri =
                change.url == null ? null : Uri.tryParse(change.url!);
            if (uri != null && _isPaymobResult(uri)) {
              _handleResult(uri);
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(iframeUrl));
  }

  bool _isPaymobResult(Uri uri) {
    // Paymob redirects to whatever "Response URL" is configured in the dashboard
    // (could be our backend URL, a deep link, etc.). Detect by payload shape, not host.
    final params = uri.queryParameters;
    return params.containsKey('success') && params.containsKey('txn_response_code');
  }

  void _handleResult(Uri uri) {
    if (_redirectHandled) return;
    _redirectHandled = true;
    context.read<PaymobWebViewCubit>().handleRedirect(
          uri: uri,
          doctorProfileId: widget.doctorProfileId,
          scheduledAt: widget.scheduledAt,
          locationName: widget.locationName,
          paymentMethod: widget.paymentMethod,
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PaymobWebViewCubit, PaymobWebViewState>(
      listener: (context, state) {
        switch (state) {
          case PaymobWebViewReady():
            _initController(state.iframeUrl);
          case PaymobWebViewSuccess():
            GoRouter.of(context).go('/booking-success', extra: {
              'isConfirmed': true,
              'doctorName': state.doctorName,
              'scheduledAt': state.scheduledAt,
              'appointmentId': state.appointmentId,
            });
          case PaymobWebViewFailure():
            _showResultDialog(context, message: state.message);
          default:
            break;
        }
      },
      builder: (context, state) {
        return PopScope(
          canPop: state is! PaymobWebViewConfirming,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && state is PaymobWebViewConfirming) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Confirming payment, please wait…'),
                ),
              );
            }
          },
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Secure Payment'),
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => _confirmCancel(context, state),
              ),
            ),
            body: Stack(
              children: [
                if (_controller != null)
                  WebViewWidget(controller: _controller!)
                else
                  const Center(child: CircularProgressIndicator()),
                if (_loadProgress < 100 && _controller != null)
                  LinearProgressIndicator(
                    value: _loadProgress / 100,
                    minHeight: 3,
                    color: AppColors.primary,
                    backgroundColor:
                        AppColors.primary.withValues(alpha: 0.15),
                  ),
                if (state is PaymobWebViewConfirming)
                  _ConfirmingOverlay(),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmCancel(
      BuildContext context, PaymobWebViewState state) async {
    if (state is PaymobWebViewConfirming) return;
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel payment?'),
        content: const Text(
          'If you leave now, your booking will not be created.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Leave',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (!context.mounted) return;
    if (shouldCancel ?? false) Navigator.of(context).pop();
  }

  void _showResultDialog(BuildContext context, {required String message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            const Text(
              'Payment Failed',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop(); // close webview → back to checkout
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Try Again'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmingOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.55),
      child: const Center(
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 28, vertical: 22),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
                SizedBox(width: 16),
                Text('Confirming payment…',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
