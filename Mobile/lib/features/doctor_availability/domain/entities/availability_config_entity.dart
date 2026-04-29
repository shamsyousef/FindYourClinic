// Domain entities for Doctor Availability management.
// Pure Dart — no Flutter imports.

class AvailabilityConfigEntity {
  final String id;
  final String doctorProfileId;
  final String dayOfWeek;
  final String startTime;
  final String endTime;
  final bool isActive;

  const AvailabilityConfigEntity({
    required this.id,
    required this.doctorProfileId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.isActive,
  });
}
