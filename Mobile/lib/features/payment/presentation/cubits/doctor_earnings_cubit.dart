import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_result.dart';
import '../../domain/entities/payment_entities.dart';
import '../../domain/usecases/payment_usecases.dart';

sealed class DoctorEarningsState {
  const DoctorEarningsState();
}

class DoctorEarningsInitial extends DoctorEarningsState {
  const DoctorEarningsInitial();
}

class DoctorEarningsLoading extends DoctorEarningsState {
  const DoctorEarningsLoading();
}

class DoctorEarningsLoaded extends DoctorEarningsState {
  final DoctorEarningsEntity earnings;
  const DoctorEarningsLoaded(this.earnings);
}

class DoctorEarningsError extends DoctorEarningsState {
  final String message;
  const DoctorEarningsError(this.message);
}

class DoctorEarningsCubit extends Cubit<DoctorEarningsState> {
  final GetDoctorEarningsUseCase _getDoctorEarnings;

  DoctorEarningsCubit({required GetDoctorEarningsUseCase getDoctorEarnings})
      : _getDoctorEarnings = getDoctorEarnings,
        super(const DoctorEarningsInitial());

  Future<void> load() async {
    emit(const DoctorEarningsLoading());
    final result = await _getDoctorEarnings();
    switch (result) {
      case Success(data: final e):
        emit(DoctorEarningsLoaded(e));
      case Error(failure: final f):
        emit(DoctorEarningsError(f.message));
    }
  }

  Future<void> refresh() => load();
}
