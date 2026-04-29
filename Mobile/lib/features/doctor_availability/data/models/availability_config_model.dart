import '../../domain/entities/availability_config_entity.dart';

class AvailabilityConfigModel {
  final String id;
  final String doctorProfileId;
  final String dayOfWeek;
  final String startTime;
  final String endTime;
  final bool isActive;

  const AvailabilityConfigModel({
    required this.id,
    required this.doctorProfileId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.isActive,
  });

  factory AvailabilityConfigModel.fromJson(Map<String, dynamic> json) {
    return AvailabilityConfigModel(
      id: json['id'],
      doctorProfileId: json['doctorProfileId'],
      dayOfWeek: json['dayOfWeek'],
      startTime: json['startTime'],
      endTime: json['endTime'],
      isActive: json['isActive'],
    );
  }

  AvailabilityConfigEntity toEntity() => AvailabilityConfigEntity(
        id: id,
        doctorProfileId: doctorProfileId,
        dayOfWeek: dayOfWeek,
        startTime: startTime,
        endTime: endTime,
        isActive: isActive,
      );
}
