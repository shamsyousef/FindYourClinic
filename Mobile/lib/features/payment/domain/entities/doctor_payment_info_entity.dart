enum PayoutMethodType { wallet, bank }

enum WalletProviderType { vodafoneCash, orangeMoney, etisalatCash, wePay }

extension WalletProviderTypeLabel on WalletProviderType {
  String get label => switch (this) {
        WalletProviderType.vodafoneCash => 'Vodafone Cash',
        WalletProviderType.orangeMoney => 'Orange Money',
        WalletProviderType.etisalatCash => 'Etisalat Cash',
        WalletProviderType.wePay => 'WE Pay',
      };

  String get serverValue => switch (this) {
        WalletProviderType.vodafoneCash => 'VodafoneCash',
        WalletProviderType.orangeMoney => 'OrangeMoney',
        WalletProviderType.etisalatCash => 'EtisalatCash',
        WalletProviderType.wePay => 'WePay',
      };
}

class DoctorPaymentInfoEntity {
  final PayoutMethodType payoutMethod;
  final WalletProviderType? walletProvider;
  final String? walletPhoneNumber;
  final String? bankName;
  final String? accountHolderName;
  final String? accountNumber;
  final String? iban;

  const DoctorPaymentInfoEntity({
    required this.payoutMethod,
    this.walletProvider,
    this.walletPhoneNumber,
    this.bankName,
    this.accountHolderName,
    this.accountNumber,
    this.iban,
  });
}
