// Domain entity for notifications.
// Pure Dart — no Flutter imports.

class AppNotification {
  final String id;
  final String title;
  final String body;
  final String? type;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    this.type,
    required this.isRead,
    required this.createdAt,
  });
}
