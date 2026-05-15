import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../health_records/domain/entities/health_record_entity.dart';
import '../../../health_records/domain/usecases/health_record_usecases.dart';
import '../cubits/booking_cubit.dart';
import '../cubits/booking_state.dart';
import '../widgets/step_indicator.dart';
import '../widgets/time_slot_grid.dart';

/// Book Appointment screen — 4-step wizard:
/// Step 0: When would you like to come in? (date + time slot)
/// Step 1: What brings you in today? (reason for visit)
/// Step 2: Any health warnings we should know? (allergy review)
/// Step 3: Does everything look right? (summary + confirm)
class BookAppointmentScreen extends StatefulWidget {
  final String doctorProfileId;
  final String doctorUserId;
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
  // ─── Wizard state ───
  int _currentStep = 0;
  static const int _totalSteps = 4;
  static const _stepLabels = ['Date & Time', 'Reason', 'Allergies', 'Summary'];

  // ─── Step 0 data ───
  DateTime? _selectedDate;
  DateTime? _selectedSlot;
  List<DateTime> _cachedSlots = [];

  // ─── Step 1 data ───
  final _reasonController = TextEditingController();
  final _reasonFocusNode = FocusNode();
  bool _reasonError = false;

  // ─── Step 2 data ───
  List<HealthRecordEntity> _allergies = [];
  bool _loadingAllergies = false;
  Set<String> _dismissedAllergyIds = {};

  @override
  void dispose() {
    _reasonController.dispose();
    _reasonFocusNode.dispose();
    super.dispose();
  }

