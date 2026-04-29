import '../../domain/entities/home_entities.dart';

/// JSON deserialization models for the home summary API response.

class HomeSummaryModel {
  final UpcomingAppointmentModel? upcomingAppointment;
  final HealthSummaryModel healthSummary;
  final List<TopDoctorModel> topDoctors;
  final List<SpecialtySummaryModel> specialties;

  const HomeSummaryModel({
    this.upcomingAppointment,
    required this.healthSummary,
    required this.topDoctors,
    required this.specialties,
  });

  factory HomeSummaryModel.fromJson(Map<String, dynamic> json) {
    return HomeSummaryModel(
      upcomingAppointment: json['upcomingAppointment'] != null
          ? UpcomingAppointmentModel.fromJson(json['upcomingAppointment'])
          : null,
      healthSummary: HealthSummaryModel.fromJson(json['healthSummary']),
      topDoctors: (json['topDoctors'] as List)
          .map((e) => TopDoctorModel.fromJson(e))
          .toList(),
      specialties: (json['specialties'] as List)
          .map((e) => SpecialtySummaryModel.fromJson(e))
          .toList(),
    );
  }

  HomeSummary toEntity() => HomeSummary(
        upcomingAppointment: upcomingAppointment?.toEntity(),
        healthSummary: healthSummary.toEntity(),
        topDoctors: topDoctors.map((e) => e.toEntity()).toList(),
        specialties: specialties.map((e) => e.toEntity()).toList(),
      );
}

class UpcomingAppointmentModel {
  final String appointmentId;
  final DateTime scheduledAt;
  final String status;
  final String? locationName;
  final String doctorId;
  final String doctorName;
  final String specialty;

  const UpcomingAppointmentModel({
    required this.appointmentId,
    required this.scheduledAt,
    required this.status,
    this.locationName,
    required this.doctorId,
    required this.doctorName,
    required this.specialty,
  });

  factory UpcomingAppointmentModel.fromJson(Map<String, dynamic> json) {
    return UpcomingAppointmentModel(
      appointmentId: json['appointmentId'],
      scheduledAt: DateTime.parse(json['scheduledAt']),
      status: json['status'],
      locationName: json['locationName'],
      doctorId: json['doctorId'],
      doctorName: json['doctorName'],
      specialty: json['specialty'],
    );
  }

  UpcomingAppointment toEntity() => UpcomingAppointment(
        appointmentId: appointmentId,
        scheduledAt: scheduledAt,
        status: status,
        locationName: locationName,
        doctorId: doctorId,
        doctorName: doctorName,
        specialty: specialty,
      );
}

class HealthSummaryModel {
  final int medicalRecordsCount;
  final String? latestHeartRate;
  final String? latestBloodPressure;

  const HealthSummaryModel({
    required this.medicalRecordsCount,
    this.latestHeartRate,
    this.latestBloodPressure,
  });

  factory HealthSummaryModel.fromJson(Map<String, dynamic> json) {
    return HealthSummaryModel(
      medicalRecordsCount: json['medicalRecordsCount'] ?? 0,
      latestHeartRate: json['latestHeartRate'],
      latestBloodPressure: json['latestBloodPressure'],
    );
  }

  HealthSummary toEntity() => HealthSummary(
        medicalRecordsCount: medicalRecordsCount,
        latestHeartRate: latestHeartRate,
        latestBloodPressure: latestBloodPressure,
      );
}

class TopDoctorModel {
  final String doctorId;
  final String fullName;
  final String specialty;
  final double rating;
  final int reviewsCount;
  final double consultationFee;
  final double? latitude;
  final double? longitude;
  final String? profileImageUrl;

  const TopDoctorModel({
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

  factory TopDoctorModel.fromJson(Map<String, dynamic> json) {
    return TopDoctorModel(
      doctorId: json['doctorId'],
      fullName: json['fullName'],
      specialty: json['specialty'],
      rating: (json['rating'] as num).toDouble(),
      reviewsCount: json['reviewsCount'] ?? 0,
      consultationFee: (json['consultationFee'] as num).toDouble(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      profileImageUrl: json['profileImageUrl'] as String?,
    );
  }

  TopDoctor toEntity() => TopDoctor(
        doctorId: doctorId,
        fullName: fullName,
        specialty: specialty,
        rating: rating,
        reviewsCount: reviewsCount,
        consultationFee: consultationFee,
        latitude: latitude,
        longitude: longitude,
        profileImageUrl: profileImageUrl,
      );
}

class SpecialtySummaryModel {
  final String id;
  final String name;
  final String? iconUrl;

  const SpecialtySummaryModel({
    required this.id,
    required this.name,
    this.iconUrl,
  });

  factory SpecialtySummaryModel.fromJson(Map<String, dynamic> json) {
    return SpecialtySummaryModel(
      id: json['id'],
      name: json['name'],
      iconUrl: json['iconUrl'],
    );
  }

  SpecialtySummary toEntity() => SpecialtySummary(
        id: id,
        name: name,
        iconUrl: iconUrl,
      );
}
