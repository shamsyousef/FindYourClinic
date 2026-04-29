import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_result.dart';
import '../../domain/usecases/notification_usecases.dart';
import 'notification_badge_state.dart';

class NotificationBadgeCubit extends Cubit<NotificationBadgeState> {
  final GetUnreadNotificationCountUseCase _getUnreadCountUseCase;

  NotificationBadgeCubit({
    required GetUnreadNotificationCountUseCase getUnreadCountUseCase,
  })  : _getUnreadCountUseCase = getUnreadCountUseCase,
        super(const NotificationBadgeInitial());

  Future<void> loadUnreadCount() async {
    final result = await _getUnreadCountUseCase();
    switch (result) {
      case Success(:final data):
        emit(NotificationBadgeLoaded(data));
      case Error():
        // Keep existing state on error — badge silently stays unchanged
        break;
    }
  }

  void increment() {
    final current = state is NotificationBadgeLoaded
        ? (state as NotificationBadgeLoaded).unreadCount
        : 0;
    emit(NotificationBadgeLoaded(current + 1));
  }

  void reset() => emit(const NotificationBadgeLoaded(0));
}
