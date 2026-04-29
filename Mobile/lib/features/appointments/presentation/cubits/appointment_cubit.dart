import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_result.dart';
import '../../domain/entities/appointment_entity.dart';
import '../../domain/usecases/appointment_usecases.dart';
import 'appointment_state.dart';

class AppointmentCubit extends Cubit<AppointmentState> {
  final GetPatientAppointmentsUseCase _getPatientAppointmentsUseCase;
  final GetDoctorAppointmentsUseCase _getDoctorAppointmentsUseCase;
  final GetAppointmentByIdUseCase _getAppointmentByIdUseCase;
  final CancelAppointmentUseCase _cancelAppointmentUseCase;
  final ConfirmAppointmentUseCase _confirmAppointmentUseCase;
  final CompleteAppointmentUseCase _completeAppointmentUseCase;

  /// Tracks whether we're loading patient or doctor appointments for reload.
  bool _isDoctorMode = false;

  AppointmentCubit({
    required GetPatientAppointmentsUseCase getPatientAppointmentsUseCase,
    required GetDoctorAppointmentsUseCase getDoctorAppointmentsUseCase,
    required GetAppointmentByIdUseCase getAppointmentByIdUseCase,
    required CancelAppointmentUseCase cancelAppointmentUseCase,
    required ConfirmAppointmentUseCase confirmAppointmentUseCase,
    required CompleteAppointmentUseCase completeAppointmentUseCase,
  })  : _getPatientAppointmentsUseCase = getPatientAppointmentsUseCase,
        _getDoctorAppointmentsUseCase = getDoctorAppointmentsUseCase,
        _getAppointmentByIdUseCase = getAppointmentByIdUseCase,
        _cancelAppointmentUseCase = cancelAppointmentUseCase,
        _confirmAppointmentUseCase = confirmAppointmentUseCase,
        _completeAppointmentUseCase = completeAppointmentUseCase,
        super(AppointmentInitial());

  Future<void> loadPatientAppointments() async {
    _isDoctorMode = false;
    emit(AppointmentLoading());

    final result = await _getPatientAppointmentsUseCase();

    switch (result) {
      case Success(:final data):
        emit(_splitAppointments(data));
      case Error(:final failure):
        emit(AppointmentError(failure.message));
    }
  }

  Future<void> loadDoctorAppointments() async {
    _isDoctorMode = true;
    emit(AppointmentLoading());

    final result = await _getDoctorAppointmentsUseCase();

    switch (result) {
      case Success(:final data):
        emit(_splitAppointments(data));
      case Error(:final failure):
        emit(AppointmentError(failure.message));
    }
  }

  Future<void> loadAppointmentDetail(String id) async {
    emit(AppointmentLoading());

    final result = await _getAppointmentByIdUseCase(id);

    switch (result) {
      case Success(:final data):
        emit(AppointmentDetailLoaded(data));
      case Error(:final failure):
        emit(AppointmentError(failure.message));
    }
  }

  Future<void> cancelAppointment(String id) async {
    emit(AppointmentActionInProgress());

    final result = await _cancelAppointmentUseCase(id);

    switch (result) {
      case Success():
        emit(const AppointmentActionSuccess('Appointment cancelled.'));
        await _reload();
      case Error(:final failure):
        emit(AppointmentError(failure.message));
    }
  }

  Future<void> confirmAppointment(String id) async {
    emit(AppointmentActionInProgress());

    final result = await _confirmAppointmentUseCase(id);

    switch (result) {
      case Success():
        emit(const AppointmentActionSuccess('Appointment confirmed.'));
        await _reload();
      case Error(:final failure):
        emit(AppointmentError(failure.message));
    }
  }

  Future<void> completeAppointment(String id) async {
    emit(AppointmentActionInProgress());

    final result = await _completeAppointmentUseCase(id);

    switch (result) {
      case Success():
        emit(const AppointmentActionSuccess('Appointment completed.'));
        await _reload();
      case Error(:final failure):
        emit(AppointmentError(failure.message));
    }
  }

  /// Reloads the appropriate list after an action.
  Future<void> _reload() async {
    if (_isDoctorMode) {
      await loadDoctorAppointments();
    } else {
      await loadPatientAppointments();
    }
  }

  /// Splits the full list into categorized sub-lists.
  AppointmentListLoaded _splitAppointments(List<AppointmentEntity> all) {
    final now = DateTime.now();

    final upcoming = all
        .where((a) =>
            (a.status == AppointmentStatus.scheduled ||
                a.status == AppointmentStatus.confirmed) &&
            a.scheduledAt.isAfter(now))
        .toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    final completed = all
        .where((a) => a.status == AppointmentStatus.completed)
        .toList()
      ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));

    final cancelled = all
        .where((a) => a.status == AppointmentStatus.cancelled)
        .toList()
      ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));

    return AppointmentListLoaded(
      upcoming: upcoming,
      completed: completed,
      cancelled: cancelled,
      all: all..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt)),
    );
  }
}
