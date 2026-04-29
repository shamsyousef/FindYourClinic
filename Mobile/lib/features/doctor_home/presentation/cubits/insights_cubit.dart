import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_result.dart';
import '../../domain/usecases/get_doctor_dashboard_usecase.dart';
import 'insights_state.dart';

class InsightsCubit extends Cubit<InsightsState> {
  final GetDoctorDashboardUseCase _getDashboard;

  InsightsCubit(this._getDashboard) : super(InsightsInitial());

  Future<void> loadInsights() async {
    emit(InsightsLoading());
    final result = await _getDashboard();
    switch (result) {
      case Success(:final data):
        emit(InsightsLoaded(data));
      case Error(:final failure):
        emit(InsightsError(failure.message));
    }
  }
}
