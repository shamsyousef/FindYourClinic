import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/network/failure.dart';
import '../../domain/entities/ai_chat_message.dart';
import '../../domain/entities/symptom_analysis.dart';
import '../../domain/repos/ai_health_repository.dart';
import '../datasources/ai_health_remote_datasource.dart';

class AiHealthRepositoryImpl implements AiHealthRepository {
  final AiHealthRemoteDataSource _dataSource;

  const AiHealthRepositoryImpl({required AiHealthRemoteDataSource dataSource})
      : _dataSource = dataSource;

  @override
  Future<ApiResult<AiChatMessage>> sendMessage(String content) async {
    try {
      final model = await _dataSource.sendMessage(content);
      return Success(model.toEntity());
    } on DioException catch (e) {
      return Error(mapDioException(e));
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<ApiResult<List<AiChatMessage>>> getChatHistory() async {
    try {
      final models = await _dataSource.getChatHistory();
      return Success(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return Error(mapDioException(e));
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<ApiResult<SymptomAnalysis>> analyzeSymptoms(
      List<String> symptoms) async {
    try {
      final model = await _dataSource.analyzeSymptoms(symptoms);
      return Success(model.toEntity());
    } on DioException catch (e) {
      return Error(mapDioException(e));
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }
}
