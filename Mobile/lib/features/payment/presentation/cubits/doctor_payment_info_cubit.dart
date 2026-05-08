import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_result.dart';
import '../../domain/entities/doctor_payment_info_entity.dart';
import '../../domain/usecases/payment_usecases.dart';
import 'doctor_payment_info_state.dart';

class DoctorPaymentInfoCubit extends Cubit<DoctorPaymentInfoState> {
  final GetDoctorPaymentInfoUseCase _getInfo;
  final SaveDoctorPaymentInfoUseCase _saveInfo;

  DoctorPaymentInfoCubit({
    required GetDoctorPaymentInfoUseCase getInfo,
    required SaveDoctorPaymentInfoUseCase saveInfo,
  })  : _getInfo = getInfo,
        _saveInfo = saveInfo,
        super(const DoctorPaymentInfoLoading());

  Future<void> load() async {
    emit(const DoctorPaymentInfoLoading());
    final result = await _getInfo();
    switch (result) {
      case Success(:final data):
        emit(DoctorPaymentInfoLoaded(data));
      case Error(:final failure):
        emit(DoctorPaymentInfoError(failure.message));
    }
  }

  Future<void> save(DoctorPaymentInfoEntity info) async {
    emit(const DoctorPaymentInfoSaving());
    final result = await _saveInfo(info);
    switch (result) {
      case Success():
        emit(const DoctorPaymentInfoSaved());
        // Reload to reflect saved state
        await load();
      case Error(:final failure):
        emit(DoctorPaymentInfoError(failure.message));
    }
  }
}
