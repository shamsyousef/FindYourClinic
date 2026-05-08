import '../../domain/entities/doctor_payment_info_entity.dart';

sealed class DoctorPaymentInfoState {
  const DoctorPaymentInfoState();
}

class DoctorPaymentInfoLoading extends DoctorPaymentInfoState {
  const DoctorPaymentInfoLoading();
}

class DoctorPaymentInfoLoaded extends DoctorPaymentInfoState {
  final DoctorPaymentInfoEntity? info;
  const DoctorPaymentInfoLoaded(this.info);
}

class DoctorPaymentInfoSaving extends DoctorPaymentInfoState {
  const DoctorPaymentInfoSaving();
}

class DoctorPaymentInfoSaved extends DoctorPaymentInfoState {
  const DoctorPaymentInfoSaved();
}

class DoctorPaymentInfoError extends DoctorPaymentInfoState {
  final String message;
  const DoctorPaymentInfoError(this.message);
}
