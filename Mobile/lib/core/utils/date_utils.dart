import 'package:intl/intl.dart';

final RegExp _timezoneSuffix = RegExp(r'(Z|[+-]\d{2}:\d{2})$');

/// Parse a server timestamp and convert it to the device's local timezone.
///
/// The backend stores values in UTC, but some payloads can be serialized without
/// an explicit timezone suffix. In that case, force UTC interpretation first.
DateTime parseServerDateTime(String raw) {
  final normalized = _timezoneSuffix.hasMatch(raw) ? raw : '${raw}Z';
  return DateTime.parse(normalized).toLocal();
}

/// Current wall-clock time in the device's local timezone.
DateTime nowLocal() => DateTime.now().toLocal();

/// Backward-compatible alias kept for existing call sites.
DateTime nowCairo() => nowLocal();

/// Short relative time label used by timeline-like UI elements.
String formatRelativeTime(DateTime dateTime, {DateTime? now}) {
  final reference = now ?? nowLocal();
  final target = dateTime.toLocal();
  final diff = reference.difference(target);

  if (diff.isNegative || diff.inSeconds < 60) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return DateFormat('MMM d').format(target);
}
