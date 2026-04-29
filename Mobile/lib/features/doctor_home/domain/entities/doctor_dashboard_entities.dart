// Domain entities for the doctor dashboard.
// Pure Dart — no Flutter imports.

class DoctorDashboard {
  final QuickStats quickStats;
  final NextAppointment? nextAppointment;
  final PerformanceSummary performance;
  final List<ScheduleItem> todaySchedule;

  const DoctorDashboard({
    required this.quickStats,
    this.nextAppointment,
    required this.performance,
    required this.todaySchedule,
  });
}

class QuickStats {
  final int totalToday;
  final int completed;
  final int pending;
  final int cancelled;

  const QuickStats({
    required this.totalToday,
    required this.completed,
    required this.pending,
    required this.cancelled,
  });
}

class NextAppointment {
  final String appointmentId;
  final DateTime scheduledAt;
  final String status;
  final String? locationName;
  final String patientId;
  final String patientName;
  final String? patientImageUrl;

  const NextAppointment({
    required this.appointmentId,
    required this.scheduledAt,
    required this.status,
    this.locationName,
    required this.patientId,
    required this.patientName,
    this.patientImageUrl,
  });
}

class PerformanceSummary {
  final int patientsThisMonth;
  final double averageRating;
  final int totalReviews;

  const PerformanceSummary({
    required this.patientsThisMonth,
    required this.averageRating,
    required this.totalReviews,
  });
}

class ScheduleItem {
  final String appointmentId;
  final DateTime scheduledAt;
  final String status;
  final String patientId;
  final String patientName;
  final String? patientImageUrl;

  const ScheduleItem({
    required this.appointmentId,
    required this.scheduledAt,
    required this.status,
    required this.patientId,
    required this.patientName,
    this.patientImageUrl,
  });
}
