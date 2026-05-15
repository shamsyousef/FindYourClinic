import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../cubits/auth_cubit.dart';
import '../cubits/auth_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthCubit, AuthState>(
        listener: _handleAuthState,
        child: SingleChildScrollView(
          child: Column(children: [_buildHeader(), _buildForm()]),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 72, 24, 32),
      decoration: const BoxDecoration(
        gradient: AppTheme.headerGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          Image.asset('assets/icons/app_logo.png', height: 56),
          const SizedBox(height: 16),
          Text(
            'Welcome Back!',
            style: AppTextStyles.heading1.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            'Sign in to continue',
            style: AppTextStyles.bodyMd.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              'Login to Your Account',
              style: AppTextStyles.heading3.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),

            // Email
            AppTextField(
              label: 'Email Address',
              hint: 'your.email@example.com',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: const Icon(Icons.email_outlined, size: 20),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Email is required';
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) {
                  return 'Enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Password
            AppTextField(
              label: 'Password',
              hint: 'Enter your password',
              controller: _passwordController,
              obscureText: _obscurePassword,
              prefixIcon: const Icon(Icons.lock_outlined, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password is required';
                if (v.length < 8) {
                  return 'Password must be at least 8 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),

            // Forgot Password
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.pushNamed(RouteNames.forgotPassword),
                child: const Text('Forgot Password?'),
              ),
            ),
            const SizedBox(height: 16),

            // Login Button
            BlocBuilder<AuthCubit, AuthState>(
              buildWhen: (prev, curr) =>
                  curr is AuthLoading ||
                  curr is AuthError ||
                  curr is AuthSuccess,
              builder: (context, state) {
                return AppButton(
                  text: 'Login',
                  isLoading: state is AuthLoading,
                  onPressed: _onLogin,
                );
              },
            ),
            const SizedBox(height: 24),

            // Divider
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Or continue with',
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 16),

            // Social Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _onGoogleSignIn,
                    icon: const Icon(Icons.g_mobiledata, size: 24),
                    label: const Text('Google'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Sign Up Link
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Don't have an account? ",
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                GestureDetector(
                  onTap: () => context.pushNamed(RouteNames.signUp),
                  child: Text(
                    'Sign Up',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _onLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthCubit>().login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    }
  }

  Future<void> _onGoogleSignIn() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;
      final auth = await googleUser.authentication;
      final idToken = auth.idToken;
      if (idToken == null) return;
      if (!mounted) { return; }
      context.read<AuthCubit>().googleLogin(idToken: idToken);
    } catch (_) {
      // Google sign-in cancelled or failed.
    }
  }

  void _handleAuthState(BuildContext context, AuthState state) {
    switch (state) {
      case AuthSuccess(:final result):
        if (result.user.isDoctor) {
          context.read<AuthCubit>().getDoctorStatus();
        } else {
          context.goNamed(RouteNames.patientHome);
        }
      case AuthDoctorStatusLoaded(:final result):
        if (result.isApproved) {
          context.goNamed(RouteNames.doctorHome);
        } else if (result.isRejected) {
          context.goNamed(
            RouteNames.doctorRejected,
            extra: result.rejectionReason,
          );
        } else {
          context.goNamed(RouteNames.doctorPending);
        }
      case AuthGoogleResult(:final result):
        if (result.authResult != null) {
          if (result.authResult!.user.isDoctor) {
            context.read<AuthCubit>().getDoctorStatus();
          } else {
            context.goNamed(RouteNames.patientHome);
          }
        }
      case AuthError(:final message):
        final lowerMessage = message.toLowerCase();
        if (lowerMessage.contains('rejected')) {
          String? reason;
          if (message.contains('Reason:')) {
            reason = message.split(RegExp(r'Reason:\s*', caseSensitive: false)).last;
          }
          context.goNamed(RouteNames.doctorRejected, extra: reason);
        } else if (lowerMessage.contains('under review') || lowerMessage.contains('pending')) {
          context.goNamed(RouteNames.doctorPending);
        } else {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
        }

      default:
        break;
    }
  }
}
