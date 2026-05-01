import '../../../../core/utils/date_utils.dart';
import '../../domain/entities/notification_entity.dart';

class AppNotificationModel {
  final String id;
  final String title;
  final String body;
  final String? type;
  final bool isRead;
  final DateTime createdAt;

  const AppNotificationModel({
    required this.id,
    required this.title,
    required this.body,
    this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    return AppNotificationModel(
      id: json['id'],
      title: json['title'] ?? '',
      body: json['body'] ?? json['message'] ?? '',
      type: json['type'],
      isRead: json['isRead'] ?? false,
      createdAt: parseServerDateTime(json['createdAt']),
    );
  }

  AppNotification toEntity() => AppNotification(
        id: id,
        title: title,
        body: body,
        type: type,
        isRead: isRead,
        createdAt: createdAt,
      );
}
