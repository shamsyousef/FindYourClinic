sealed class DoctorShellProfileState {}

class DoctorShellProfileInitial extends DoctorShellProfileState {}

class DoctorShellProfileLoading extends DoctorShellProfileState {}

class DoctorShellProfileLoaded extends DoctorShellProfileState {
  final String fullName;
  final String? profileImageUrl;
  final double avgRating;
  final int totalPatients;
  final int totalReviews;

  DoctorShellProfileLoaded({
    required this.fullName,
    this.profileImageUrl,
    required this.avgRating,
    required this.totalPatients,
    required this.totalReviews,
  });
}

class DoctorShellProfileError extends DoctorShellProfileState {
  final String message;
  DoctorShellProfileError(this.message);
}
