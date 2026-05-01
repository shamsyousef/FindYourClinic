import '../../domain/entities/onboarding_entities.dart';

sealed class OnboardingState {}

class OnboardingInitial extends OnboardingState {}

class OnboardingLoading extends OnboardingState {}

class OnboardingDocumentsLoaded extends OnboardingState {
  final List<UploadedDocument> documents;
  OnboardingDocumentsLoaded(this.documents);
}

class OnboardingDocumentsUploaded extends OnboardingState {
  final List<UploadedDocument> documents;
  OnboardingDocumentsUploaded(this.documents);
}

class OnboardingError extends OnboardingState {
  final String message;
  OnboardingError(this.message);
}
