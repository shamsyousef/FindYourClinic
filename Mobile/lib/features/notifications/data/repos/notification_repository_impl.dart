import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/network/failure.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repos/notification_repository.dart';
import '../models/notification_models.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final ApiClient _apiClient;

  const NotificationRepositoryImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<ApiResult<List<AppNotification>>> getNotifications({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.notifications,
        queryParameters: {'page': page, 'pageSize': pageSize},
      );
      final data = response.data['data'];
      final List items = data is List ? data : (data['items'] ?? data);
      final notifications = items
          .map((e) => AppNotificationModel.fromJson(e).toEntity())
          .toList();
      return Success(notifications);
    } on DioException catch (e) {
      return Error(mapDioException(e));
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<ApiResult<int>> getUnreadCount() async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.notifications,
        queryParameters: {'page': 1, 'pageSize': 1},
      );
      final data = response.data['data'];
      final unreadCount =
          (data is Map) ? ((data['unreadCount'] as num?)?.toInt() ?? 0) : 0;
      return Success(unreadCount);
    } on DioException catch (e) {
      return Error(mapDioException(e));
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<ApiResult<void>> markAsRead(String notificationId) async {
    try {
      await _apiClient.dio
          .put(ApiEndpoints.markNotificationRead(notificationId));
      return const Success(null);
    } on DioException catch (e) {
      return Error(mapDioException(e));
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<ApiResult<void>> registerDeviceToken(String token) async {
    try {
      await _apiClient.dio.post(
        ApiEndpoints.deviceToken,
        data: {'token': token},
      );
      return const Success(null);
    } on DioException catch (e) {
      return Error(mapDioException(e));
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<ApiResult<void>> markAllAsRead() async {
    try {
      await _apiClient.dio.put(ApiEndpoints.markAllNotificationsRead);
      return const Success(null);
    } on DioException catch (e) {
      return Error(mapDioException(e));
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }
}
