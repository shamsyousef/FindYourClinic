import '../../domain/entities/payment_entities.dart';

class PaymentIntentModel {
  final String? appointmentId;
  final String? paymentKey;
  final String? paymobOrderId;
  final int? iframeId;
  final double amount;
  final double platformFee;
  final double total;
  final bool requiresPayment;
  final String? redirectUrl;

  const PaymentIntentModel({
    this.appointmentId,
    this.paymentKey,
    this.paymobOrderId,
    this.iframeId,
    required this.amount,
    required this.platformFee,
    required this.total,
    required this.requiresPayment,
    this.redirectUrl,
  });

  factory PaymentIntentModel.fromJson(Map<String, dynamic> json) {
    return PaymentIntentModel(
      appointmentId: json['appointmentId'],
      paymentKey: json['paymentKey'],
      paymobOrderId: json['paymobOrderId'],
      iframeId: json['iframeId'],
      amount: (json['amount'] as num).toDouble(),
      platformFee: (json['platformFee'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      requiresPayment: json['requiresPayment'] ?? false,
      redirectUrl: json['redirectUrl'],
    );
  }

  PaymentIntentEntity toEntity() => PaymentIntentEntity(
        appointmentId: appointmentId,
        paymentKey: paymentKey,
        paymobOrderId: paymobOrderId,
        iframeId: iframeId,
        amount: amount,
        platformFee: platformFee,
        total: total,
        requiresPayment: requiresPayment,
        redirectUrl: redirectUrl,
      );
}

class TransactionModel {
  final String id;
  final String appointmentId;
  final double amount;
  final double platformFee;
  final double doctorEarnings;
  final String paymentMethod;
  final String status;
  final String createdAt;
  final String? completedAt;
  final String? doctorName;
  final String? patientName;

  const TransactionModel({
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

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'],
      appointmentId: json['appointmentId'],
      amount: (json['amount'] as num).toDouble(),
      platformFee: (json['platformFee'] as num).toDouble(),
      doctorEarnings: (json['doctorEarnings'] as num).toDouble(),
      paymentMethod: json['paymentMethod'] ?? '',
      status: json['status'] ?? '',
      createdAt: json['createdAt'],
      completedAt: json['completedAt'],
      doctorName: json['doctorName'],
      patientName: json['patientName'],
    );
  }

  TransactionEntity toEntity() => TransactionEntity(
        id: id,
        appointmentId: appointmentId,
        amount: amount,
        platformFee: platformFee,
        doctorEarnings: doctorEarnings,
        paymentMethod: paymentMethod,
        status: status,
        createdAt: DateTime.parse(createdAt),
        completedAt: completedAt != null ? DateTime.parse(completedAt!) : null,
        doctorName: doctorName,
        patientName: patientName,
      );
}

class DoctorEarningsModel {
  final double totalEarnings;
  final double pendingBalance;
  final double withdrawnAmount;
  final int totalTransactions;

  const DoctorEarningsModel({
    required this.totalEarnings,
    required this.pendingBalance,
    required this.withdrawnAmount,
    required this.totalTransactions,
  });

  factory DoctorEarningsModel.fromJson(Map<String, dynamic> json) {
    return DoctorEarningsModel(
      totalEarnings: (json['totalEarnings'] as num).toDouble(),
      pendingBalance: (json['pendingBalance'] as num).toDouble(),
      withdrawnAmount: (json['withdrawnAmount'] as num).toDouble(),
      totalTransactions: json['totalTransactions'] ?? 0,
    );
  }

  DoctorEarningsEntity toEntity() => DoctorEarningsEntity(
        totalEarnings: totalEarnings,
        pendingBalance: pendingBalance,
        withdrawnAmount: withdrawnAmount,
        totalTransactions: totalTransactions,
      );
}
