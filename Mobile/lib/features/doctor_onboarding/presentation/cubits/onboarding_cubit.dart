import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/onboarding_entities.dart';
import '../../domain/usecases/get_my_documents_usecase.dart';
import '../../domain/usecases/upload_documents_usecase.dart';
import '../../../../core/network/api_result.dart';
import 'onboarding_state.dart';

class OnboardingCubit extends Cubit<OnboardingState> {
  final GetMyDocumentsUseCase _getMyDocumentsUseCase;
  final UploadDocumentsUseCase _uploadDocumentsUseCase;

  OnboardingCubit({
    required GetMyDocumentsUseCase getMyDocumentsUseCase,
    required UploadDocumentsUseCase uploadDocumentsUseCase,
  })
      : _getMyDocumentsUseCase = getMyDocumentsUseCase,
        _uploadDocumentsUseCase = uploadDocumentsUseCase,
        super(OnboardingInitial());

  Future<void> loadMyDocuments() async {
    emit(OnboardingLoading());
    final result = await _getMyDocumentsUseCase();
    switch (result) {
      case Success(:final data):
        emit(OnboardingDocumentsLoaded(data));
      case Error(:final failure):
        emit(OnboardingError(failure.message));
    }
  }

  Future<void> uploadDocuments({
    required List<DoctorDocument> documents,
    required String pendingToken,
  }) async {
    emit(OnboardingLoading());
    final result = await _uploadDocumentsUseCase(
      documents: documents,
      pendingToken: pendingToken,
    );
    switch (result) {
      case Success(:final data):
        emit(OnboardingDocumentsUploaded(data));
      case Error(:final failure):
        emit(OnboardingError(failure.message));
    }
  }
}
