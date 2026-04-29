import '../../../../core/network/api_result.dart';
import '../entities/health_record_entity.dart';

abstract class HealthRecordRepository {
  Future<ApiResult<List<HealthRecordEntity>>> getRecords({HealthRecordType? type});
  Future<ApiResult<HealthRecordEntity>> getRecordById(String id);
  Future<ApiResult<HealthSummaryEntity>> getSummary();
  Future<ApiResult<HealthRecordEntity>> createRecord({
    required String title,
    required HealthRecordType type,
    String? value,
    String? unit,
    required DateTime recordedAt,
    String? notes,
  });
  Future<ApiResult<HealthRecordEntity>> updateRecord({
    required String id,
    required String title,
    required HealthRecordType type,
    String? value,
    String? unit,
    required DateTime recordedAt,
    String? notes,
  });
  Future<ApiResult<void>> deleteRecord(String id);
}
