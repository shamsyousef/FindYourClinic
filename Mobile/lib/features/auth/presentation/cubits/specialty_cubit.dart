import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_result.dart';
import '../../domain/usecases/get_specialties_usecase.dart';
import 'specialty_state.dart';

class SpecialtyCubit extends Cubit<SpecialtyState> {
  final GetSpecialtiesUseCase _getSpecialtiesUseCase;

  SpecialtyCubit(this._getSpecialtiesUseCase) : super(SpecialtyInitial());

  Future<void> loadSpecialties() async {
    emit(SpecialtyLoading());
    final result = await _getSpecialtiesUseCase();
    switch (result) {
      case Success(:final data):
        emit(SpecialtyLoaded(data));
      case Error(:final failure):
        emit(SpecialtyError(failure.message));
    }
  }
}
