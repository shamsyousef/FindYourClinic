import '../../domain/entities/user_profile_entity.dart';

sealed class PatientProfileState {}

class PatientProfileInitial extends PatientProfileState {}

class PatientProfileLoading extends PatientProfileState {}

class PatientProfileLoaded extends PatientProfileState {
  final UserProfileEntity profile;
  PatientProfileLoaded(this.profile);
}

class PatientProfileUpdating extends PatientProfileState {
  final UserProfileEntity profile;
  PatientProfileUpdating(this.profile);
}

class PatientProfileUpdateSuccess extends PatientProfileState {
  final UserProfileEntity profile;
  PatientProfileUpdateSuccess(this.profile);
}

class PatientProfileError extends PatientProfileState {
  final String message;
  PatientProfileError(this.message);
}
