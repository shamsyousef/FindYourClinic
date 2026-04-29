import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_result.dart';
import '../../../doctor_home/domain/usecases/get_doctor_dashboard_usecase.dart';
import '../../../patient_profile/domain/usecases/patient_profile_usecases.dart';
import 'doctor_shell_profile_state.dart';

class DoctorShellProfileCubit extends Cubit<DoctorShellProfileState> {
  final GetPatientProfileUseCase _getProfile;
  final GetDoctorDashboardUseCase _getDashboard;

  DoctorShellProfileCubit({
    required GetPatientProfileUseCase getProfile,
    required GetDoctorDashboardUseCase getDashboard,
  })  : _getProfile = getProfile,
        _getDashboard = getDashboard,
        super(DoctorShellProfileInitial());

  Future<void> loadProfile() async {
    emit(DoctorShellProfileLoading());

    final profileFuture = _getProfile();
    final dashboardFuture = _getDashboard();
    final results = await Future.wait([profileFuture, dashboardFuture]);

    final profileResult = results[0];
    final dashboardResult = results[1];

    if (profileResult is Error) {
      emit(DoctorShellProfileError((profileResult as Error).failure.message));
      return;
    }
    if (dashboardResult is Error) {
      emit(DoctorShellProfileError((dashboardResult as Error).failure.message));
      return;
    }

    final profile = (profileResult as Success).data;
    final dashboard = (dashboardResult as Success).data;

    emit(DoctorShellProfileLoaded(
      fullName: profile.fullName,
      profileImageUrl: profile.profileImageUrl,
      avgRating: dashboard.performance.averageRating,
      totalPatients: dashboard.performance.patientsThisMonth,
      totalReviews: dashboard.performance.totalReviews,
    ));
  }
}
