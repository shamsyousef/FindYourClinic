sealed class NotificationBadgeState {
  const NotificationBadgeState();
}

class NotificationBadgeInitial extends NotificationBadgeState {
  const NotificationBadgeInitial();
}

class NotificationBadgeLoaded extends NotificationBadgeState {
  final int unreadCount;
  const NotificationBadgeLoaded(this.unreadCount);
}
