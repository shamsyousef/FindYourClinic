import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../cubits/patient_profile_cubit.dart';
import '../cubits/patient_profile_state.dart';

class PatientProfileScreen extends StatelessWidget {
  const PatientProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<PatientProfileCubit, PatientProfileState>(
        listener: (context, state) {
          if (state is PatientProfileError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is PatientProfileLoading ||
              state is PatientProfileInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is PatientProfileError) {
            return ErrorView(
              message: state.message,
              onRetry: () => context.read<PatientProfileCubit>().loadProfile(),
            );
          }

          final (profile, stats) = switch (state) {
            PatientProfileLoaded(:final profile, :final stats) => (
              profile,
              stats,
            ),
            PatientProfileUpdating(:final profile, :final stats) => (
              profile,
              stats,
            ),
            PatientProfileUpdateSuccess(:final profile, :final stats) => (
              profile,
              stats,
            ),
            _ => (null, null),
          };

          if (profile == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return _ProfileBody(profile: profile, stats: stats!);
        },
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  final dynamic profile;
  final PatientStats stats;
  const _ProfileBody({required this.profile, required this.stats});

  String get _initials {
    final name = profile.fullName as String;
    final parts = name.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : 'P';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: () => context.read<PatientProfileCubit>().loadProfile(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          // ─── Header card ───
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.outline.withAlpha(40)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(12),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Stack(
                      children: [
                        UserAvatar(
                          radius: 32,
                          imageUrl: profile.profileImageUrl,
                          initials: _initials,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: cs.surface, width: 1.5),
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.fullName as String,
                            style: AppTextStyles.heading3.copyWith(
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            profile.email as String,
                            style: AppTextStyles.bodySm.copyWith(
                              color: cs.onSurface.withAlpha(160),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(25),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Patient',
                              style: AppTextStyles.bodySm.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _StatItem(
                      value: stats.appointmentsCount.toString(),
                      label: 'Appointments',
                      color: AppColors.primary,
                    ),
                    _StatDivider(),
                    _StatItem(
                      value: stats.doctorsCount.toString(),
                      label: 'Doctors',
                      color: AppColors.secondary,
                    ),
                    _StatDivider(),
                    _StatItem(
                      value: stats.recordsCount.toString(),
                      label: 'Records',
                      color: AppColors.success,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ─── My Health ───
          _SectionHeader('MY HEALTH'),
          _SettingsTile(
            icon: Icons.person_outline,
            iconBg: AppColors.primary.withAlpha(25),
            iconColor: AppColors.primary,
            title: 'Edit Profile',
            subtitle: 'Update your personal information',
            onTap: () => context.push('/patient/profile/edit'),
          ),
          _SettingsTile(
            icon: Icons.favorite_border,
            iconBg: const Color(0xFF4CAF50).withAlpha(25),
            iconColor: const Color(0xFF4CAF50),
            title: 'AI Health Assistant',
            subtitle: 'Get personalised health insights',
            onTap: () => context.pushNamed(RouteNames.aiChat),
          ),
          _SettingsTile(
            icon: Icons.search,
            iconBg: const Color(0xFF2196F3).withAlpha(25),
            iconColor: const Color(0xFF2196F3),
            title: 'Symptom Checker',
            subtitle: 'Check your symptoms with AI',
            onTap: () => context.pushNamed(RouteNames.symptomChecker),
          ),
          _SettingsTile(
            icon: Icons.location_on_outlined,
            iconBg: const Color(0xFFFF9800).withAlpha(25),
            iconColor: const Color(0xFFFF9800),
            title: 'Nearby Clinics',
            subtitle: 'Find clinics near you',
            onTap: () => context.push('/nearby-clinics'),
          ),

          const SizedBox(height: 8),

          // ─── Account ───
          _SectionHeader('ACCOUNT'),
          _SettingsTile(
            icon: Icons.notifications_outlined,
            iconBg: AppColors.warning.withAlpha(25),
            iconColor: AppColors.warning,
            title: 'Notifications',
            subtitle: 'Manage your alerts',
            onTap: () => context.push('/notifications'),
          ),
          _SettingsTile(
            icon: Icons.credit_card_outlined,
            iconBg: AppColors.secondary.withAlpha(25),
            iconColor: AppColors.secondary,
            title: 'Payment Methods',
            subtitle: 'Choose your default method',
            onTap: () => context.push('/patient/payments/methods'),
          ),
          _SettingsTile(
            icon: Icons.receipt_long_outlined,
            iconBg: const Color(0xFF9C27B0).withAlpha(25),
            iconColor: const Color(0xFF9C27B0),
            title: 'Transaction History',
            subtitle: 'View past payments',
            onTap: () => context.push('/patient/payments/history'),
          ),
          _SettingsTile(
            icon: Icons.settings_outlined,
            iconBg: AppColors.primary.withAlpha(25),
            iconColor: AppColors.primary,
            title: 'App Settings',
            subtitle: 'Theme, language & more',
            onTap: () => context.push('/settings'),
          ),

          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              icon: const Icon(Icons.logout, color: AppColors.error),
              label: const Text(
                'Logout',
                style: TextStyle(color: AppColors.error),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => _confirmLogout(context),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await sl<AuthCubit>().logout();
              if (context.mounted) context.go('/login');
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        title,
        style: AppTextStyles.labelSm.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withAlpha(140),
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline.withAlpha(30)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          title,
          style: AppTextStyles.bodyMd.copyWith(color: cs.onSurface),
        ),
        subtitle: Text(
          subtitle,
          style: AppTextStyles.bodySm.copyWith(
            color: cs.onSurface.withAlpha(160),
          ),
        ),
        trailing: Icon(Icons.chevron_right, color: cs.onSurface.withAlpha(120)),
        onTap: onTap,
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatItem({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(
        children: [
          Text(value, style: AppTextStyles.heading3.copyWith(color: color)),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.bodySm.copyWith(
              color: cs.onSurface.withAlpha(160),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      color: Theme.of(context).dividerColor,
    );
  }
}
