import '../../domain/entities/appointment_entity.dart';

/// Sealed state for AppointmentCubit (list + actions).
sealed class AppointmentState {
  const AppointmentState();
}

class AppointmentInitial extends AppointmentState {}

class AppointmentLoading extends AppointmentState {}

class AppointmentListLoaded extends AppointmentState {
  final List<AppointmentEntity> upcoming;
  final List<AppointmentEntity> completed;
  final List<AppointmentEntity> cancelled;
  final List<AppointmentEntity> all;

  const AppointmentListLoaded({
    required this.upcoming,
    required this.completed,
    required this.cancelled,
    required this.all,
  });
}

class AppointmentDetailLoaded extends AppointmentState {
  final AppointmentEntity appointment;
  const AppointmentDetailLoaded(this.appointment);
}

class AppointmentError extends AppointmentState {
  final String message;
  const AppointmentError(this.message);
}

class AppointmentActionInProgress extends AppointmentState {}

class AppointmentActionSuccess extends AppointmentState {
  final String message;
  const AppointmentActionSuccess(this.message);
}
