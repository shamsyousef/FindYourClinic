// Domain entities for doctor profile detail view.
// Pure Dart — no Flutter imports.

class DoctorDetails {
  final String doctorId;
  final String doctorProfileId;
  final String fullName;
  final String specialty;
  final String? profileImageUrl;
  final String? clinicName;
  final String? clinicAddress;
  final double? latitude;
  final double? longitude;
  final double consultationFee;
  final int experienceYears;
  final String? bio;
  final double avgRating;
  final int reviewsCount;
  final DateTime? nextAvailableSlot;

  const DoctorDetails({
    required this.doctorId,
    required this.doctorProfileId,
    required this.fullName,
    required this.specialty,
    this.profileImageUrl,
    this.clinicName,
    this.clinicAddress,
    this.latitude,
    this.longitude,
    required this.consultationFee,
    required this.experienceYears,
    this.bio,
    required this.avgRating,
    required this.reviewsCount,
    this.nextAvailableSlot,
  });
}

class DoctorReview {
  final String id;
  final String patientName;
  final String? patientImageUrl;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  const DoctorReview({
    required this.id,
    required this.patientName,
    this.patientImageUrl,
    required this.rating,
    this.comment,
    required this.createdAt,
  });
}

class AvailabilitySlot {
  final String dayOfWeek;
  final String startTime;
  final String endTime;

  const AvailabilitySlot({
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
  });
}

class UpdateDoctorProfileParams {
  final String? bio;
  final String? clinicName;
  final String? clinicAddress;
  final double? latitude;
  final double? longitude;
  final double? consultationFee;
  final int? experienceYears;

  const UpdateDoctorProfileParams({
    this.bio,
    this.clinicName,
    this.clinicAddress,
    this.latitude,
    this.longitude,
    this.consultationFee,
    this.experienceYears,
  });
}
