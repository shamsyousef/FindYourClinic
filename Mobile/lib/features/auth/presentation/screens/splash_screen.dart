import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/token_storage.dart';
import '../../domain/usecases/auth_usecases.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _scale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
    _navigateAfterDelay();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    // 1. Check first-launch onboarding
    final prefs = await SharedPreferences.getInstance();
    final seenOnboarding = prefs.getBool('onboarding_seen') ?? false;
    if (!mounted) return;

    if (!seenOnboarding) {
      context.goNamed(RouteNames.onboarding);
      return;
    }

    // 2. Check stored token
    final tokenStorage = sl<TokenStorage>();
    final hasTokens = await tokenStorage.hasTokens();
    if (!mounted) return;

    if (!hasTokens) {
      context.goNamed(RouteNames.login);
      return;
    }

    // 3. Route by role
    final role = await tokenStorage.getUserRole();
    if (!mounted) return;

    if (role == 'Doctor') {
      // Check doctor approval status before routing
      final statusUseCase = sl<GetDoctorStatusUseCase>();
      final result = await statusUseCase();
      if (!mounted) return;

      switch (result) {
        case Success(:final data):
          if (data.isApproved) {
            context.goNamed(RouteNames.doctorHome);
          } else if (data.isRejected) {
            context.goNamed(
              RouteNames.doctorRejected,
              extra: data.rejectionReason,
            );
          } else {
            // PendingReview or unknown
            context.goNamed(RouteNames.doctorPending);
          }
        case Error():
          // On error (e.g. no profile yet), go to pending
          context.goNamed(RouteNames.doctorPending);
      }
    } else {
      context.goNamed(RouteNames.patientHome);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppTheme.headerGradient),
        child: FadeTransition(
          opacity: _fadeIn,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/icons/app_logo.png', height: 96),
                const SizedBox(height: 24),
                Text(
                  'Find Your Clinic',
                  style: AppTextStyles.heading1.copyWith(
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Healthcare at your fingertips',
                  style: AppTextStyles.bodyMd.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 48),
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
