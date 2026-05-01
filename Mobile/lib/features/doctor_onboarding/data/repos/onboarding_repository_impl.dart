import 'dart:io';

import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/network/failure.dart';
import '../../domain/entities/onboarding_entities.dart';
import '../../domain/repos/onboarding_repository.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  final ApiClient _apiClient;

  const OnboardingRepositoryImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<ApiResult<List<UploadedDocument>>> getMyDocuments() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.doctorMyDocuments);
      final body = response.data as Map<String, dynamic>;
      if (body['success'] != true) {
        return Error(
          ServerFailure(body['message'] as String? ?? 'Failed to load documents'),
        );
      }

      final list = (body['data'] as List).map((e) {
        final map = e as Map<String, dynamic>;
        return UploadedDocument(
          documentType: map['documentType'] as String,
          url: map['url'] as String,
        );
      }).toList();
      return Success(list);
    } on DioException catch (e) {
      return Error(mapDioException(e));
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<ApiResult<List<UploadedDocument>>> uploadDocuments({
    required List<DoctorDocument> documents,
    required String pendingToken,
  }) async {
    try {
      final formData = FormData();

      for (final doc in documents) {
        final file = File(doc.localPath);
        final filename = file.path.split(Platform.pathSeparator).last;
        formData.files.add(MapEntry(
          'files',
          await MultipartFile.fromFile(file.path, filename: filename),
        ));
        formData.fields.add(MapEntry('documentTypes', doc.documentType));
      }

      final options = pendingToken.isNotEmpty
          ? Options(headers: {'Authorization': 'Bearer $pendingToken'})
          : null;

      final response = await _apiClient.dio.post(
        ApiEndpoints.uploadDoctorDocuments,
        data: formData,
        options: options,
      );

      final body = response.data as Map<String, dynamic>;
      if (body['success'] != true) {
        return Error(ServerFailure(body['message'] as String? ?? 'Upload failed'));
      }

      final list = (body['data'] as List).map((e) {
        final map = e as Map<String, dynamic>;
        return UploadedDocument(
          documentType: map['documentType'] as String,
          url: map['url'] as String,
        );
      }).toList();

      return Success(list);
    } on DioException catch (e) {
      return Error(mapDioException(e));
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }
}
