import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../cubits/doctor_shell_profile_cubit.dart';
import '../cubits/doctor_shell_profile_state.dart';

class DoctorShellProfileScreen extends StatelessWidget {
  const DoctorShellProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<DoctorShellProfileCubit, DoctorShellProfileState>(
        listener: (context, state) {
          if (state is DoctorShellProfileError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is DoctorShellProfileLoading ||
              state is DoctorShellProfileInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is DoctorShellProfileError) {
            return ErrorView(
              message: state.message,
              onRetry: () =>
                  context.read<DoctorShellProfileCubit>().loadProfile(),
            );
          }
          if (state is! DoctorShellProfileLoaded) {
            return const SizedBox.shrink();
          }
          return _ProfileBody(state: state);
        },
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  final DoctorShellProfileLoaded state;
  const _ProfileBody({required this.state});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: () => context.read<DoctorShellProfileCubit>().loadProfile(),
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
                    UserAvatar(
                      radius: 32,
                      imageUrl: state.profileImageUrl,
                      fullName: state.fullName,
                      backgroundColor: AppColors.primary,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            state.fullName,
                            style: AppTextStyles.heading3.copyWith(
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${state.specialty} Specialist',
                            style: AppTextStyles.bodySm.copyWith(
                              color: cs.onSurface.withAlpha(160),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: AppColors.starRating,
                                size: 14,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${state.avgRating.toStringAsFixed(1)} (${state.reviewsCount} reviews)',
                                style: AppTextStyles.bodySm.copyWith(
                                  color: cs.onSurface.withAlpha(160),
                                ),
                              ),
                            ],
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
                      value: state.totalPatients.toString(),
                      label: 'Patients',
                      color: AppColors.primary,
                    ),
                    _StatDivider(),
                    _StatItem(
                      value: '${state.experienceYears}',
                      label: 'Years Exp.',
                      color: AppColors.secondary,
                    ),
                    _StatDivider(),
                    _StatItem(
                      value: '${state.consultationFee.toStringAsFixed(0)} EGP',
                      label: 'Fee',
                      color: AppColors.success,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ─── Profile Settings ───
          _SectionHeader('PROFILE SETTINGS'),
          _SettingsTile(
            icon: Icons.person_outline,
            iconBg: AppColors.primary.withAlpha(25),
            iconColor: AppColors.primary,
            title: 'Edit Profile',
            subtitle: 'Update personal & professional info',
            onTap: () => context.push('/doctor/profile/edit'),
          ),
          _SettingsTile(
            icon: Icons.calendar_month_outlined,
            iconBg: AppColors.secondary.withAlpha(25),
            iconColor: AppColors.secondary,
            title: 'Manage Schedule',
            subtitle: 'Set availability & working hours',
            onTap: () => context.push('/doctor/home/availability'),
          ),
          _SettingsTile(
            icon: Icons.location_on_outlined,
            iconBg: const Color(0xFFFF9800).withAlpha(25),
            iconColor: const Color(0xFFFF9800),
            title: 'My Clinics',
            subtitle: 'Add or edit clinic locations',
            onTap: () => context.push('/doctor/profile/edit'),
          ),
          _SettingsTile(
            icon: Icons.description_outlined,
            iconBg: AppColors.info.withAlpha(25),
            iconColor: AppColors.info,
            title: 'Documents',
            subtitle: 'View & update certificates',
            onTap: () => context.push('/doctor/profile/documents'),
          ),

          const SizedBox(height: 8),

          // ─── Account Settings ───
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
            icon: Icons.account_balance_wallet_outlined,
            iconBg: AppColors.success.withAlpha(25),
            iconColor: AppColors.success,
            title: 'Earnings',
            subtitle: 'View your wallet & balance',
            onTap: () => context.push('/doctor/earnings'),
          ),
          _SettingsTile(
            icon: Icons.receipt_long_outlined,
            iconBg: const Color(0xFF9C27B0).withAlpha(25),
            iconColor: const Color(0xFF9C27B0),
            title: 'Transaction History',
            subtitle: 'View past transactions',
            onTap: () => context.push('/doctor/payments/history'),
          ),
          _SettingsTile(
            icon: Icons.language_outlined,
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
                'Sign Out',
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
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
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
              'Sign Out',
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
