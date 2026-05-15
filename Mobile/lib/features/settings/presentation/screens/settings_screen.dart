import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_mode_cubit.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/utils/token_storage.dart';
import '../../../accessibility/presentation/cubits/voice_assistant_visibility_cubit.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart' as import_auth;
import '../../../auth/presentation/cubits/auth_state.dart' as import_auth;

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: sl<ThemeModeCubit>(),
      child: const _SettingsBody(),
    );
  }
}

class _SettingsBody extends StatelessWidget {
  const _SettingsBody();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: BlocBuilder<ThemeModeCubit, ThemeMode>(
        builder: (context, themeMode) {
          final isDark = themeMode == ThemeMode.dark ||
              (themeMode == ThemeMode.system &&
                  MediaQuery.platformBrightnessOf(context) ==
                      Brightness.dark);
          return ListView(
            children: [
              // ACCESSIBILITY section is patient-only — the voice assistant is
              // a blind-patient feature.
              FutureBuilder<String?>(
                future: sl<TokenStorage>().getUserRole(),
                builder: (ctx, snap) {
                  if (snap.data != 'Patient') return const SizedBox.shrink();
                  return Column(
                    children: [
                      _SectionHeader('ACCESSIBILITY'),
                      BlocBuilder<VoiceAssistantVisibilityCubit, bool>(
                        bloc: sl<VoiceAssistantVisibilityCubit>(),
                        builder: (_, enabled) => SwitchListTile(
                          secondary:
                              const Icon(Icons.record_voice_over_outlined),
                          title: const Text('Voice Assistant Card'),
                          subtitle: const Text(
                            'Show the voice assistant card on the home screen',
                          ),
                          value: enabled,
                          onChanged: (v) =>
                              sl<VoiceAssistantVisibilityCubit>().setEnabled(v),
                        ),
                      ),
                      const Divider(height: 1),
                    ],
                  );
                },
              ),
              _SectionHeader('APPEARANCE'),
              SwitchListTile(
                secondary: Icon(
                    isDark ? Icons.dark_mode : Icons.light_mode_outlined),
                title: const Text('Dark Mode'),
                value: isDark,
                onChanged: (_) =>
                    context.read<ThemeModeCubit>().toggle(),
              ),
              const Divider(height: 1),
              _SectionHeader('ACCOUNT'),
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('Change Password'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.pushNamed('changePassword'),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Delete Account', style: TextStyle(color: Colors.red)),
                onTap: () => _showDeleteAccountDialog(context),
              ),
              const Divider(height: 1),
              _SectionHeader('SUPPORT'),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('Help & Support'),
                subtitle: const Text('FAQs, contact us, legal'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.pushNamed('helpSupport'),
              ),
              const Divider(height: 1),
              _SectionHeader('ABOUT'),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('App Version'),
                trailing: Text(
                  '1.0.0',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface
                            .withAlpha(120),
                      ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final passwordController = TextEditingController();
    final authCubit = sl<import_auth.AuthCubit>(); // we will use alias to avoid collision
    
    showDialog(
      context: context,
      builder: (ctx) => BlocProvider.value(
        value: authCubit,
        child: BlocConsumer<import_auth.AuthCubit, import_auth.AuthState>(
          listener: (context, state) {
            if (state is import_auth.AuthAccountDeletionRequested) {
              Navigator.of(context).pop(); // close dialog
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account deletion requested successfully. Your account will be permanently deleted in 30 days.'),
                  backgroundColor: Colors.green,
                ),
              );
              // Log out the user since their account is now inactive
              authCubit.logout();
            } else if (state is import_auth.AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            final isLoading = state is import_auth.AuthLoading;
            return AlertDialog(
              title: const Text('Delete Account'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Are you sure you want to delete your account? This action will schedule your account for permanent deletion after 30 days.'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Enter your password to confirm',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: isLoading
                      ? null
                      : () {
                          if (passwordController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter your password'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          context.read<import_auth.AuthCubit>().requestAccountDeletion(
                                password: passwordController.text,
                              );
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Delete'),
                ),
              ],
            );
          },
        ),
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
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withAlpha(140),
              letterSpacing: 1.2,
            ),
      ),
    );
  }
}
