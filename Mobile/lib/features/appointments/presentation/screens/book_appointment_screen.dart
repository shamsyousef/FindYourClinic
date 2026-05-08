import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../cubits/booking_cubit.dart';
import '../cubits/booking_state.dart';
import '../widgets/time_slot_grid.dart';
import '../../../../core/widgets/user_avatar.dart';

/// Book Appointment screen — single scroll with date picker → time slot → summary.
class BookAppointmentScreen extends StatefulWidget {
  final String doctorProfileId; // DoctorProfile PK — used for booking
  final String doctorUserId; // User PK — used for fetching availability slots
  final String doctorName;
  final String specialty;
  final String? consultationFee;
  final String? clinicName;
  final String? doctorImageUrl;

  const BookAppointmentScreen({
    super.key,
    required this.doctorProfileId,
    required this.doctorUserId,
    required this.doctorName,
    required this.specialty,
    this.consultationFee,
    this.clinicName,
    this.doctorImageUrl,
  });

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  DateTime? _selectedDate;
  DateTime? _selectedSlot;
  List<DateTime> _cachedSlots = [];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocConsumer<BookingCubit, BookingState>(
        listener: (context, state) {
          if (state is BookingSlotsLoaded) {
            setState(() => _cachedSlots = state.slots);
          }
          if (state is BookingError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
            // If slot conflict, refresh slots for the selected date
            if (state.message.contains('already booked') &&
                _selectedDate != null) {
              context.read<BookingCubit>().loadSlots(
                doctorId: widget.doctorUserId,
                date: _selectedDate!,
              );
              setState(() {
                _selectedSlot = null;
                _cachedSlots = [];
              });
            }
          }
        },
        builder: (context, state) {
          final isSubmitting = state is BookingSubmitting;

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── Doctor Header Card ───
                    _buildDoctorCard(theme, isDark),
                    const SizedBox(height: 24),

                    // ─── Step 1: Select Date ───
                    _buildStepHeader(
                      1,
                      'Select Date',
                      Icons.calendar_today_outlined,
                      theme,
                    ),
                    const SizedBox(height: 12),
                    _buildCalendar(context, theme, isDark),
                    const SizedBox(height: 24),

                    // ─── Step 2: Available Times ───
                    if (_selectedDate != null) ...[
                      _buildStepHeader(
                        2,
                        'Available Times',
                        Icons.access_time_outlined,
                        theme,
                      ),
                      const SizedBox(height: 12),
                      _buildTimeSlotsSection(state, theme),
                      const SizedBox(height: 24),
                    ],

                    // ─── Appointment Summary ───
                    if (_selectedSlot != null) ...[
                      _buildSummaryCard(theme, isDark),
                    ],
                  ],
                ),
              ),

              // ─── Confirm Button ───
              if (_selectedSlot != null)
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: MediaQuery.of(context).padding.bottom + 16,
                  child: ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () => _navigateToCheckout(context),
                    child: isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Continue to Payment'),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _navigateToCheckout(BuildContext context) {
    // Parse fee from the consultationFee string like "150 EGP" or "150.00"
    final feeStr = widget.consultationFee ?? '0';
    final fee = double.tryParse(
          feeStr.replaceAll(RegExp(r'[^0-9.]'), ''),
        ) ??
        0.0;

    context.push('/checkout', extra: {
      'doctorProfileId': widget.doctorProfileId,
      'doctorName': widget.doctorName,
      'doctorImageUrl': widget.doctorImageUrl,
      'specialty': widget.specialty,
      'consultationFee': fee,
      'scheduledAt': _selectedSlot!,
      'locationName': widget.clinicName,
    });
  }

  Widget _buildDoctorCard(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkSurfaceAlt : AppColors.divider,
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          UserAvatar(
            radius: 24,
            imageUrl: widget.doctorImageUrl,
            fullName: widget.doctorName,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
            textStyle: AppTextStyles.heading3.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.doctorName,
                  style: AppTextStyles.label.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  widget.specialty,
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (widget.consultationFee != null)
                  Text(
                    widget.consultationFee!,
                    style: AppTextStyles.label.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepHeader(
    int step,
    String title,
    IconData icon,
    ThemeData theme,
  ) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            '$step',
            style: AppTextStyles.labelSm.copyWith(color: Colors.white),
          ),
        ),
        const SizedBox(width: 10),
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 6),
        Text(
          title,
          style: AppTextStyles.heading3.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildCalendar(BuildContext context, ThemeData theme, bool isDark) {
    final now = nowCairo();
    final firstDay = DateTime(now.year, now.month, now.day);
    final lastDay = firstDay.add(const Duration(days: 60));

    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkSurfaceAlt : AppColors.divider,
          width: 0.5,
        ),
      ),
      child: CalendarDatePicker(
        initialDate: _selectedDate ?? firstDay,
        firstDate: firstDay,
        lastDate: lastDay,
        onDateChanged: (date) {
          setState(() {
            _selectedDate = date;
            _selectedSlot = null;
            _cachedSlots = [];
          });
          context.read<BookingCubit>().loadSlots(
            doctorId: widget.doctorUserId,
            date: date,
          );
        },
      ),
    );
  }

  Widget _buildTimeSlotsSection(BookingState state, ThemeData theme) {
    if (state is BookingSlotsLoading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (state is BookingSlotsEmpty) {
      return Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(Icons.event_busy_outlined, size: 40, color: AppColors.warning),
            const SizedBox(height: 8),
            Text(
              'No available slots for this date',
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Try selecting a different date',
              style: AppTextStyles.bodySm.copyWith(color: AppColors.textHint),
            ),
            const SizedBox(height: 16),
          ],
        ),
      );
    }

    if (_cachedSlots.isNotEmpty) {
      return TimeSlotGrid(
        slots: _cachedSlots,
        selectedSlot: _selectedSlot,
        onSlotSelected: (slot) => setState(() => _selectedSlot = slot),
      );
    }

    // Initial — show prompt
    return Center(
      child: Text(
        'Select a date to see available times',
        style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildSummaryCard(ThemeData theme, bool isDark) {
    final slot = _selectedSlot!;
    final endSlot = slot.add(const Duration(minutes: 30));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Appointment Summary',
            style: AppTextStyles.label.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          if (widget.clinicName != null)
            _summaryRow(Icons.location_on_outlined, widget.clinicName!, theme),
          _summaryRow(
            Icons.calendar_today_outlined,
            DateFormat.yMMMMEEEEd().format(slot),
            theme,
          ),
          _summaryRow(
            Icons.access_time_outlined,
            '${DateFormat.jm().format(slot)} — ${DateFormat.jm().format(endSlot)}',
            theme,
          ),
          if (widget.consultationFee != null) ...[
            const SizedBox(height: 8),
            Text(
              'Consultation Fee: ${widget.consultationFee}',
              style: AppTextStyles.label.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryRow(IconData icon, String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodyMd.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
