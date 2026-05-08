import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/payment_entities.dart';
import '../helpers/payment_display.dart';

class ReceiptDetailScreen extends StatelessWidget {
  final TransactionEntity transaction;
  final bool isPatient;

  const ReceiptDetailScreen({
    super.key,
    required this.transaction,
    this.isPatient = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = paymentStatusDisplay(transaction.status);
    final method = paymentMethodDisplay(transaction.paymentMethod);
    final counterparty = isPatient
        ? 'Dr. ${transaction.doctorName ?? '—'}'
        : (transaction.patientName ?? '—');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HeroCard(
              status: status,
              amount:
                  '${(isPatient ? transaction.amount : transaction.doctorEarnings).toStringAsFixed(2)} EGP',
              counterparty: counterparty,
            ),
            const SizedBox(height: 20),
            _DetailsCard(isDark: isDark, children: [
              _Row(
                  label: 'Status',
                  child: Text(
                    status.label,
                    style: TextStyle(
                      color: status.color,
                      fontWeight: FontWeight.w700,
                    ),
                  )),
              _Row(
                  label: 'Method',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(method.icon, size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(method.label,
                          style:
                              const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  )),
              _Row(
                  label: 'Date',
                  value: DateFormat('MMM dd, yyyy · hh:mm a')
                      .format(transaction.createdAt)),
              if (transaction.completedAt != null)
                _Row(
                    label: 'Completed',
                    value: DateFormat('MMM dd, yyyy · hh:mm a')
                        .format(transaction.completedAt!)),
            ]),
            const SizedBox(height: 16),
            _DetailsCard(
              isDark: isDark,
              title: 'Breakdown',
              children: [
                _Row(
                    label: 'Consultation Fee',
                    value: '${transaction.amount.toStringAsFixed(2)} EGP'),
                _Row(
                    label: 'Platform Fee',
                    value: '-${transaction.platformFee.toStringAsFixed(2)} EGP'),
                const Divider(height: 24),
                _Row(
                  label: isPatient ? 'You Paid' : 'You Earned',
                  child: Text(
                    '${(isPatient ? transaction.amount : transaction.doctorEarnings).toStringAsFixed(2)} EGP',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _DetailsCard(
              isDark: isDark,
              title: 'Reference',
              children: [
                _CopyRow(label: 'Transaction ID', value: transaction.id),
                _CopyRow(
                    label: 'Appointment ID', value: transaction.appointmentId),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final ({String label, Color color}) status;
  final String amount;
  final String counterparty;

  const _HeroCard({
    required this.status,
    required this.amount,
    required this.counterparty,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.gradientStart, AppColors.gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status.label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            counterparty,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 30,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  final bool isDark;
  final String? title;
  final List<Widget> children;

  const _DetailsCard({
    required this.isDark,
    this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white10 : AppColors.divider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 12),
          ],
          ...children,
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? child;

  const _Row({
    required this.label,
    this.value,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: child ??
                Text(
                  value ?? '',
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
          ),
        ],
      ),
    );
  }
}

class _CopyRow extends StatelessWidget {
  final String label;
  final String value;

  const _CopyRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return _Row(
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () async {
          await Clipboard.setData(ClipboardData(text: value));
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$label copied'),
              duration: const Duration(seconds: 1),
            ),
          );
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.copy_rounded,
                size: 14, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
