import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';

class AddAvailabilitySheet extends StatefulWidget {
  final void Function(String dayOfWeek, String startTime, String endTime) onAdd;

  const AddAvailabilitySheet({super.key, required this.onAdd});

  @override
  State<AddAvailabilitySheet> createState() => _AddAvailabilitySheetState();
}

class _AddAvailabilitySheetState extends State<AddAvailabilitySheet> {
  String _selectedDay = 'Monday';
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);

  final _days = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    final borderColor = isDark ? Colors.white12 : AppColors.divider;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Add Availability',
                  style: AppTextStyles.heading3.copyWith(color: textColor)),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close, color: textColor),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Day of Week',
              style: AppTextStyles.label.copyWith(color: textColor)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(12),
              color: bgColor,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedDay,
                isExpanded: true,
                dropdownColor: bgColor,
                iconEnabledColor: textColor,
                style: TextStyle(color: textColor),
                items: _days
                    .map((day) => DropdownMenuItem(
                          value: day,
                          child: Text(day, style: TextStyle(color: textColor)),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedDay = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Start Time',
                        style: AppTextStyles.label.copyWith(color: textColor)),
                    const SizedBox(height: 8),
                    _TimePickerTile(
                      time: _startTime,
                      bgColor: bgColor,
                      borderColor: borderColor,
                      textColor: textColor,
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: _startTime,
                        );
                        if (time != null) setState(() => _startTime = time);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('End Time',
                        style: AppTextStyles.label.copyWith(color: textColor)),
                    const SizedBox(height: 8),
                    _TimePickerTile(
                      time: _endTime,
                      bgColor: bgColor,
                      borderColor: borderColor,
                      textColor: textColor,
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: _endTime,
                        );
                        if (time != null) setState(() => _endTime = time);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          AppButton(
            text: 'Save Slot',
            onPressed: () {
              final startStr =
                  '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}:00';
              final endStr =
                  '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}:00';
              widget.onAdd(_selectedDay, startStr, endStr);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

class _TimePickerTile extends StatelessWidget {
  final TimeOfDay time;
  final Color bgColor;
  final Color borderColor;
  final Color textColor;
  final VoidCallback onTap;

  const _TimePickerTile({
    required this.time,
    required this.bgColor,
    required this.borderColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(12),
          color: bgColor,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(time.format(context),
                style: AppTextStyles.bodyMd.copyWith(color: textColor)),
            Icon(Icons.access_time, size: 20, color: textColor),
          ],
        ),
      ),
    );
  }
}
