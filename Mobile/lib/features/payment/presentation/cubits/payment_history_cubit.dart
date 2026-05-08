import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_result.dart';
import '../../domain/entities/payment_entities.dart';
import '../../domain/usecases/payment_usecases.dart';

sealed class PaymentHistoryState {
  const PaymentHistoryState();
}

class PaymentHistoryInitial extends PaymentHistoryState {
  const PaymentHistoryInitial();
}

class PaymentHistoryLoading extends PaymentHistoryState {
  const PaymentHistoryLoading();
}

class PaymentHistoryLoaded extends PaymentHistoryState {
  final List<TransactionEntity> transactions;
  const PaymentHistoryLoaded(this.transactions);
}

class PaymentHistoryError extends PaymentHistoryState {
  final String message;
  const PaymentHistoryError(this.message);
}

class PaymentHistoryCubit extends Cubit<PaymentHistoryState> {
  final GetPaymentHistoryUseCase _getPaymentHistory;

  PaymentHistoryCubit({required GetPaymentHistoryUseCase getPaymentHistory})
      : _getPaymentHistory = getPaymentHistory,
        super(const PaymentHistoryInitial());

  Future<void> load() async {
    emit(const PaymentHistoryLoading());
    final result = await _getPaymentHistory();
    switch (result) {
      case Success(data: final list):
        emit(PaymentHistoryLoaded(list));
      case Error(failure: final failure):
        emit(PaymentHistoryError(failure.message));
    }
  }

  Future<void> refresh() => load();
}
