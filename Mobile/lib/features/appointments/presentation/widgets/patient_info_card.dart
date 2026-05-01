import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../health_records/domain/entities/health_record_entity.dart';
import '../../../patient_profile/domain/entities/user_profile_entity.dart';
import '../cubits/patient_card_cubit.dart';

/// Full patient info card shown to the doctor in the appointment detail screen.
class PatientInfoCard extends StatelessWidget {
  final String patientId;

  const PatientInfoCard({super.key, required this.patientId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PatientCardCubit, PatientCardState>(
      builder: (context, state) => switch (state) {
        PatientCardInitial() || PatientCardLoading() => const _LoadingCard(),
        PatientCardError(:final message) => _ErrorCard(message: message),
        PatientCardLoaded(:final profile, :final records) =>
          _LoadedCard(profile: profile, records: records),
      },
    );
  }
}

// ─── Loading ──────────────────────────────────────────────────────────────────

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

// ─── Error ────────────────────────────────────────────────────────────────────

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: AppTextStyles.bodySm.copyWith(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

// ─── Loaded ───────────────────────────────────────────────────────────────────

class _LoadedCard extends StatelessWidget {
  final UserProfileEntity profile;
  final List<HealthRecordEntity> records;

  const _LoadedCard({required this.profile, required this.records});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section label ──
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.person_outline,
                    size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 8),
              Text('Patient Profile', style: AppTextStyles.label),
            ],
          ),
        ),

        // ── Header card: avatar + name + quick stats ──
        _SectionCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Avatar(name: profile.fullName, imageUrl: profile.profileImageUrl),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(profile.fullName, style: AppTextStyles.heading3),
                    const SizedBox(height: 2),
                    Text(
                      profile.email,
                      style: AppTextStyles.bodySm
                          .copyWith(color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    // Quick badges: gender, blood type, age
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        if (profile.gender != null)
                          _Badge(
                            icon: Icons.wc_outlined,
                            label: profile.gender!,
                            color: AppColors.secondary,
                          ),
                        if (profile.bloodType != null)
                          _Badge(
                            icon: Icons.water_drop_outlined,
                            label: profile.bloodType!,
                            color: AppColors.error,
                          ),
                        if (profile.dateOfBirth != null)
                          _Badge(
                            icon: Icons.cake_outlined,
                            label: '${_age(profile.dateOfBirth!)} yrs',
                            color: AppColors.primary,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // ── Contact & personal details ──
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Contact & Personal', style: AppTextStyles.label),
              const SizedBox(height: 12),
              if (profile.dateOfBirth != null)
                _DetailRow(
                  icon: Icons.calendar_month_outlined,
                  label: 'Date of Birth',
                  value: DateFormat.yMMMd().format(profile.dateOfBirth!),
                ),
              if (profile.phoneNumber != null)
                _DetailRow(
                  icon: Icons.phone_outlined,
                  label: 'Phone',
                  value: profile.phoneNumber!,
                ),
              if (profile.address != null)
                _DetailRow(
                  icon: Icons.location_on_outlined,
                  label: 'Address',
                  value: profile.address!,
                ),
              if (profile.dateOfBirth == null &&
                  profile.phoneNumber == null &&
                  profile.address == null)
                Text(
                  'No contact details provided.',
                  style: AppTextStyles.bodySm
                      .copyWith(color: AppColors.textSecondary),
                ),
            ],
          ),
        ),

        // ── Emergency contact ──
        if (profile.emergencyContactName != null ||
            profile.emergencyContactPhone != null) ...[
          const SizedBox(height: 10),
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.emergency_outlined,
                        size: 16, color: AppColors.warning),
                    const SizedBox(width: 6),
                    Text('Emergency Contact',
                        style: AppTextStyles.label
                            .copyWith(color: AppColors.warning)),
                  ],
                ),
                const SizedBox(height: 12),
                if (profile.emergencyContactName != null)
                  _DetailRow(
                    icon: Icons.person_outline,
                    label: 'Name',
                    value: profile.emergencyContactName!,
                  ),
                if (profile.emergencyContactPhone != null)
                  _DetailRow(
                    icon: Icons.phone_outlined,
                    label: 'Phone',
                    value: profile.emergencyContactPhone!,
                  ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 10),

        // ── Health records ──
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Health Records', style: AppTextStyles.label),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${records.length}',
                      style: AppTextStyles.labelSm.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (records.isEmpty)
                Text(
                  'No health records available.',
                  style: AppTextStyles.bodySm
                      .copyWith(color: AppColors.textSecondary),
                )
              else
                ...records.take(10).map((r) => _RecordTile(record: r)),
              if (records.length > 10)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '+ ${records.length - 10} more records',
                    style: AppTextStyles.bodySm
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  int _age(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }
}

