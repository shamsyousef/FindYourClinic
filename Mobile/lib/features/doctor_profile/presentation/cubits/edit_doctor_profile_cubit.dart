import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_result.dart';
import '../../domain/entities/doctor_profile_entities.dart';
import '../../domain/usecases/doctor_profile_usecases.dart';
import 'edit_doctor_profile_state.dart';

class EditDoctorProfileCubit extends Cubit<EditDoctorProfileState> {
  final GetDoctorDetailsUseCase _getDetails;
  final UpdateDoctorProfileUseCase _updateProfile;

  EditDoctorProfileCubit({
    required GetDoctorDetailsUseCase getDetails,
    required UpdateDoctorProfileUseCase updateProfile,
  })  : _getDetails = getDetails,
        _updateProfile = updateProfile,
        super(EditDoctorProfileInitial());

  Future<void> loadProfile(String doctorUserId) async {
    emit(EditDoctorProfileLoading());
    final result = await _getDetails(doctorUserId);
    switch (result) {
      case Success(:final data):
        emit(EditDoctorProfileLoaded(data));
      case Error(:final failure):
        emit(EditDoctorProfileError(failure.message));
    }
  }

  Future<void> saveProfile(UpdateDoctorProfileParams params) async {
    final current = state;
    if (current is! EditDoctorProfileLoaded) return;
    emit(EditDoctorProfileSaving(current.details));
    final result = await _updateProfile(params);
    switch (result) {
      case Success():
        emit(EditDoctorProfileSaved());
      case Error(:final failure):
        emit(EditDoctorProfileLoaded(current.details));
        emit(EditDoctorProfileError(failure.message));
    }
  }
}
