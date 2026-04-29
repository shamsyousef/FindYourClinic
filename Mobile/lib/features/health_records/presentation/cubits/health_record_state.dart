import '../../domain/entities/health_record_entity.dart';

sealed class HealthRecordState {
  const HealthRecordState();
}

class HealthRecordInitial extends HealthRecordState {}

class HealthRecordLoading extends HealthRecordState {}

class HealthRecordListLoaded extends HealthRecordState {
  final List<HealthRecordEntity> records;
  final HealthSummaryEntity summary;
  final HealthRecordType? activeFilter;

  const HealthRecordListLoaded({
    required this.records,
    required this.summary,
    this.activeFilter,
  });
}

class HealthRecordDetailLoaded extends HealthRecordState {
  final HealthRecordEntity record;
  const HealthRecordDetailLoaded(this.record);
}

class HealthRecordError extends HealthRecordState {
  final String message;
  const HealthRecordError(this.message);
}

class HealthRecordActionInProgress extends HealthRecordState {}

class HealthRecordActionSuccess extends HealthRecordState {
  final String message;
  const HealthRecordActionSuccess(this.message);
}
