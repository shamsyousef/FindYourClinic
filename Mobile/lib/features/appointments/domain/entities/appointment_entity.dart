// Domain entities for the Appointments feature.
// Pure Dart — no Flutter imports.

enum AppointmentStatus { scheduled, confirmed, cancelled, completed }

extension AppointmentStatusLabels on AppointmentStatus {
  String get patientLabel => switch (this) {
        AppointmentStatus.scheduled => 'Pending',
        AppointmentStatus.confirmed => 'Confirmed',
        AppointmentStatus.cancelled => 'Cancelled',
        AppointmentStatus.completed => 'Completed',
      };

  String get doctorLabel => switch (this) {
        AppointmentStatus.scheduled => 'New Request',
        AppointmentStatus.confirmed => 'Confirmed',
        AppointmentStatus.cancelled => 'Cancelled',
        AppointmentStatus.completed => 'Completed',
      };
}

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
  });

  /// Whether this appointment is upcoming (future + active status).
  bool get isUpcoming =>
      (status == AppointmentStatus.scheduled ||
          status == AppointmentStatus.confirmed) &&
      scheduledAt.isAfter(DateTime.now());

  /// Whether this appointment is today.
  bool get isToday {
    final now = DateTime.now();
    return scheduledAt.year == now.year &&
        scheduledAt.month == now.month &&
        scheduledAt.day == now.day;
  }
}
