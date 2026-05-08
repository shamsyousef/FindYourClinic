import '../../../../core/utils/date_utils.dart';
import '../../domain/entities/appointment_entity.dart';

class AppointmentModel {
  final String id;
  final String patientId;
  final String doctorProfileId;
  final String doctorUserId;
  final DateTime scheduledAt;
  final String? locationName;
  final String status;
  final DateTime createdAt;
  final String relatedPersonName;
  final String? relatedPersonImageUrl;
  final String? specialty;
  final String paymentStatus;
  final String? paymentMethod;
  final double? amountPaid;

  const AppointmentModel({
    required this.id,
    required this.patientId,
    required this.doctorProfileId,
    required this.doctorUserId,
    required this.scheduledAt,
    this.locationName,
    required this.status,
    required this.createdAt,
    required this.relatedPersonName,
    this.relatedPersonImageUrl,
    this.specialty,
    this.paymentStatus = 'Unpaid',
    this.paymentMethod,
    this.amountPaid,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id'],
      patientId: json['patientId'],
      doctorProfileId: json['doctorProfileId'],
      doctorUserId: json['doctorUserId'],
      scheduledAt: parseServerDateTime(json['scheduledAt']),
      locationName: json['locationName'],
      status: json['status'] ?? 'Scheduled',
      createdAt: parseServerDateTime(json['createdAt']),
      relatedPersonName: json['relatedPersonName'] ?? '',
      relatedPersonImageUrl: json['relatedPersonImageUrl'],
      specialty: json['specialty'],
      paymentStatus: json['paymentStatus'] ?? 'Unpaid',
      paymentMethod: json['paymentMethod'],
      amountPaid: (json['amountPaid'] as num?)?.toDouble(),
    );
  }

  AppointmentEntity toEntity() => AppointmentEntity(
        id: id,
        patientId: patientId,
        doctorProfileId: doctorProfileId,
        doctorUserId: doctorUserId,
        scheduledAt: scheduledAt,
        locationName: locationName,
        status: _parseStatus(status),
        createdAt: createdAt,
        relatedPersonName: relatedPersonName,
        relatedPersonImageUrl: relatedPersonImageUrl,
        specialty: specialty,
        paymentStatus: _parsePaymentStatus(paymentStatus),
        paymentMethod: _parsePaymentMethod(paymentMethod),
        amountPaid: amountPaid,
      );

  static AppointmentStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return AppointmentStatus.confirmed;
      case 'cancelled':
        return AppointmentStatus.cancelled;
      case 'completed':
        return AppointmentStatus.completed;
      case 'pendingpayment':
        return AppointmentStatus.pendingPayment;
      default:
        return AppointmentStatus.scheduled;
    }
  }

  static AppointmentPaymentStatus _parsePaymentStatus(String raw) {
    switch (raw.toLowerCase()) {
      case 'paid':
        return AppointmentPaymentStatus.paid;
      case 'pending':
        return AppointmentPaymentStatus.pending;
      case 'refunded':
        return AppointmentPaymentStatus.refunded;
      case 'failed':
        return AppointmentPaymentStatus.failed;
      default:
        return AppointmentPaymentStatus.unpaid;
    }
  }

  static AppointmentPaymentMethod? _parsePaymentMethod(String? raw) {
    if (raw == null) return null;
    switch (raw.toLowerCase()) {
      case 'cash':
        return AppointmentPaymentMethod.cash;
      case 'card':
        return AppointmentPaymentMethod.card;
      case 'wallet':
        return AppointmentPaymentMethod.wallet;
      default:
        return null;
    }
  }
}
