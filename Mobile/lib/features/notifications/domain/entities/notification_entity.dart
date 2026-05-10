class AppNotification {
  final String id;
  final String title;
  final String body;
  final String? type;
  final String? referenceId;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    this.type,
    this.referenceId,
    required this.isRead,
    required this.createdAt,
  });
}
