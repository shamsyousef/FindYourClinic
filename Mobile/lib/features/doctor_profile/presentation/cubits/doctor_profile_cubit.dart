import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_result.dart';
import '../../domain/usecases/doctor_profile_usecases.dart';
import 'doctor_profile_state.dart';

class DoctorProfileCubit extends Cubit<DoctorProfileState> {
  final GetDoctorDetailsUseCase _getDetailsUseCase;
  final GetDoctorReviewsUseCase _getReviewsUseCase;
  final GetDoctorAvailabilityUseCase _getAvailabilityUseCase;
  final AddReviewUseCase _addReviewUseCase;

  DoctorProfileCubit({
    required GetDoctorDetailsUseCase getDetailsUseCase,
    required GetDoctorReviewsUseCase getReviewsUseCase,
    required GetDoctorAvailabilityUseCase getAvailabilityUseCase,
    required AddReviewUseCase addReviewUseCase,
  })  : _getDetailsUseCase = getDetailsUseCase,
        _getReviewsUseCase = getReviewsUseCase,
        _getAvailabilityUseCase = getAvailabilityUseCase,
        _addReviewUseCase = addReviewUseCase,
        super(DoctorProfileInitial());

  Future<void> loadProfile(String doctorId) async {
    emit(DoctorProfileLoading());

    final detailsResult = await _getDetailsUseCase(doctorId);

    switch (detailsResult) {
      case Success(:final data):
        // Load reviews and availability in parallel after details succeed.
        final reviewsResult = await _getReviewsUseCase(doctorId);
        final availabilityResult = await _getAvailabilityUseCase(doctorId);

        final reviews = switch (reviewsResult) {
          Success(:final data) => data,
          Error() => <dynamic>[],
        };

        final availability = switch (availabilityResult) {
          Success(:final data) => data,
          Error() => <dynamic>[],
        };

        emit(DoctorProfileLoaded(
          details: data,
          reviews: List.from(reviews),
          availability: List.from(availability),
        ));
      case Error(:final failure):
        emit(DoctorProfileError(failure.message));
    }
  }

  Future<void> addReview(
      String doctorId, int rating, String? comment) async {
    final current = state;
    if (current is! DoctorProfileLoaded) return;
    final result = await _addReviewUseCase(doctorId, rating, comment);
    switch (result) {
      case Success():
        emit(DoctorProfileReviewSuccess(current));
        // Reload reviews
        final reviewsResult = await _getReviewsUseCase(doctorId);
        final reviews = switch (reviewsResult) {
          Success(:final data) => data,
          Error() => current.reviews,
        };
        emit(DoctorProfileLoaded(
          details: current.details,
          reviews: reviews,
          availability: current.availability,
        ));
      case Error(:final failure):
        emit(DoctorProfileReviewError(failure.message, current));
        emit(current);
    }
  }
}
