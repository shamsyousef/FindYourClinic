import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_result.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/usecases/notification_usecases.dart';
import 'notification_badge_cubit.dart';
import 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  final GetNotificationsUseCase _getNotificationsUseCase;
  final MarkNotificationReadUseCase _markReadUseCase;
  final MarkAllNotificationsReadUseCase _markAllReadUseCase;
  final NotificationBadgeCubit _badgeCubit;

  NotificationsCubit({
    required GetNotificationsUseCase getNotificationsUseCase,
    required MarkNotificationReadUseCase markReadUseCase,
    required MarkAllNotificationsReadUseCase markAllReadUseCase,
    required NotificationBadgeCubit badgeCubit,
  })  : _getNotificationsUseCase = getNotificationsUseCase,
        _markReadUseCase = markReadUseCase,
        _markAllReadUseCase = markAllReadUseCase,
        _badgeCubit = badgeCubit,
        super(NotificationsInitial());

  Future<void> loadNotifications() async {
    emit(NotificationsLoading());
    final result = await _getNotificationsUseCase();
    switch (result) {
      case Success(:final data):
        emit(NotificationsLoaded(data));
      case Error(:final failure):
        emit(NotificationsError(failure.message));
    }
  }

  Future<void> markAsRead(String id) async {
    final result = await _markReadUseCase(id);
    if (result is Success && state is NotificationsLoaded) {
      final current = (state as NotificationsLoaded).notifications;
      final updated = current.map((n) {
        if (n.id == id) {
          return AppNotification(
            id: n.id,
            title: n.title,
            body: n.body,
            type: n.type,
            referenceId: n.referenceId,
            isRead: true,
            createdAt: n.createdAt,
          );
        }
        return n;
      }).toList();
      emit(NotificationsLoaded(updated));
      _badgeCubit.decrement();
    }
  }

  Future<void> markAllAsRead() async {
    if (state is! NotificationsLoaded) return;
    final current = (state as NotificationsLoaded).notifications;

    // Optimistic update — flip all to read and clear badge immediately
    final updated = current
        .map((n) => AppNotification(
              id: n.id,
              title: n.title,
              body: n.body,
              type: n.type,
              referenceId: n.referenceId,
              isRead: true,
              createdAt: n.createdAt,
            ))
        .toList();
    emit(NotificationsLoaded(updated));
    _badgeCubit.reset();

    final result = await _markAllReadUseCase();
    if (result is Error) {
      await loadNotifications();
    }
  }
}
