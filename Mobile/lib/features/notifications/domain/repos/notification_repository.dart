import '../../../../core/network/api_result.dart';
import '../entities/notification_entity.dart';

abstract class NotificationRepository {
  Future<ApiResult<List<AppNotification>>> getNotifications({int page = 1, int pageSize = 20});
  Future<ApiResult<int>> getUnreadCount();
  Future<ApiResult<void>> markAsRead(String notificationId);
  Future<ApiResult<void>> registerDeviceToken(String token);
  Future<ApiResult<void>> markAllAsRead();
}
