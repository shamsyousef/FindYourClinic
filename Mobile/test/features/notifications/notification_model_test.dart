import 'package:find_your_clinic/features/notifications/data/models/notification_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppNotificationModel.fromJson', () {
    test('parses referenceId when present', () {
      final json = {
        'id': 'abc-123',
        'title': 'Test',
        'body': 'Body',
        'type': 'appointment_booked',
        'referenceId': 'appt-456',
        'isRead': false,
        'createdAt': '2026-05-08T10:00:00Z',
      };

      final model = AppNotificationModel.fromJson(json);

      expect(model.referenceId, 'appt-456');
      expect(model.toEntity().referenceId, 'appt-456');
    });

    test('referenceId is null when absent from json', () {
      final json = {
        'id': 'abc-123',
        'title': 'Test',
        'body': 'Body',
        'isRead': false,
        'createdAt': '2026-05-08T10:00:00Z',
      };

      final model = AppNotificationModel.fromJson(json);

      expect(model.referenceId, isNull);
      expect(model.toEntity().referenceId, isNull);
    });
  });
}
