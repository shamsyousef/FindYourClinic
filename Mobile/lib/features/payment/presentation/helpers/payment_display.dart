import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Maps a backend PaymentStatus enum string to a (label, color) pair for UI.
({String label, Color color}) paymentStatusDisplay(String raw) {
  switch (raw.toLowerCase()) {
    case 'paid':
      return (label: 'Paid', color: AppColors.success);
    case 'pending':
      return (label: 'Pending', color: AppColors.warning);
    case 'unpaid':
      return (label: 'Unpaid', color: AppColors.warning);
    case 'failed':
      return (label: 'Failed', color: AppColors.error);
    case 'refunded':
      return (label: 'Refunded', color: AppColors.info);
    default:
      return (label: raw, color: AppColors.textSecondary);
  }
}

/// Maps a backend PaymentMethod enum string to (label, icon).
({String label, IconData icon}) paymentMethodDisplay(String raw) {
  switch (raw.toLowerCase()) {
    case 'cash':
      return (label: 'Cash', icon: Icons.money_rounded);
    case 'card':
      return (label: 'Card', icon: Icons.credit_card_rounded);
    case 'wallet':
      return (label: 'Wallet', icon: Icons.phone_android_rounded);
    default:
      return (label: raw, icon: Icons.payment_rounded);
  }
}
