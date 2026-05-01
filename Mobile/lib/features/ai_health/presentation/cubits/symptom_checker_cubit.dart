import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_result.dart';
import '../../domain/usecases/analyze_symptoms_usecase.dart';
import 'symptom_checker_state.dart';

class SymptomCheckerCubit extends Cubit<SymptomCheckerState> {
  final AnalyzeSymptomsUseCase _analyzeSymptoms;

  SymptomCheckerCubit(this._analyzeSymptoms) : super(SymptomCheckerInitial());

  void toggleSymptom(String symptom) {
    final current = switch (state) {
      SymptomCheckerSelecting(:final selected) => List<String>.from(selected),
      _ => <String>[],
    };
    if (current.contains(symptom)) {
      current.remove(symptom);
    } else {
      current.add(symptom);
    }
    emit(SymptomCheckerSelecting(current));
  }

  Future<void> analyzeSymptoms() async {
    final selected = switch (state) {
      SymptomCheckerSelecting(:final selected) => selected,
      _ => <String>[],
    };
    if (selected.isEmpty) return;

    emit(SymptomCheckerAnalyzing());
    final result = await _analyzeSymptoms(selected);
    switch (result) {
      case Success(:final data):
        emit(SymptomCheckerResult(data));
      case Error(:final failure):
        emit(SymptomCheckerError(failure.message));
    }
  }

  void reset() => emit(SymptomCheckerInitial());
}
