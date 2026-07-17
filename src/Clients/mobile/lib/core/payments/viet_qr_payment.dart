class VietQrPaymentQr {
  final String qrCode;
  final String qrDataUrl;
  final String bankName;
  final String accountNumber;
  final String accountName;
  final int amount;
  final String addInfo;

  const VietQrPaymentQr({
    required this.qrCode,
    required this.qrDataUrl,
    required this.bankName,
    required this.accountNumber,
    required this.accountName,
    required this.amount,
    required this.addInfo,
  });

  factory VietQrPaymentQr.fromJson(Map<String, dynamic> json) {
    return VietQrPaymentQr(
      qrCode: (json['qrCode'] ?? '').toString(),
      qrDataUrl: (json['qrDataUrl'] ?? '').toString(),
      bankName: (json['bankShortName'] ?? json['bankName'] ?? '').toString(),
      accountNumber: (json['accountNumber'] ?? '').toString(),
      accountName: (json['accountName'] ?? '').toString(),
      amount: (json['amount'] as num? ?? 0).toInt(),
      addInfo: (json['addInfo'] ?? '').toString(),
    );
  }
}
