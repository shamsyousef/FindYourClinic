import '../../domain/entities/doctor_payment_info_entity.dart';

class DoctorPaymentInfoModel {
  final String payoutMethod;
  final String? walletProvider;
  final String? walletPhoneNumber;
  final String? bankName;
  final String? accountHolderName;
  final String? accountNumber;
  final String? iban;

  const DoctorPaymentInfoModel({
    required this.payoutMethod,
    this.walletProvider,
    this.walletPhoneNumber,
    this.bankName,
    this.accountHolderName,
    this.accountNumber,
    this.iban,
  });

  factory DoctorPaymentInfoModel.fromJson(Map<String, dynamic> json) {
    return DoctorPaymentInfoModel(
      payoutMethod: json['payoutMethod'] as String? ?? 'Wallet',
      walletProvider: json['walletProvider'] as String?,
      walletPhoneNumber: json['walletPhoneNumber'] as String?,
      bankName: json['bankName'] as String?,
      accountHolderName: json['accountHolderName'] as String?,
      accountNumber: json['accountNumber'] as String?,
      iban: json['iBAN'] as String? ?? json['iban'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'payoutMethod': _payoutMethodIndex(),
        if (walletProvider != null) 'walletProvider': _walletProviderIndex(),
        if (walletPhoneNumber != null) 'walletPhoneNumber': walletPhoneNumber,
        if (bankName != null) 'bankName': bankName,
        if (accountHolderName != null) 'accountHolderName': accountHolderName,
        if (accountNumber != null) 'accountNumber': accountNumber,
        if (iban != null) 'iBAN': iban,
      };

  int _payoutMethodIndex() =>
      payoutMethod.toLowerCase() == 'bank' ? 1 : 0;

  int? _walletProviderIndex() {
    switch (walletProvider?.toLowerCase()) {
      case 'orangemoney':
        return 1;
      case 'etisalatcash':
        return 2;
      case 'wepay':
        return 3;
      default:
        return 0; // VodafoneCash
    }
  }

  DoctorPaymentInfoEntity toEntity() {
    return DoctorPaymentInfoEntity(
      payoutMethod: payoutMethod.toLowerCase() == 'bank'
          ? PayoutMethodType.bank
          : PayoutMethodType.wallet,
      walletProvider: _parseWalletProvider(walletProvider),
      walletPhoneNumber: walletPhoneNumber,
      bankName: bankName,
      accountHolderName: accountHolderName,
      accountNumber: accountNumber,
      iban: iban,
    );
  }

  static WalletProviderType? _parseWalletProvider(String? raw) {
    switch (raw?.toLowerCase()) {
      case 'orangemoney':
        return WalletProviderType.orangeMoney;
      case 'etisalatcash':
        return WalletProviderType.etisalatCash;
      case 'wepay':
        return WalletProviderType.wePay;
      case 'vodafonecash':
        return WalletProviderType.vodafoneCash;
      default:
        return null;
    }
  }

  static DoctorPaymentInfoModel fromEntity(DoctorPaymentInfoEntity entity) {
    return DoctorPaymentInfoModel(
      payoutMethod: entity.payoutMethod == PayoutMethodType.bank ? 'Bank' : 'Wallet',
      walletProvider: entity.walletProvider?.serverValue,
      walletPhoneNumber: entity.walletPhoneNumber,
      bankName: entity.bankName,
      accountHolderName: entity.accountHolderName,
      accountNumber: entity.accountNumber,
      iban: entity.iban,
    );
  }
}
