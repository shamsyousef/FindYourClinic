import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_result.dart';
import '../../domain/entities/availability_config_entity.dart';
import '../../domain/usecases/manage_availability_usecases.dart';
import 'manage_availability_state.dart';

class ManageAvailabilityCubit extends Cubit<ManageAvailabilityState> {
  final GetMyAvailabilityUseCase _getMyAvailabilityUseCase;
  final AddAvailabilityUseCase _addAvailabilityUseCase;
  final RemoveAvailabilityUseCase _removeAvailabilityUseCase;

  ManageAvailabilityCubit({
    required GetMyAvailabilityUseCase getMyAvailabilityUseCase,
    required AddAvailabilityUseCase addAvailabilityUseCase,
    required RemoveAvailabilityUseCase removeAvailabilityUseCase,
  })  : _getMyAvailabilityUseCase = getMyAvailabilityUseCase,
        _addAvailabilityUseCase = addAvailabilityUseCase,
        _removeAvailabilityUseCase = removeAvailabilityUseCase,
        super(ManageAvailabilityInitial());

  Future<void> loadAvailability() async {
    emit(ManageAvailabilityLoading());
    final result = await _getMyAvailabilityUseCase();
    switch (result) {
      case Success(:final data):
        emit(ManageAvailabilityLoaded(data));
      case Error(:final failure):
        emit(ManageAvailabilityError(failure.message));
    }
  }

  Future<void> addSlot({
    required String dayOfWeek,
    required String startTime,
    required String endTime,
  }) async {
    final currentState = state;
    if (currentState is ManageAvailabilityLoaded) {
      emit(ManageAvailabilityOperationInProgress(currentState.slots));
      final result = await _addAvailabilityUseCase(
        dayOfWeek: dayOfWeek,
        startTime: startTime,
        endTime: endTime,
      );
      switch (result) {
        case Success(:final data):
          final updatedSlots = List<AvailabilityConfigEntity>.from(currentState.slots)..add(data);
          emit(ManageAvailabilityLoaded(updatedSlots));
        case Error(:final failure):
          emit(ManageAvailabilityError(failure.message));
          // Restore previous state after a delay or immediately
          emit(ManageAvailabilityLoaded(currentState.slots));
      }
    }
  }

  Future<void> removeSlot(String id) async {
    final currentState = state;
    if (currentState is ManageAvailabilityLoaded) {
      emit(ManageAvailabilityOperationInProgress(currentState.slots));
      final result = await _removeAvailabilityUseCase(id);
      switch (result) {
        case Success():
          final updatedSlots = currentState.slots.where((s) => s.id != id).toList();
          emit(ManageAvailabilityLoaded(updatedSlots));
        case Error(:final failure):
          // Show error then restore the previous list
          emit(ManageAvailabilityError(failure.message));
          emit(ManageAvailabilityLoaded(currentState.slots));
      }
    }
  }
}
