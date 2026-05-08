import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/preferred_payment_method_store.dart';
import '../../domain/entities/payment_entities.dart';
import '../cubits/checkout_cubit.dart';
import '../cubits/checkout_state.dart';
import 'paymob_webview_screen.dart';

class CheckoutScreen extends StatelessWidget {
  final String doctorProfileId;
  final String doctorName;
  final String? doctorImageUrl;
  final String? specialty;
  final double consultationFee;
  final DateTime scheduledAt;
  final String? locationName;

  const CheckoutScreen({
    super.key,
    required this.doctorProfileId,
    required this.doctorName,
    this.doctorImageUrl,
    this.specialty,
    required this.consultationFee,
    required this.scheduledAt,
    this.locationName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CheckoutCubit>(),
      child: _CheckoutView(
        doctorProfileId: doctorProfileId,
        doctorName: doctorName,
        doctorImageUrl: doctorImageUrl,
        specialty: specialty,
        consultationFee: consultationFee,
        scheduledAt: scheduledAt,
        locationName: locationName,
      ),
    );
  }
}

class _CheckoutView extends StatefulWidget {
  final String doctorProfileId;
  final String doctorName;
  final String? doctorImageUrl;
  final String? specialty;
  final double consultationFee;
  final DateTime scheduledAt;
  final String? locationName;

  const _CheckoutView({
    required this.doctorProfileId,
    required this.doctorName,
    this.doctorImageUrl,
    this.specialty,
    required this.consultationFee,
    required this.scheduledAt,
    this.locationName,
  });

  @override
  State<_CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<_CheckoutView> {
  PaymentMethod _selectedMethod = PaymentMethod.cash;
  final _walletPhoneCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPreferredMethod();
  }

  @override
  void dispose() {
    _walletPhoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPreferredMethod() async {
    final preferred = await sl<PreferredPaymentMethodStore>().read();
    if (!mounted) return;
    setState(() => _selectedMethod = preferred);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        centerTitle: true,
      ),
      body: BlocConsumer<CheckoutCubit, CheckoutState>(
        listener: (context, state) {
          switch (state) {
            case CheckoutCashSuccess():
              GoRouter.of(context).go('/booking-success', extra: {
                'isConfirmed': false,
                'doctorName': widget.doctorName,
                'scheduledAt': widget.scheduledAt,
                'appointmentId': null,
              });
            case CheckoutPaymentReady():
              _openPaymobWebView(context, state.intent);
            case CheckoutError():
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                ),
              );
            default:
              break;
          }
        },
        builder: (context, state) {
          final isLoading = state is CheckoutLoading;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Doctor Card ───
                _DoctorCard(
                  name: widget.doctorName,
                  imageUrl: widget.doctorImageUrl,
                  specialty: widget.specialty,
                ),
                const SizedBox(height: 20),

                // ─── Appointment Details ───
                _SectionCard(
                  title: 'Appointment Details',
                  isDark: isDark,
                  children: [
                    _DetailRow(
                      icon: Icons.calendar_today_rounded,
                      label: 'Date',
                      value: DateFormat('EEEE, MMM dd, yyyy').format(widget.scheduledAt),
                    ),
                    _DetailRow(
                      icon: Icons.access_time_rounded,
                      label: 'Time',
                      value: DateFormat('hh:mm a').format(widget.scheduledAt),
                    ),
                    if (widget.locationName != null)
                      _DetailRow(
                        icon: Icons.location_on_rounded,
                        label: 'Location',
                        value: widget.locationName!,
                      ),
                  ],
                ),
                const SizedBox(height: 20),

                // ─── Fee Breakdown ───
                _SectionCard(
                  title: 'Payment Summary',
                  isDark: isDark,
                  children: [
                    _FeeRow(label: 'Consultation Fee', amount: widget.consultationFee),
                    const Divider(height: 24),
                    _FeeRow(
                      label: 'Total',
                      amount: widget.consultationFee,
                      isBold: true,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ─── Payment Method ───
                Text(
                  'Payment Method',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                _PaymentMethodTile(
                  icon: Icons.money_rounded,
                  label: 'Pay at Clinic (Cash)',
                  subtitle: 'Doctor must approve before confirmation',
                  isSelected: _selectedMethod == PaymentMethod.cash,
                  onTap: () => setState(() => _selectedMethod = PaymentMethod.cash),
                ),
                const SizedBox(height: 8),
                _PaymentMethodTile(
                  icon: Icons.phone_android_rounded,
                  label: 'Mobile Wallet',
                  subtitle: 'Instant confirmation via Paymob',
                  isSelected: _selectedMethod == PaymentMethod.wallet,
                  onTap: () => setState(() => _selectedMethod = PaymentMethod.wallet),
                ),
                if (_selectedMethod == PaymentMethod.wallet) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _walletPhoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: 'Wallet phone number (e.g. 01xxxxxxxxx)',
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      prefixIcon: const Icon(Icons.phone_rounded),
                    ),
                  ),
                ],
                const SizedBox(height: 32),

                // ─── Pay Button ───
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : () => _onPay(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            _selectedMethod == PaymentMethod.cash
                                ? 'Book Appointment'
                                : 'Pay ${widget.consultationFee.toStringAsFixed(0)} EGP',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // ─── Disclaimer ───
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (isDark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.security_rounded,
                          size: 18, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your payment is secured by Paymob. We never store your card details.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _onPay(BuildContext context) {
    if (_selectedMethod == PaymentMethod.wallet &&
        _walletPhoneCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your wallet phone number.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    context.read<CheckoutCubit>().initiate(
          doctorProfileId: widget.doctorProfileId,
          scheduledAt: widget.scheduledAt,
          locationName: widget.locationName,
          paymentMethod: _selectedMethod,
          walletPhone: _selectedMethod == PaymentMethod.wallet
              ? _walletPhoneCtrl.text.trim()
              : null,
        );
  }

  void _openPaymobWebView(BuildContext context, PaymentIntentEntity intent) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => PaymobWebViewScreen(
          intent: intent,
          doctorProfileId: widget.doctorProfileId,
          scheduledAt: widget.scheduledAt,
          locationName: widget.locationName,
          paymentMethod: _selectedMethod,
        ),
      ),
    );
  }

}

// ─── Sub-Widgets ───

class _DoctorCard extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final String? specialty;

  const _DoctorCard({required this.name, this.imageUrl, this.specialty});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.gradientStart, AppColors.gradientEnd],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
            backgroundColor: Colors.white24,
            child: imageUrl == null
                ? const Icon(Icons.person, color: Colors.white, size: 28)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dr. $name',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (specialty != null)
                  Text(
                    specialty!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final bool isDark;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.isDark,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeeRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool isBold;

  const _FeeRow({required this.label, required this.amount, this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
            color: isBold ? null : AppColors.textSecondary,
          ),
        ),
        Text(
          '${amount.toStringAsFixed(2)} EGP',
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: isBold ? AppColors.primary : null,
          ),
        ),
      ],
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentMethodTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : (isDark ? AppColors.darkSurface : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppColors.primary : null,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.primary, size: 22),
          ],
        ),
      ),
    );
  }
}
