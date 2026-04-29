import '../../domain/entities/doctor_dashboard_entities.dart';

sealed class InsightsState {}

class InsightsInitial extends InsightsState {}

class InsightsLoading extends InsightsState {}

class InsightsLoaded extends InsightsState {
  final DoctorDashboard dashboard;
  InsightsLoaded(this.dashboard);
}

class InsightsError extends InsightsState {
  final String message;
  InsightsError(this.message);
}
