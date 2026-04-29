import '../../domain/entities/availability_config_entity.dart';

sealed class ManageAvailabilityState {
  const ManageAvailabilityState();
}

class ManageAvailabilityInitial extends ManageAvailabilityState {}

class ManageAvailabilityLoading extends ManageAvailabilityState {}

class ManageAvailabilityLoaded extends ManageAvailabilityState {
  final List<AvailabilityConfigEntity> slots;
  const ManageAvailabilityLoaded(this.slots);
}

class ManageAvailabilityError extends ManageAvailabilityState {
  final String message;
  const ManageAvailabilityError(this.message);
}

class ManageAvailabilityOperationInProgress extends ManageAvailabilityLoaded {
  const ManageAvailabilityOperationInProgress(super.slots);
}
