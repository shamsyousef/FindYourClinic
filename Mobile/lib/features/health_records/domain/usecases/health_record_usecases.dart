import '../../../../core/network/api_result.dart';
import '../entities/health_record_entity.dart';
import '../repos/health_record_repository.dart';

class GetHealthRecordsUseCase {
  final HealthRecordRepository _repository;
  const GetHealthRecordsUseCase(this._repository);

  Future<ApiResult<List<HealthRecordEntity>>> call({HealthRecordType? type}) =>
      _repository.getRecords(type: type);
}

class GetHealthRecordByIdUseCase {
  final HealthRecordRepository _repository;
  const GetHealthRecordByIdUseCase(this._repository);

  Future<ApiResult<HealthRecordEntity>> call(String id) =>
      _repository.getRecordById(id);
}

class GetHealthSummaryUseCase {
  final HealthRecordRepository _repository;
  const GetHealthSummaryUseCase(this._repository);

  Future<ApiResult<HealthSummaryEntity>> call() => _repository.getSummary();
}

class CreateHealthRecordUseCase {
  final HealthRecordRepository _repository;
  const CreateHealthRecordUseCase(this._repository);

  Future<ApiResult<HealthRecordEntity>> call({
    required String title,
    required HealthRecordType type,
    String? value,
    String? unit,
    required DateTime recordedAt,
    String? notes,
  }) =>
      _repository.createRecord(
        title: title,
        type: type,
        value: value,
        unit: unit,
        recordedAt: recordedAt,
        notes: notes,
      );
}

class UpdateHealthRecordUseCase {
  final HealthRecordRepository _repository;
  const UpdateHealthRecordUseCase(this._repository);

  Future<ApiResult<HealthRecordEntity>> call({
    required String id,
    required String title,
    required HealthRecordType type,
    String? value,
    String? unit,
    required DateTime recordedAt,
    String? notes,
  }) =>
      _repository.updateRecord(
        id: id,
        title: title,
        type: type,
        value: value,
        unit: unit,
        recordedAt: recordedAt,
        notes: notes,
      );
}

class DeleteHealthRecordUseCase {
  final HealthRecordRepository _repository;
  const DeleteHealthRecordUseCase(this._repository);

  Future<ApiResult<void>> call(String id) => _repository.deleteRecord(id);
}
