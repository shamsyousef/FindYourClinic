// Domain entities for the patient home dashboard.
// Pure Dart — no Flutter imports.

class HomeSummary {
  final UpcomingAppointment? upcomingAppointment;
  final HealthSummary healthSummary;
  final List<TopDoctor> topDoctors;
  final List<SpecialtySummary> specialties;

  const HomeSummary({
    this.upcomingAppointment,
    required this.healthSummary,
    required this.topDoctors,
    required this.specialties,
  });
}

class UpcomingAppointment {
  final String appointmentId;
  final DateTime scheduledAt;
  final String status;
  final String? locationName;
  final String doctorId;
  final String doctorName;
  final String specialty;

  const UpcomingAppointment({
    required this.appointmentId,
    required this.scheduledAt,
    required this.status,
    this.locationName,
    required this.doctorId,
    required this.doctorName,
    required this.specialty,
  });
}

class HealthSummary {
  final int medicalRecordsCount;
  final String? latestHeartRate;
  final String? latestBloodPressure;

  const HealthSummary({
    required this.medicalRecordsCount,
    this.latestHeartRate,
    this.latestBloodPressure,
  });
}

class TopDoctor {
  final String doctorId;
  final String fullName;
  final String specialty;
  final double rating;
  final int reviewsCount;
  final double consultationFee;
  final double? latitude;
  final double? longitude;
  final String? profileImageUrl;

  const TopDoctor({
    required this.doctorId,
    required this.fullName,
    required this.specialty,
    required this.rating,
    required this.reviewsCount,
    required this.consultationFee,
    this.latitude,
    this.longitude,
    this.profileImageUrl,
  });
}

class SpecialtySummary {
  final String id;
  final String name;
  final String? iconUrl;

  const SpecialtySummary({
    required this.id,
    required this.name,
    this.iconUrl,
  });
}
