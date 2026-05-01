import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../domain/entities/doctor_search_entities.dart';

class DoctorListTile extends StatelessWidget {
  final DoctorSearchResult doctor;
  final VoidCallback? onTap;

  const DoctorListTile({super.key, required this.doctor, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            UserAvatar(
              radius: 28,
              imageUrl: doctor.profileImageUrl,
              fullName: doctor.fullName,
              backgroundColor: AppColors.primary.withAlpha(20),
              textStyle: AppTextStyles.heading3.copyWith(color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dr. ${doctor.fullName}',
                    style: AppTextStyles.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    doctor.specialty,
                    style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star, color: AppColors.starRating, size: 14),
                      const SizedBox(width: 3),
                      Text(
                        '${doctor.avgRating.toStringAsFixed(1)} (${doctor.reviewsCount})',
                        style: AppTextStyles.caption,
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.work_outline, size: 14, color: AppColors.textHint),
                      const SizedBox(width: 3),
                      Text(
                        '${doctor.experienceYears} yrs',
                        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                      ),
                      if (doctor.distanceKm != null) ...[
                        const SizedBox(width: 12),
                        Icon(Icons.location_on, size: 14, color: AppColors.textHint),
                        const SizedBox(width: 3),
                        Text(
                          '${doctor.distanceKm!.toStringAsFixed(1)} km',
                          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Fee
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${doctor.consultationFee.toStringAsFixed(0)}',
                  style: AppTextStyles.heading3.copyWith(color: AppColors.primary),
                ),
                Text(
                  'per visit',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
