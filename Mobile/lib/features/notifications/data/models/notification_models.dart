import '../../../../core/utils/date_utils.dart';
import '../../domain/entities/notification_entity.dart';

class AppNotificationModel {
  final String id;
  final String title;
  final String body;
  final String? type;
  final String? referenceId;
  final bool isRead;
  final DateTime createdAt;

  const AppNotificationModel({
    required this.id,
    required this.title,
    required this.body,
    this.type,
    this.referenceId,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    return AppNotificationModel(
      id: json['id'],
      title: json['title'] ?? '',
      body: json['body'] ?? json['message'] ?? '',
      type: json['type'],
      referenceId: json['referenceId'],
      isRead: json['isRead'] ?? false,
      createdAt: parseServerDateTime(json['createdAt']),
    );
  }

  AppNotification toEntity() => AppNotification(
        id: id,
        title: title,
        body: body,
        type: type,
        referenceId: referenceId,
        isRead: isRead,
        createdAt: createdAt,
      );
}
