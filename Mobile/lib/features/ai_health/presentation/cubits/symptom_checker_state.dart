import '../../domain/entities/symptom_analysis.dart';

/// Sealed state for SymptomCheckerCubit.
sealed class SymptomCheckerState {
  const SymptomCheckerState();
}

class SymptomCheckerInitial extends SymptomCheckerState {}

class SymptomCheckerSelecting extends SymptomCheckerState {
  final List<String> selected;
  const SymptomCheckerSelecting(this.selected);
}

class SymptomCheckerAnalyzing extends SymptomCheckerState {}

class SymptomCheckerResult extends SymptomCheckerState {
  final SymptomAnalysis analysis;
  const SymptomCheckerResult(this.analysis);
}

class SymptomCheckerError extends SymptomCheckerState {
  final String message;
  const SymptomCheckerError(this.message);
}
