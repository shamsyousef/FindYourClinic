import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../cubits/doctor_shell_profile_cubit.dart';
import '../cubits/doctor_shell_profile_state.dart';

class DoctorShellProfileScreen extends StatelessWidget {
  const DoctorShellProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
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
    return ListView(
      children: [
        // ─── Header ───
        Container(
          padding: const EdgeInsets.symmetric(vertical: 32),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.gradientStart, AppColors.gradientEnd],
            ),
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: Colors.white24,
                backgroundImage: state.profileImageUrl != null
                    ? NetworkImage(state.profileImageUrl!)
                    : null,
                child: state.profileImageUrl == null
                    ? const Icon(Icons.person, color: Colors.white, size: 48)
                    : null,
              ),
              const SizedBox(height: 12),
              Text(
                state.fullName,
                style:
                    AppTextStyles.heading2.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.verified,
                      size: 16, color: AppColors.success),
                  const SizedBox(width: 4),
                  Text(
                    'Verified Doctor',
                    style: AppTextStyles.bodySm
                        .copyWith(color: AppColors.success),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // ─── Stats row ───
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _StatColumn(
                      label: 'Rating',
                      value: state.avgRating.toStringAsFixed(1),
                      icon: Icons.star,
                    ),
                    Container(
                        width: 1, height: 40, color: Colors.white30),
                    _StatColumn(
                      label: 'Patients',
                      value: state.totalPatients.toString(),
                      icon: Icons.people,
                    ),
                    Container(
                        width: 1, height: 40, color: Colors.white30),
                    _StatColumn(
                      label: 'Reviews',
                      value: state.totalReviews.toString(),
                      icon: Icons.reviews_outlined,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // ─── Menu items ───
        ListTile(
          leading: const Icon(Icons.edit_outlined),
          title: const Text('Edit Profile'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/doctor/profile/edit'),
        ),
        const Divider(height: 1, indent: 16),
        ListTile(
          leading: const Icon(Icons.schedule_outlined),
          title: const Text('Manage Availability'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/doctor/home/availability'),
        ),
        const Divider(height: 1, indent: 16),
        ListTile(
          leading: const Icon(Icons.bar_chart_outlined),
          title: const Text('Insights'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.go('/doctor/insights'),
        ),
        const Divider(height: 1),
        const SizedBox(height: 8),
        ListTile(
          leading: const Icon(Icons.logout, color: AppColors.error),
          title: const Text(
            'Log Out',
            style: TextStyle(color: AppColors.error),
          ),
          onTap: () => _confirmLogout(context),
        ),
      ],
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
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
              'Log Out',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatColumn({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.heading3.copyWith(color: Colors.white),
        ),
        Text(
          label,
          style: AppTextStyles.labelSm.copyWith(color: Colors.white70),
        ),
      ],
    );
  }
}
