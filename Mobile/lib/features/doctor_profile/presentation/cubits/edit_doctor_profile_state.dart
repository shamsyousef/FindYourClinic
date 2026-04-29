import '../../domain/entities/doctor_profile_entities.dart';

sealed class EditDoctorProfileState {
  const EditDoctorProfileState();
}

class EditDoctorProfileInitial extends EditDoctorProfileState {}

class EditDoctorProfileLoading extends EditDoctorProfileState {}

class EditDoctorProfileLoaded extends EditDoctorProfileState {
  final DoctorDetails details;
  const EditDoctorProfileLoaded(this.details);
}

class EditDoctorProfileSaving extends EditDoctorProfileState {
  final DoctorDetails current;
  const EditDoctorProfileSaving(this.current);
}

class EditDoctorProfileSaved extends EditDoctorProfileState {}

class EditDoctorProfileError extends EditDoctorProfileState {
  final String message;
  const EditDoctorProfileError(this.message);
}
