import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';

class BookingSuccessScreen extends StatefulWidget {
  final bool isConfirmed;
  final String doctorName;
  final DateTime scheduledAt;
  final String? appointmentId;

  const BookingSuccessScreen({
    super.key,
    required this.isConfirmed,
    required this.doctorName,
    required this.scheduledAt,
    this.appointmentId,
  });

  @override
  State<BookingSuccessScreen> createState() => _BookingSuccessScreenState();
}

class _BookingSuccessScreenState extends State<BookingSuccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(
        parent: _controller, curve: const Interval(0.3, 1.0, curve: Curves.easeIn));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final confirmed = widget.isConfirmed;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Column(
              children: [
                const Spacer(),

                // ─── Icon ───
                ScaleTransition(
                  scale: _scaleAnim,
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: confirmed
                          ? AppColors.success.withValues(alpha: 0.12)
                          : AppColors.warning.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      confirmed
                          ? Icons.check_circle_rounded
                          : Icons.access_time_rounded,
                      size: 68,
                      color: confirmed ? AppColors.success : AppColors.warning,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // ─── Title + Subtitle ───
                FadeTransition(
                  opacity: _fadeAnim,
                  child: Column(
                    children: [
                      Text(
                        confirmed ? 'Booking Confirmed!' : 'Booking Request Sent',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        confirmed
                            ? 'Your payment was processed successfully. Your appointment is confirmed.'
                            : 'Your booking request has been sent. Waiting for the doctor to confirm.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // ─── Details Card ───
                FadeTransition(
                  opacity: _fadeAnim,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.white10 : AppColors.divider,
                      ),
                    ),
                    child: Column(
                      children: [
                        _DetailRow(
                          icon: Icons.person_rounded,
                          label: 'Doctor',
                          value: 'Dr. ${widget.doctorName}',
                        ),
                        const SizedBox(height: 12),
                        _DetailRow(
                          icon: Icons.calendar_today_rounded,
                          label: 'Date',
                          value: DateFormat('EEE, MMM dd, yyyy').format(widget.scheduledAt),
                        ),
                        const SizedBox(height: 12),
                        _DetailRow(
                          icon: Icons.access_time_rounded,
                          label: 'Time',
                          value: DateFormat('hh:mm a').format(widget.scheduledAt),
                        ),
                        if (!confirmed) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline_rounded,
                                    size: 16, color: AppColors.warning),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'You will be notified once the doctor confirms.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.warning,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // ─── Actions ───
                FadeTransition(
                  opacity: _fadeAnim,
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {
                            if (confirmed && widget.appointmentId != null) {
                              context.go('/appointment/${widget.appointmentId}?doctor=false');
                            } else {
                              context.go('/patient/appointments');
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            confirmed ? 'View Appointment' : 'View Appointments',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => context.go('/patient/home'),
                        child: Text(
                          'Go Home',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
