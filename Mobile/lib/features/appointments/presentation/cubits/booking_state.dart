import '../../domain/entities/appointment_entity.dart';

/// Sealed state for BookingCubit (slot selection + booking).
sealed class BookingState {
  const BookingState();
}

class BookingInitial extends BookingState {}

class BookingSlotsLoading extends BookingState {}

class BookingSlotsLoaded extends BookingState {
  final List<DateTime> slots;
  const BookingSlotsLoaded(this.slots);
}

class BookingSlotsEmpty extends BookingState {}

class BookingSubmitting extends BookingState {}

class BookingSuccess extends BookingState {
  final AppointmentEntity appointment;
  const BookingSuccess(this.appointment);
}

class BookingError extends BookingState {
  final String message;
  const BookingError(this.message);
}
