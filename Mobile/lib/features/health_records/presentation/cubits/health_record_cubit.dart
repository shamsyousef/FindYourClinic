import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_result.dart';
import '../../domain/entities/health_record_entity.dart';
import '../../domain/usecases/health_record_usecases.dart';
import 'health_record_state.dart';

class HealthRecordCubit extends Cubit<HealthRecordState> {
  final GetHealthRecordsUseCase _getRecordsUseCase;
  final GetHealthRecordByIdUseCase _getByIdUseCase;
  final GetHealthSummaryUseCase _getSummaryUseCase;
  final CreateHealthRecordUseCase _createUseCase;
  final UpdateHealthRecordUseCase _updateUseCase;
  final DeleteHealthRecordUseCase _deleteUseCase;

  HealthRecordType? _lastFilter;

  HealthRecordCubit({
    required GetHealthRecordsUseCase getRecordsUseCase,
    required GetHealthRecordByIdUseCase getByIdUseCase,
    required GetHealthSummaryUseCase getSummaryUseCase,
    required CreateHealthRecordUseCase createUseCase,
    required UpdateHealthRecordUseCase updateUseCase,
    required DeleteHealthRecordUseCase deleteUseCase,
  })  : _getRecordsUseCase = getRecordsUseCase,
        _getByIdUseCase = getByIdUseCase,
        _getSummaryUseCase = getSummaryUseCase,
        _createUseCase = createUseCase,
        _updateUseCase = updateUseCase,
        _deleteUseCase = deleteUseCase,
        super(HealthRecordInitial());

  Future<void> loadRecords({HealthRecordType? type}) async {
    _lastFilter = type;
    emit(HealthRecordLoading());

    // Start both concurrently before awaiting.
    final recordsFuture = _getRecordsUseCase(type: type);
    final summaryFuture = _getSummaryUseCase();

    final recordsResult = await recordsFuture;
    final summaryResult = await summaryFuture;

    if (recordsResult case Error(:final failure)) {
      emit(HealthRecordError(failure.message));
      return;
    }
    if (summaryResult case Error(:final failure)) {
      emit(HealthRecordError(failure.message));
      return;
    }

    emit(HealthRecordListLoaded(
      records: (recordsResult as Success<List<HealthRecordEntity>>).data,
      summary: (summaryResult as Success<HealthSummaryEntity>).data,
      activeFilter: type,
    ));
  }

  Future<void> loadRecordDetail(String id) async {
    emit(HealthRecordLoading());
    final result = await _getByIdUseCase(id);
    switch (result) {
      case Success(:final data):
        emit(HealthRecordDetailLoaded(data));
      case Error(:final failure):
        emit(HealthRecordError(failure.message));
    }
  }

  Future<void> createRecord({
    required String title,
    required HealthRecordType type,
    String? value,
    String? unit,
    required DateTime recordedAt,
    String? notes,
  }) async {
    emit(HealthRecordActionInProgress());
    final result = await _createUseCase(
      title: title,
      type: type,
      value: value,
      unit: unit,
      recordedAt: recordedAt,
      notes: notes,
    );
    switch (result) {
      case Success():
        emit(const HealthRecordActionSuccess('Record added.'));
        await _reload();
      case Error(:final failure):
        emit(HealthRecordError(failure.message));
    }
  }

  Future<void> updateRecord({
    required String id,
    required String title,
    required HealthRecordType type,
    String? value,
    String? unit,
    required DateTime recordedAt,
    String? notes,
  }) async {
    emit(HealthRecordActionInProgress());
    final result = await _updateUseCase(
      id: id,
      title: title,
      type: type,
      value: value,
      unit: unit,
      recordedAt: recordedAt,
      notes: notes,
    );
    switch (result) {
      case Success():
        emit(const HealthRecordActionSuccess('Record updated.'));
        await _reload();
      case Error(:final failure):
        emit(HealthRecordError(failure.message));
    }
  }

  Future<void> deleteRecord(String id) async {
    emit(HealthRecordActionInProgress());
    final result = await _deleteUseCase(id);
    switch (result) {
      case Success():
        emit(const HealthRecordActionSuccess('Record deleted.'));
        await _reload();
      case Error(:final failure):
        emit(HealthRecordError(failure.message));
    }
  }

  Future<void> _reload() async => loadRecords(type: _lastFilter);
}
