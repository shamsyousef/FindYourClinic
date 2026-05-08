import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/doctor_payment_info_entity.dart';
import '../cubits/doctor_payment_info_cubit.dart';
import '../cubits/doctor_payment_info_state.dart';

class DoctorPaymentInfoScreen extends StatelessWidget {
  const DoctorPaymentInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<DoctorPaymentInfoCubit>()..load(),
      child: const _Body(),
    );
  }
}

class _Body extends StatefulWidget {
  const _Body();

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  PayoutMethodType _method = PayoutMethodType.wallet;
  WalletProviderType _walletProvider = WalletProviderType.vodafoneCash;

  final _walletPhoneCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();
  final _accountHolderCtrl = TextEditingController();
  final _accountNumberCtrl = TextEditingController();
  final _ibanCtrl = TextEditingController();

  bool _prefilled = false;

  @override
  void dispose() {
    _walletPhoneCtrl.dispose();
    _bankNameCtrl.dispose();
    _accountHolderCtrl.dispose();
    _accountNumberCtrl.dispose();
    _ibanCtrl.dispose();
    super.dispose();
  }

  void _prefill(DoctorPaymentInfoEntity? info) {
    if (_prefilled || info == null) return;
    _prefilled = true;
    _method = info.payoutMethod;
    _walletProvider = info.walletProvider ?? WalletProviderType.vodafoneCash;
    _walletPhoneCtrl.text = info.walletPhoneNumber ?? '';
    _bankNameCtrl.text = info.bankName ?? '';
    _accountHolderCtrl.text = info.accountHolderName ?? '';
    _accountNumberCtrl.text = info.accountNumber ?? '';
    _ibanCtrl.text = info.iban ?? '';
  }

