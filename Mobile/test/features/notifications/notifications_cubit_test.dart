import 'package:find_your_clinic/core/network/api_result.dart';
import 'package:find_your_clinic/core/network/failure.dart';
import 'package:find_your_clinic/features/notifications/domain/entities/notification_entity.dart';
import 'package:find_your_clinic/features/notifications/domain/repos/notification_repository.dart';
import 'package:find_your_clinic/features/notifications/domain/usecases/notification_usecases.dart';
import 'package:find_your_clinic/features/notifications/presentation/cubits/notification_badge_cubit.dart';
import 'package:find_your_clinic/features/notifications/presentation/cubits/notification_badge_state.dart';
import 'package:find_your_clinic/features/notifications/presentation/cubits/notifications_cubit.dart';
import 'package:find_your_clinic/features/notifications/presentation/cubits/notifications_state.dart';
import 'package:flutter_test/flutter_test.dart';

final _notification1 = AppNotification(
  id: 'n1',
  title: 'T1',
  body: 'B1',
  type: 'appointment_confirmed',
  referenceId: 'appt-1',
  isRead: false,
  createdAt: DateTime(2026, 5, 8),
);

final _notification2 = AppNotification(
  id: 'n2',
  title: 'T2',
  body: 'B2',
  isRead: false,
  createdAt: DateTime(2026, 5, 7),
);

class _FakeRepo implements NotificationRepository {
  final List<AppNotification> notifications;
  bool markAllFails;

  _FakeRepo({List<AppNotification>? notifications, this.markAllFails = false})
      : notifications = notifications ?? [_notification1, _notification2];

  @override
  Future<ApiResult<List<AppNotification>>> getNotifications(
          {int page = 1, int pageSize = 20}) async =>
      Success(notifications);

  @override
  Future<ApiResult<int>> getUnreadCount() async => const Success(0);

  @override
  Future<ApiResult<void>> markAsRead(String notificationId) async =>
      const Success(null);

  @override
  Future<ApiResult<void>> registerDeviceToken(String token) async =>
      const Success(null);

  @override
  Future<ApiResult<void>> markAllAsRead() async {
    if (markAllFails) return const Error(ServerFailure('error'));
    return const Success(null);
  }
}

NotificationBadgeCubit _makeBadgeCubit(_FakeRepo repo) =>
    NotificationBadgeCubit(
        getUnreadCountUseCase: GetUnreadNotificationCountUseCase(repo));

NotificationsCubit _makeCubit(_FakeRepo repo, NotificationBadgeCubit badge) =>
    NotificationsCubit(
      getNotificationsUseCase: GetNotificationsUseCase(repo),
      markReadUseCase: MarkNotificationReadUseCase(repo),
      markAllReadUseCase: MarkAllNotificationsReadUseCase(repo),
      badgeCubit: badge,
    );

void main() {
  group('NotificationsCubit.markAsRead', () {
    test('flips isRead=true on the matching notification', () async {
      final repo = _FakeRepo();
      final badge = _makeBadgeCubit(repo);
      final cubit = _makeCubit(repo, badge);
      await cubit.loadNotifications();

      await cubit.markAsRead('n1');

      final state = cubit.state as NotificationsLoaded;
      final updated = state.notifications.firstWhere((n) => n.id == 'n1');
      expect(updated.isRead, true);
    });

    test('decrements badge count after marking read', () async {
      final repo = _FakeRepo();
      final badge = _makeBadgeCubit(repo);
      badge.increment();
      badge.increment();
      final cubit = _makeCubit(repo, badge);
      await cubit.loadNotifications();

      await cubit.markAsRead('n1');

      expect((badge.state as NotificationBadgeLoaded).unreadCount, 1);
    });
  });

  group('NotificationsCubit.markAllAsRead', () {
    test('optimistically sets all notifications to isRead=true', () async {
      final repo = _FakeRepo();
      final badge = _makeBadgeCubit(repo);
      final cubit = _makeCubit(repo, badge);
      await cubit.loadNotifications();

      await cubit.markAllAsRead();

      final state = cubit.state as NotificationsLoaded;
      expect(state.notifications.every((n) => n.isRead), true);
    });

    test('resets badge to zero', () async {
      final repo = _FakeRepo();
      final badge = _makeBadgeCubit(repo);
      badge.increment();
      badge.increment();
      final cubit = _makeCubit(repo, badge);
      await cubit.loadNotifications();

      await cubit.markAllAsRead();

      expect((badge.state as NotificationBadgeLoaded).unreadCount, 0);
    });

    test('reloads notifications on API failure', () async {
      final repo = _FakeRepo(markAllFails: true);
      final badge = _makeBadgeCubit(repo);
      final cubit = _makeCubit(repo, badge);
      await cubit.loadNotifications();

      await cubit.markAllAsRead();

      expect(cubit.state, isA<NotificationsLoaded>());
    });
  });
}
