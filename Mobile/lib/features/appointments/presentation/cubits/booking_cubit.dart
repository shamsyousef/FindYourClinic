import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_result.dart';
import '../../domain/usecases/appointment_usecases.dart';
import 'booking_state.dart';

class BookingCubit extends Cubit<BookingState> {
  final GetAvailableSlotsUseCase _getAvailableSlotsUseCase;
  final BookAppointmentUseCase _bookAppointmentUseCase;

  BookingCubit({
    required GetAvailableSlotsUseCase getAvailableSlotsUseCase,
    required BookAppointmentUseCase bookAppointmentUseCase,
  })  : _getAvailableSlotsUseCase = getAvailableSlotsUseCase,
        _bookAppointmentUseCase = bookAppointmentUseCase,
        super(BookingInitial());

  Future<void> loadSlots({
    required String doctorId,
    required DateTime date,
  }) async {
    emit(BookingSlotsLoading());

    final result = await _getAvailableSlotsUseCase(
      doctorId: doctorId,
      date: date,
    );

    switch (result) {
      case Success(:final data):
        if (data.isEmpty) {
          emit(BookingSlotsEmpty());
        } else {
          emit(BookingSlotsLoaded(data));
        }
      case Error(:final failure):
        emit(BookingError(failure.message));
    }
  }

  Future<void> bookAppointment({
    required String doctorProfileId,
    required DateTime scheduledAt,
    String? locationName,
  }) async {
    emit(BookingSubmitting());

    final result = await _bookAppointmentUseCase(
      doctorProfileId: doctorProfileId,
      scheduledAt: scheduledAt,
      locationName: locationName,
    );

    switch (result) {
      case Success(:final data):
        emit(BookingSuccess(data));
      case Error(:final failure):
        emit(BookingError(failure.message));
    }
  }
}