  void _save(BuildContext context) {
    final info = DoctorPaymentInfoEntity(
      payoutMethod: _method,
      walletProvider: _method == PayoutMethodType.wallet ? _walletProvider : null,
      walletPhoneNumber:
          _method == PayoutMethodType.wallet ? _walletPhoneCtrl.text.trim() : null,
      bankName: _method == PayoutMethodType.bank ? _bankNameCtrl.text.trim() : null,
      accountHolderName:
          _method == PayoutMethodType.bank ? _accountHolderCtrl.text.trim() : null,
      accountNumber:
          _method == PayoutMethodType.bank ? _accountNumberCtrl.text.trim() : null,
      iban: _method == PayoutMethodType.bank ? _ibanCtrl.text.trim() : null,
    );
    context.read<DoctorPaymentInfoCubit>().save(info);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payout Details'),
        centerTitle: true,
      ),
      body: BlocConsumer<DoctorPaymentInfoCubit, DoctorPaymentInfoState>(
        listener: (context, state) {
          if (state is DoctorPaymentInfoLoaded) {
            setState(() => _prefill(state.info));
          }
          if (state is DoctorPaymentInfoSaved) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Payout details saved successfully.'),
                backgroundColor: AppColors.success,
              ),
            );
          }
          if (state is DoctorPaymentInfoError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          final isSaving = state is DoctorPaymentInfoSaving;
          final isLoading = state is DoctorPaymentInfoLoading;

          if (isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Info banner ───
                _InfoBanner(isDark: isDark),
                const SizedBox(height: 20),

                // ─── Method selector ───
                Text(
                  'Payout Method',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _MethodChip(
                        label: 'Mobile Wallet',
                        icon: Icons.phone_android_rounded,
                        selected: _method == PayoutMethodType.wallet,
                        onTap: () => setState(() => _method = PayoutMethodType.wallet),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MethodChip(
                        label: 'Bank Account',
                        icon: Icons.account_balance_rounded,
                        selected: _method == PayoutMethodType.bank,
                        onTap: () => setState(() => _method = PayoutMethodType.bank),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ─── Fields ───
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _method == PayoutMethodType.wallet
                      ? _WalletFields(
                          key: const ValueKey('wallet'),
                          isDark: isDark,
                          selectedProvider: _walletProvider,
                          onProviderChanged: (p) =>
                              setState(() => _walletProvider = p),
                          phoneCtrl: _walletPhoneCtrl,
                        )
                      : _BankFields(
                          key: const ValueKey('bank'),
                          isDark: isDark,
                          bankNameCtrl: _bankNameCtrl,
                          accountHolderCtrl: _accountHolderCtrl,
                          accountNumberCtrl: _accountNumberCtrl,
                          ibanCtrl: _ibanCtrl,
                        ),
                ),
                const SizedBox(height: 32),

                // ─── Save button ───
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isSaving ? null : () => _save(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Save Payout Details',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Info Banner ───

class _InfoBanner extends StatelessWidget {
  final bool isDark;
  const _InfoBanner({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Add your payout details so earnings can be transferred to you. '
              'Your information is stored securely.',
              style: TextStyle(fontSize: 12, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Method Chip ───

class _MethodChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _MethodChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.08)
              : (isDark ? AppColors.darkSurface : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: selected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.primary : null,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Wallet Fields ───

class _WalletFields extends StatelessWidget {
  final bool isDark;
  final WalletProviderType selectedProvider;
  final ValueChanged<WalletProviderType> onProviderChanged;
  final TextEditingController phoneCtrl;

  const _WalletFields({
    super.key,
    required this.isDark,
    required this.selectedProvider,
    required this.onProviderChanged,
    required this.phoneCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Wallet Provider',
          style: Theme.of(context)
              .textTheme
              .labelLarge
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<WalletProviderType>(
          initialValue: selectedProvider,
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark ? AppColors.darkSurface : Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
          items: WalletProviderType.values
              .map((p) => DropdownMenuItem(value: p, child: Text(p.label)))
              .toList(),
          onChanged: (v) {
            if (v != null) onProviderChanged(v);
          },
        ),
        const SizedBox(height: 16),
        Text(
          'Wallet Phone Number',
          style: Theme.of(context)
              .textTheme
              .labelLarge
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: phoneCtrl,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            hintText: 'e.g. 01xxxxxxxxx',
            filled: true,
            fillColor: isDark ? AppColors.darkSurface : Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            prefixIcon: const Icon(Icons.phone_rounded),
          ),
        ),
      ],
    );
  }
}

// ─── Bank Fields ───

class _BankFields extends StatelessWidget {
  final bool isDark;
  final TextEditingController bankNameCtrl;
  final TextEditingController accountHolderCtrl;
  final TextEditingController accountNumberCtrl;
  final TextEditingController ibanCtrl;

  const _BankFields({
    super.key,
    required this.isDark,
    required this.bankNameCtrl,
    required this.accountHolderCtrl,
    required this.accountNumberCtrl,
    required this.ibanCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Field(
          isDark: isDark,
          label: 'Bank Name',
          hint: 'e.g. CIB, NBE, Banque Misr',
          controller: bankNameCtrl,
          icon: Icons.account_balance_rounded,
        ),
        const SizedBox(height: 16),
        _Field(
          isDark: isDark,
          label: 'Account Holder Name',
          hint: 'Full name as on bank account',
          controller: accountHolderCtrl,
          icon: Icons.person_rounded,
        ),
        const SizedBox(height: 16),
        _Field(
          isDark: isDark,
          label: 'Account Number',
          hint: 'Your bank account number',
          controller: accountNumberCtrl,
          icon: Icons.credit_card_rounded,
          inputType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        _Field(
          isDark: isDark,
          label: 'IBAN (Optional)',
          hint: 'EG00 0000 0000 0000 ...',
          controller: ibanCtrl,
          icon: Icons.tag_rounded,
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  final bool isDark;
  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData icon;
  final TextInputType inputType;

  const _Field({
    required this.isDark,
    required this.label,
    required this.hint,
    required this.controller,
    required this.icon,
    this.inputType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelLarge
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: inputType,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: isDark ? AppColors.darkSurface : Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            prefixIcon: Icon(icon),
          ),
        ),
      ],
    );
  }
}
