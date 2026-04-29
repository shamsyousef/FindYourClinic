import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_result.dart';
import '../../domain/usecases/patient_profile_usecases.dart';
import 'patient_profile_state.dart';

class PatientProfileCubit extends Cubit<PatientProfileState> {
  final GetPatientProfileUseCase _getProfile;
  final UpdatePatientProfileUseCase _updateProfile;

  PatientProfileCubit({
    required GetPatientProfileUseCase getProfile,
    required UpdatePatientProfileUseCase updateProfile,
  })  : _getProfile = getProfile,
        _updateProfile = updateProfile,
        super(PatientProfileInitial());

  Future<void> loadProfile() async {
    emit(PatientProfileLoading());
    final result = await _getProfile();
    switch (result) {
      case Success(:final data):
        emit(PatientProfileLoaded(data));
      case Error(:final failure):
        emit(PatientProfileError(failure.message));
    }
  }

  Future<void> updateProfile({
    required String firstName,
    required String lastName,
  }) async {
    final current = state;
    if (current is! PatientProfileLoaded) return;
    emit(PatientProfileUpdating(current.profile));
    final result =
        await _updateProfile(firstName: firstName, lastName: lastName);
    switch (result) {
      case Success(:final data):
        emit(PatientProfileUpdateSuccess(data));
        emit(PatientProfileLoaded(data));
      case Error(:final failure):
        emit(PatientProfileLoaded(current.profile));
        emit(PatientProfileError(failure.message));
    }
  }
}
