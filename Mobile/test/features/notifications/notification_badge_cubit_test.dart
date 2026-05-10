import 'package:find_your_clinic/core/network/api_result.dart';
import 'package:find_your_clinic/features/notifications/domain/entities/notification_entity.dart';
import 'package:find_your_clinic/features/notifications/domain/repos/notification_repository.dart';
import 'package:find_your_clinic/features/notifications/domain/usecases/notification_usecases.dart';
import 'package:find_your_clinic/features/notifications/presentation/cubits/notification_badge_cubit.dart';
import 'package:find_your_clinic/features/notifications/presentation/cubits/notification_badge_state.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeNotificationRepository implements NotificationRepository {
  @override
  Future<ApiResult<List<AppNotification>>> getNotifications(
          {int page = 1, int pageSize = 20}) async =>
      const Success([]);
  @override
  Future<ApiResult<int>> getUnreadCount() async => const Success(5);
  @override
  Future<ApiResult<void>> markAsRead(String notificationId) async =>
      const Success(null);
  @override
  Future<ApiResult<void>> registerDeviceToken(String token) async =>
      const Success(null);
  @override
  Future<ApiResult<void>> markAllAsRead() async => const Success(null);
}

NotificationBadgeCubit _makeCubit() => NotificationBadgeCubit(
      getUnreadCountUseCase:
          GetUnreadNotificationCountUseCase(_FakeNotificationRepository()),
    );

void main() {
  group('NotificationBadgeCubit.decrement()', () {
    test('decrements count from 3 to 2', () {
      final cubit = _makeCubit();
      cubit.increment();
      cubit.increment();
      cubit.increment();

      cubit.decrement();

      expect((cubit.state as NotificationBadgeLoaded).unreadCount, 2);
    });

    test('clamps to zero — does not go negative', () {
      final cubit = _makeCubit();
      cubit.increment();

      cubit.decrement();
      cubit.decrement();

      expect((cubit.state as NotificationBadgeLoaded).unreadCount, 0);
    });

    test('decrement on initial state stays at zero', () {
      final cubit = _makeCubit();

      cubit.decrement();

      final state = cubit.state;
      if (state is NotificationBadgeLoaded) {
        expect(state.unreadCount, 0);
      }
    });
  });
}
