import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../cubits/patient_profile_cubit.dart';
import '../cubits/patient_profile_state.dart';

class PatientProfileScreen extends StatelessWidget {
  const PatientProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
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
          if (state is PatientProfileLoading || state is PatientProfileInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is PatientProfileError) {
            return ErrorView(
              message: state.message,
              onRetry: () =>
                  context.read<PatientProfileCubit>().loadProfile(),
            );
          }

          final profile = switch (state) {
            PatientProfileLoaded(:final profile) => profile,
            PatientProfileUpdating(:final profile) => profile,
            PatientProfileUpdateSuccess(:final profile) => profile,
            _ => null,
          };

          if (profile == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            children: [
              // ─── Avatar Section ───
              Container(
                padding: const EdgeInsets.symmetric(vertical: 32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.gradientStart,
                      AppColors.gradientEnd,
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: Colors.white.withAlpha(40),
                      backgroundImage: profile.profileImageUrl != null
                          ? NetworkImage(profile.profileImageUrl!)
                          : null,
                      child: profile.profileImageUrl == null
                          ? const Icon(Icons.person,
                              color: Colors.white, size: 48)
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      profile.fullName,
                      style: AppTextStyles.heading2
                          .copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile.email,
                      style: AppTextStyles.bodyMd
                          .copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(30),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        profile.role,
                        style: AppTextStyles.labelSm
                            .copyWith(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // ─── Actions ───
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit Profile'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/patient/profile/edit'),
              ),
              const Divider(height: 1, indent: 16),
              ListTile(
                leading: const Icon(Icons.notifications_outlined),
                title: const Text('Notifications'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/notifications'),
              ),
              const Divider(height: 1, indent: 16),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('Settings'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/settings'),
              ),
              const Divider(height: 1),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.error),
                title: Text(
                  'Log Out',
                  style: TextStyle(color: AppColors.error),
                ),
                onTap: () => _confirmLogout(context),
              ),
            ],
          );
        },
      ),
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
            child: Text(
              'Log Out',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
