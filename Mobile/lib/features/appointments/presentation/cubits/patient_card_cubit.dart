import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_result.dart';
import '../../../health_records/domain/entities/health_record_entity.dart';
import '../../../health_records/domain/usecases/health_record_usecases.dart';
import '../../../patient_profile/domain/entities/user_profile_entity.dart';
import '../../../patient_profile/domain/usecases/patient_profile_usecases.dart';

// ─── State ───────────────────────────────────────────────────────────────────

sealed class PatientCardState {
  const PatientCardState();
}

final class PatientCardInitial extends PatientCardState {
  const PatientCardInitial();
}

final class PatientCardLoading extends PatientCardState {
  const PatientCardLoading();
}

final class PatientCardLoaded extends PatientCardState {
  final UserProfileEntity profile;
  final List<HealthRecordEntity> records;
  const PatientCardLoaded({required this.profile, required this.records});
}

final class PatientCardError extends PatientCardState {
  final String message;
  const PatientCardError(this.message);
}

// ─── Cubit ───────────────────────────────────────────────────────────────────

class PatientCardCubit extends Cubit<PatientCardState> {
  final GetPatientProfileForDoctorUseCase _getProfile;
  final GetPatientRecordsForDoctorUseCase _getRecords;

  PatientCardCubit({
    required GetPatientProfileForDoctorUseCase getProfile,
    required GetPatientRecordsForDoctorUseCase getRecords,
  })  : _getProfile = getProfile,
        _getRecords = getRecords,
        super(const PatientCardInitial());

  Future<void> load(String patientId) async {
    emit(const PatientCardLoading());

    final profileFuture = _getProfile(patientId);
    final recordsFuture = _getRecords(patientId);

    final profileResult = await profileFuture;
    final recordsResult = await recordsFuture;

    if (profileResult case Error(:final failure)) {
      emit(PatientCardError(failure.message));
      return;
    }

    final profile = (profileResult as Success<UserProfileEntity>).data;
    final records = switch (recordsResult) {
      Success(:final data) => data,
      Error() => <HealthRecordEntity>[],
    };

    emit(PatientCardLoaded(profile: profile, records: records));
  }
}
