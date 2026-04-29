import '../../../../core/network/api_result.dart';
import '../entities/notification_entity.dart';
import '../repos/notification_repository.dart';

class GetNotificationsUseCase {
  final NotificationRepository _repository;
  const GetNotificationsUseCase(this._repository);

  Future<ApiResult<List<AppNotification>>> call({int page = 1}) =>
      _repository.getNotifications(page: page);
}

class GetUnreadNotificationCountUseCase {
  final NotificationRepository _repository;
  const GetUnreadNotificationCountUseCase(this._repository);

  Future<ApiResult<int>> call() => _repository.getUnreadCount();
}

class MarkNotificationReadUseCase {
  final NotificationRepository _repository;
  const MarkNotificationReadUseCase(this._repository);

  Future<ApiResult<void>> call(String id) => _repository.markAsRead(id);
}

class RegisterDeviceTokenUseCase {
  final NotificationRepository _repository;
  const RegisterDeviceTokenUseCase(this._repository);

  Future<ApiResult<void>> call(String token) => _repository.registerDeviceToken(token);
}