// ─── Record tile ─────────────────────────────────────────────────────────────

class _RecordTile extends StatelessWidget {
  final HealthRecordEntity record;
  const _RecordTile({required this.record});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: _typeColor(record.type).withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_typeIcon(record.type),
                size: 16, color: _typeColor(record.type)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record.title,
                    style: AppTextStyles.bodyMd
                        .copyWith(fontWeight: FontWeight.w500)),
                if (record.value != null)
                  Text(
                    '${record.value}${record.unit != null ? ' ${record.unit}' : ''}',
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (record.notes != null)
                  Text(
                    record.notes!,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                Text(
                  DateFormat.yMMMd().format(record.recordedAt),
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _typeColor(record.type).withAlpha(15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _typeLabel(record.type),
              style: AppTextStyles.caption.copyWith(
                color: _typeColor(record.type),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _typeIcon(HealthRecordType type) => switch (type) {
        HealthRecordType.bloodPressure => Icons.monitor_heart_outlined,
        HealthRecordType.heartRate => Icons.favorite_outlined,
        HealthRecordType.bloodSugar => Icons.water_drop_outlined,
        HealthRecordType.temperature => Icons.thermostat_outlined,
        HealthRecordType.weight => Icons.monitor_weight_outlined,
        HealthRecordType.spO2 => Icons.air_outlined,
        HealthRecordType.labResult => Icons.science_outlined,
        HealthRecordType.bloodTest => Icons.biotech_outlined,
        HealthRecordType.radiology => Icons.medical_services_outlined,
        HealthRecordType.vaccination => Icons.vaccines_outlined,
        HealthRecordType.prescription => Icons.medication_outlined,
        HealthRecordType.other => Icons.note_alt_outlined,
      };

  Color _typeColor(HealthRecordType type) => switch (type) {
        HealthRecordType.bloodPressure ||
        HealthRecordType.heartRate =>
          AppColors.error,
        HealthRecordType.bloodSugar ||
        HealthRecordType.bloodTest =>
          const Color(0xFFEC4899),
        HealthRecordType.temperature => AppColors.warning,
        HealthRecordType.weight => AppColors.secondary,
        HealthRecordType.spO2 => const Color(0xFF06B6D4),
        HealthRecordType.labResult ||
        HealthRecordType.radiology =>
          const Color(0xFF8B5CF6),
        HealthRecordType.vaccination => AppColors.success,
        HealthRecordType.prescription => AppColors.primary,
        HealthRecordType.other => AppColors.textSecondary,
      };

  String _typeLabel(HealthRecordType type) => switch (type) {
        HealthRecordType.bloodPressure => 'BP',
        HealthRecordType.heartRate => 'HR',
        HealthRecordType.bloodSugar => 'Sugar',
        HealthRecordType.temperature => 'Temp',
        HealthRecordType.weight => 'Weight',
        HealthRecordType.spO2 => 'SpO2',
        HealthRecordType.labResult => 'Lab',
        HealthRecordType.bloodTest => 'Blood',
        HealthRecordType.radiology => 'Xray',
        HealthRecordType.vaccination => 'Vacc',
        HealthRecordType.prescription => 'Rx',
        HealthRecordType.other => 'Other',
      };
}

// ─── Shared small widgets ─────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline.withAlpha(40)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 14, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 1),
                Text(value,
                    style: AppTextStyles.bodyMd
                        .copyWith(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Badge(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: AppTextStyles.caption
                  .copyWith(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final String? imageUrl;
  const _Avatar({required this.name, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    const colors = [
      AppColors.primary,
      AppColors.secondary,
      Color(0xFF8B5CF6),
      Color(0xFFEC4899),
      Color(0xFF06B6D4),
    ];
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final bg = colors[initial.codeUnitAt(0) % colors.length];

    return UserAvatar(
      radius: 30,
      imageUrl: imageUrl,
      fullName: name,
      backgroundColor: bg,
      textStyle: AppTextStyles.heading3.copyWith(color: Colors.white),
    );
  }
}