  // ─── Step navigation ───
  void _goNext() {
    if (_currentStep == 0 && _selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date and time slot.')),
      );
      return;
    }
    if (_currentStep == 1) {
      if (_reasonController.text.trim().isEmpty) {
        setState(() => _reasonError = true);
        _reasonFocusNode.requestFocus();
        return;
      }
      setState(() => _reasonError = false);
    }
    if (_currentStep == 1) _fetchAllergies();
    setState(() => _currentStep++);
  }

  void _goBack() {
    if (_currentStep == 0) {
      context.pop();
    } else {
      setState(() => _currentStep--);
    }
  }

  Future<void> _fetchAllergies() async {
    setState(() => _loadingAllergies = true);
    try {
      final useCase = sl<GetHealthRecordsUseCase>();
      final result = await useCase(type: HealthRecordType.allergy);
      if (result is Success<List<HealthRecordEntity>>) {
        setState(() => _allergies = result.data);
      } else {
        setState(() => _allergies = []);
      }
    } catch (_) {
      setState(() => _allergies = []);
    } finally {
      setState(() => _loadingAllergies = false);
    }
  }

  void _navigateToCheckout() {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
              _currentStep == 0 ? Icons.close : Icons.arrow_back_ios_new_rounded,
              size: 20),
          onPressed: _goBack,
        ),
        title: const Text('Book Appointment'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(72),
          child: StepIndicator(
            currentStep: _currentStep,
            totalSteps: _totalSteps,
            stepLabels: _stepLabels,
          ),
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
        builder: (context, bookingState) {
          final isSubmitting = bookingState is BookingSubmitting;
          return Column(
            children: [
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: KeyedSubtree(
                    key: ValueKey(_currentStep),
                    child: _buildStep(context, bookingState),
                  ),
                ),
              ),
              _buildBottomButton(context, isSubmitting),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStep(BuildContext context, BookingState state) {
    return switch (_currentStep) {
      0 => _buildStep0(context, state),
      1 => _buildStep1(context),
      2 => _buildStep2(context),
      3 => _buildStep3(context),
      _ => const SizedBox.shrink(),
    };
  }

  // ─── Step 0: Date & Time ───
  Widget _buildStep0(BuildContext context, BookingState state) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final now = nowCairo();
    final firstDay = DateTime(now.year, now.month, now.day);
    final lastDay = firstDay.add(const Duration(days: 60));

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DoctorCard(widget: widget),
          const SizedBox(height: 20),
          Text(
            'When would you like to come in?',
            style: AppTextStyles.heading3.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Container(
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
          ),
          if (_selectedDate != null) ...[
            const SizedBox(height: 20),
            Text(
              'Available Times',
              style: AppTextStyles.label.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            _buildTimeSlotsSection(state, theme),
          ],
        ],
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
            Text('No available slots for this date',
                style: AppTextStyles.bodyMd
                    .copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text('Try selecting a different date',
                style: AppTextStyles.bodySm.copyWith(color: AppColors.textHint)),
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
    return Center(
      child: Text('Select a date to see available times',
          style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondary)),
    );
  }

  // ─── Step 1: Reason for visit ───
  Widget _buildStep1(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What brings you in today?',
            style: AppTextStyles.heading2.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This helps the doctor prepare for your visit.',
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _reasonController,
            focusNode: _reasonFocusNode,
            maxLines: 5,
            autofocus: true,
            decoration: InputDecoration(
              hintText:
                  'e.g. I\'ve had a persistent headache for 3 days and some dizziness...',
              errorText: _reasonError ? 'Please describe your reason for visit' : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              alignLabelWithHint: true,
            ),
            onChanged: (v) {
              if (_reasonError && v.trim().isNotEmpty) {
                setState(() => _reasonError = false);
              }
            },
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              'Routine checkup',
              'Follow-up visit',
              'New symptoms',
              'Chronic condition',
              'Prescription renewal',
            ]
                .map((s) => ActionChip(
                      label: Text(s),
                      onPressed: () => setState(() {
                        _reasonController.text = s;
                        _reasonError = false;
                      }),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  // ─── Step 2: Allergy review ───
  Widget _buildStep2(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Any health warnings we should know?',
            style: AppTextStyles.heading2.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We\'ve pulled your allergy records so the doctor knows in advance.',
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          if (_loadingAllergies)
            const Center(child: CircularProgressIndicator())
          else if (_allergies.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark
                    ? Colors.green.shade900.withValues(alpha: 0.3)
                    : Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.brightness == Brightness.dark
                      ? Colors.green.shade800
                      : Colors.green.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: theme.brightness == Brightness.dark
                        ? Colors.green.shade400
                        : Colors.green.shade600,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('No allergy records found. You\'re all clear!'),
                  ),
                ],
              ),
            )
          else
            Column(
              children: _allergies
                  .where((a) => !_dismissedAllergyIds.contains(a.id))
                  .map(
                    (a) => Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: theme.brightness == Brightness.dark
                              ? Colors.red.shade900
                              : Colors.red.shade200,
                        ),
                      ),
                      child: ListTile(
                        leading: Icon(
                          Icons.warning_amber_rounded,
                          color: theme.brightness == Brightness.dark
                              ? Colors.red.shade400
                              : Colors.red.shade600,
                        ),
                        title: Text(
                          a.title,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: a.notes != null
                            ? Text(
                                a.notes!,
                                style: TextStyle(
                                  color: theme.brightness == Brightness.dark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.textSecondary,
                                ),
                              )
                            : null,
                        trailing: IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () => setState(
                              () => _dismissedAllergyIds.add(a.id)),
                          tooltip: 'Dismiss this allergy',
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  // ─── Step 3: Summary ───
  Widget _buildStep3(BuildContext context) {
    final theme = Theme.of(context);
    final slot = _selectedSlot!;
    final end = slot.add(const Duration(minutes: 30));
    final activeAllergies = _allergies
        .where((a) => !_dismissedAllergyIds.contains(a.id))
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Does everything look right?',
            style: AppTextStyles.heading2.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Review your booking details before confirming.',
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          _DoctorCard(widget: widget),
          const SizedBox(height: 16),
          _SummarySection(
            children: [
              _SummaryRow(
                icon: Icons.calendar_today_outlined,
                label: 'Date',
                value: DateFormat.yMMMMEEEEd().format(slot),
              ),
              _SummaryRow(
                icon: Icons.access_time_outlined,
                label: 'Time',
                value:
                    '${DateFormat.jm().format(slot)} — ${DateFormat.jm().format(end)}',
              ),
              if (widget.clinicName != null)
                _SummaryRow(
                  icon: Icons.location_on_outlined,
                  label: 'Clinic',
                  value: widget.clinicName!,
                ),
              if (widget.consultationFee != null)
                _SummaryRow(
                  icon: Icons.payments_outlined,
                  label: 'Fee',
                  value: widget.consultationFee!,
                ),
            ],
          ),
          const SizedBox(height: 12),
          _SummarySection(
            children: [
              _SummaryRow(
                icon: Icons.notes_outlined,
                label: 'Reason for visit',
                value: _reasonController.text.trim(),
              ),
            ],
          ),
          if (activeAllergies.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark
                    ? Colors.red.shade900.withValues(alpha: 0.3)
                    : Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.brightness == Brightness.dark
                      ? Colors.red.shade800
                      : Colors.red.shade200,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: theme.brightness == Brightness.dark
                        ? Colors.red.shade400
                        : Colors.red.shade600,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Allergy Alert',
                          style: TextStyle(
                            color: theme.brightness == Brightness.dark
                                ? Colors.red.shade300
                                : Colors.red.shade700,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          activeAllergies.map((a) => a.title).join(', '),
                          style: TextStyle(
                            color: theme.brightness == Brightness.dark
                                ? Colors.red.shade200
                                : Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Bottom action button ───
  Widget _buildBottomButton(BuildContext context, bool isSubmitting) {
    final label = switch (_currentStep) {
      0 => 'Next — What\'s the reason?',
      1 => 'Next — Health warnings',
      2 => 'Next — Review booking',
      _ => 'Confirm & Pay',
    };

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: FilledButton(
          onPressed: isSubmitting
              ? null
              : () {
                  if (_currentStep < _totalSteps - 1) {
                    _goNext();
                  } else {
                    _navigateToCheckout();
                  }
                },
          child: isSubmitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Text(label),
        ),
      ),
    );
  }
}

// ─── Shared sub-widgets ───

class _DoctorCard extends StatelessWidget {
  final BookAppointmentScreen widget;
  const _DoctorCard({required this.widget});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
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
            radius: 22,
            imageUrl: widget.doctorImageUrl,
            fullName: widget.doctorName,
            backgroundColor:
                theme.colorScheme.primary.withValues(alpha: 0.15),
            textStyle: AppTextStyles.heading3
                .copyWith(color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.doctorName,
                    style: AppTextStyles.label
                        .copyWith(color: theme.colorScheme.onSurface)),
                Text(widget.specialty,
                    style: AppTextStyles.bodySm
                        .copyWith(color: AppColors.textSecondary)),
                if (widget.consultationFee != null)
                  Text(widget.consultationFee!,
                      style: AppTextStyles.label
                          .copyWith(color: theme.colorScheme.primary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummarySection extends StatelessWidget {
  final List<Widget> children;
  const _SummarySection({required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: children),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _SummaryRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Text('$label: ',
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600)),
          Expanded(
              child: Text(value, style: theme.textTheme.bodySmall)),
        ],
      ),
    );
  }
}
