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
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id'],
      patientId: json['patientId'],
      doctorProfileId: json['doctorProfileId'],
      doctorUserId: json['doctorUserId'],
      scheduledAt: DateTime.parse(json['scheduledAt']),
      locationName: json['locationName'],
      status: json['status'] ?? 'Scheduled',
      createdAt: DateTime.parse(json['createdAt']),
      relatedPersonName: json['relatedPersonName'] ?? '',
      relatedPersonImageUrl: json['relatedPersonImageUrl'],
      specialty: json['specialty'],
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
      );

  static AppointmentStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return AppointmentStatus.confirmed;
      case 'cancelled':
        return AppointmentStatus.cancelled;
      case 'completed':
        return AppointmentStatus.completed;
      default:
        return AppointmentStatus.scheduled;
    }
  }
}
