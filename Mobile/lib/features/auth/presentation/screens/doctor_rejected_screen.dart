import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';
import '../cubits/auth_cubit.dart';

class DoctorRejectedScreen extends StatelessWidget {
  final String? rejectionReason;

  const DoctorRejectedScreen({super.key, this.rejectionReason});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),

              // Red X illustration
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.error.withAlpha(15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: AppColors.error.withAlpha(25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.cancel_rounded,
                      size: 56,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'Application Rejected',
                style: AppTextStyles.heading2.copyWith(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Action Required badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.error.withAlpha(20),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.error.withAlpha(80)),
                ),
                child: Text(
                  'Action Required',
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Rejection Reason card
              if (rejectionReason != null && rejectionReason!.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: isDark ? AppColors.darkSurfaceAlt : Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(10),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rejection Reason:',
                        style: AppTextStyles.label.copyWith(
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        rejectionReason!,
                        style: AppTextStyles.bodyMd.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
              ],

              // What to do next
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: isDark ? AppColors.darkSurfaceAlt : Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(10),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What to do next:',
                      style: AppTextStyles.label.copyWith(
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._steps.asMap().entries.map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withAlpha(20),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${e.key + 1}',
                                      style: AppTextStyles.labelSm.copyWith(
                                        color: isDark ? AppColors.primaryLight : AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    e.value,
                                    style: AppTextStyles.bodyMd.copyWith(
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Re-upload Documents CTA
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: 'Re-upload Documents',
                  icon: Icons.upload_file_rounded,
                  onPressed: () => context.goNamed(
                    RouteNames.doctorDocuments,
                    queryParameters: const {'resubmit': 'true'},
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Contact Support
              TextButton(
                onPressed: () => context.pushNamed(RouteNames.helpSupport),
                child: Text(
                  'Contact Support',
                  style: AppTextStyles.bodyMd.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Back to Login
              TextButton(
                onPressed: () async {
                  await sl<AuthCubit>().logout();
                  if (context.mounted) context.goNamed(RouteNames.login);
                },
                child: Text(
                  'Back to Login',
                  style: AppTextStyles.bodyMd.copyWith(color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const _steps = [
    'Review the rejection reason above',
    'Prepare updated, valid documents',
    'Re-upload and resubmit for review',
  ];
}
