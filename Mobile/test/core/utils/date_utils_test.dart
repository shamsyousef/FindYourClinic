import 'package:find_your_clinic/core/utils/date_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseServerDateTime', () {
    test('treats timestamp without timezone suffix as UTC', () {
      const raw = '2026-05-01T12:30:00';
      final parsed = parseServerDateTime(raw);
      final expected = DateTime.parse('${raw}Z').toLocal();

      expect(parsed, expected);
    });

    test('keeps explicit UTC timestamps correct', () {
      const raw = '2026-05-01T12:30:00Z';
      final parsed = parseServerDateTime(raw);
      final expected = DateTime.parse(raw).toLocal();

      expect(parsed, expected);
    });
  });

  group('formatRelativeTime', () {
    final now = DateTime(2026, 5, 1, 15, 0);

    test('returns "Just now" for under one minute', () {
      final result = formatRelativeTime(
        now.subtract(const Duration(seconds: 30)),
        now: now,
      );

      expect(result, 'Just now');
    });

    test('returns minute labels', () {
      final result = formatRelativeTime(
        now.subtract(const Duration(minutes: 5)),
        now: now,
      );

      expect(result, '5m ago');
    });

    test('returns hour labels', () {
      final result = formatRelativeTime(
        now.subtract(const Duration(hours: 2)),
        now: now,
      );

      expect(result, '2h ago');
    });

    test('returns day labels', () {
      final result = formatRelativeTime(
        now.subtract(const Duration(days: 3)),
        now: now,
      );

      expect(result, '3d ago');
    });
  });
}
