// Payment domain entities — pure Dart, no Flutter imports.

enum PaymentMethod { card, wallet, cash }

enum PaymentStatus { unpaid, pending, paid, refunded, failed }

class PaymentIntentEntity {
  final String? appointmentId;
  final String? paymentKey;
  final String? paymobOrderId;
  final int? iframeId;
  final double amount;
  final double platformFee;
  final double total;
  final bool requiresPayment;
  final String? message;
  /// Non-null for wallet payments — the URL to open in the webview.
  final String? redirectUrl;

  const PaymentIntentEntity({
    this.appointmentId,
    this.paymentKey,
    this.paymobOrderId,
    this.iframeId,
    required this.amount,
    required this.platformFee,
    required this.total,
    required this.requiresPayment,
    this.message,
    this.redirectUrl,
  });

  PaymentIntentEntity copyWithMessage(String? msg) => PaymentIntentEntity(
        appointmentId: appointmentId,
        paymentKey: paymentKey,
        paymobOrderId: paymobOrderId,
        iframeId: iframeId,
        amount: amount,
        platformFee: platformFee,
        total: total,
        requiresPayment: requiresPayment,
        redirectUrl: redirectUrl,
        message: msg ?? message,
      );
}

class TransactionEntity {
  final String id;
  final String appointmentId;
  final double amount;
  final double platformFee;
  final double doctorEarnings;
  final String paymentMethod;
  final String status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? doctorName;
  final String? patientName;

  const TransactionEntity({
    required this.id,
    required this.appointmentId,
    required this.amount,
    required this.platformFee,
    required this.doctorEarnings,
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.doctorName,
    this.patientName,
  });
}

class DoctorEarningsEntity {
  final double totalEarnings;
  final double pendingBalance;
  final double withdrawnAmount;
  final int totalTransactions;

  const DoctorEarningsEntity({
    required this.totalEarnings,
    required this.pendingBalance,
    required this.withdrawnAmount,
    required this.totalTransactions,
  });
}
