// Domain entities for the Appointments feature.
// Pure Dart — no Flutter imports.

import '../../../../core/utils/date_utils.dart';

enum AppointmentStatus { scheduled, confirmed, cancelled, completed, pendingPayment }

extension AppointmentStatusLabels on AppointmentStatus {
  String get patientLabel => switch (this) {
        AppointmentStatus.scheduled => 'Pending',
        AppointmentStatus.confirmed => 'Confirmed',
        AppointmentStatus.cancelled => 'Cancelled',
        AppointmentStatus.completed => 'Completed',
        AppointmentStatus.pendingPayment => 'Awaiting Approval',
      };

  String get doctorLabel => switch (this) {
        AppointmentStatus.scheduled => 'New Request',
        AppointmentStatus.confirmed => 'Confirmed',
        AppointmentStatus.cancelled => 'Cancelled',
        AppointmentStatus.completed => 'Completed',
        AppointmentStatus.pendingPayment => 'Cash - Pending Approval',
      };
}

enum AppointmentPaymentStatus { unpaid, pending, paid, refunded, failed }

enum AppointmentPaymentMethod { cash, card, wallet }

class AppointmentEntity {
  final String id;
  final String patientId;
  final String doctorProfileId;
  final String doctorUserId;
  final DateTime scheduledAt;
  final String? locationName;
  final AppointmentStatus status;
  final DateTime createdAt;
  final String relatedPersonName;
  final String? relatedPersonImageUrl;
  final String? specialty;
  final AppointmentPaymentStatus paymentStatus;
  final AppointmentPaymentMethod? paymentMethod;
  final double? amountPaid;

  const AppointmentEntity({
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
    this.paymentStatus = AppointmentPaymentStatus.unpaid,
    this.paymentMethod,
    this.amountPaid,
  });

  /// True for cash bookings the doctor approved but hasn't been paid for yet —
  /// the doctor should see a "Mark as Paid" action.
  bool get needsCashPayment =>
      paymentMethod == AppointmentPaymentMethod.cash &&
      paymentStatus != AppointmentPaymentStatus.paid &&
      (status == AppointmentStatus.scheduled ||
          status == AppointmentStatus.confirmed ||
          status == AppointmentStatus.completed);

  static const _appointmentDuration = Duration(minutes: 30);

  /// Returns the effective status, auto-completing confirmed/scheduled
  /// appointments whose time has fully passed (client-side optimistic display).
  AppointmentStatus get effectiveStatus {
    if (status == AppointmentStatus.confirmed || status == AppointmentStatus.scheduled) {
      final endTime = scheduledAt.add(_appointmentDuration);
      if (nowCairo().isAfter(endTime)) {
        return AppointmentStatus.completed;
      }
    }
    return status;
  }

  /// Whether this appointment is upcoming (future + active status).
  bool get isUpcoming =>
      (status == AppointmentStatus.scheduled ||
          status == AppointmentStatus.confirmed) &&
      scheduledAt.isAfter(nowCairo());

  /// Whether this appointment is today.
  bool get isToday {
    final now = nowCairo();
    return scheduledAt.year == now.year &&
        scheduledAt.month == now.month &&
        scheduledAt.day == now.day;
  }
}
