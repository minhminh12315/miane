import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum PaymentDestinationType { bank, wallet }

class PaymentDestination {
  final String code;
  final String name;
  final String shortName;
  final PaymentDestinationType type;
  final int minLength;
  final int maxLength;

  const PaymentDestination({
    required this.code,
    required this.name,
    required this.shortName,
    required this.type,
    this.minLength = 6,
    this.maxLength = 19,
  });

  bool get isWallet => type == PaymentDestinationType.wallet;

  String get accountNumberLabel =>
      isWallet ? 'Số điện thoại ví nhận tiền' : 'Số tài khoản';

  String get validationTitle => isWallet ? 'số điện thoại ví' : 'số tài khoản';

  PaymentAccountValidationResult validateAccountNumber(String rawValue) {
    final normalized = rawValue.replaceAll(RegExp(r'[\s-]'), '');
    if (normalized.isEmpty) {
      return PaymentAccountValidationResult.invalid(
        'Vui lòng nhập $validationTitle.',
      );
    }

    if (isWallet) {
      final phone = _normalizeVietnamPhone(normalized);
      if (phone == null) {
        return PaymentAccountValidationResult.invalid(
          'Ví ${shortName.trim()} cần số điện thoại Việt Nam hợp lệ, ví dụ 0912345678.',
        );
      }

      return PaymentAccountValidationResult.valid(
        normalizedAccountNumber: phone,
        message:
            'Số điện thoại ví hợp lệ về định dạng. Chưa xác minh được chủ ví.',
      );
    }

    if (!RegExp(r'^\d+$').hasMatch(normalized)) {
      return PaymentAccountValidationResult.invalid(
        'Số tài khoản chỉ nên gồm chữ số, không nhập dấu cách hoặc ký tự khác.',
      );
    }

    if (normalized.length < minLength || normalized.length > maxLength) {
      return PaymentAccountValidationResult.invalid(
        '${shortName.trim()} thường dùng số tài khoản từ $minLength-$maxLength chữ số.',
      );
    }

    if (RegExp(r'^(\d)\1+$').hasMatch(normalized)) {
      return PaymentAccountValidationResult.invalid(
        'Số tài khoản không hợp lệ: không nên là một chữ số lặp lại.',
      );
    }

    return PaymentAccountValidationResult.valid(
      normalizedAccountNumber: normalized,
      message:
          'Số tài khoản hợp lệ về định dạng. Chưa xác minh được tên chủ tài khoản.',
    );
  }
}

class PaymentAccountValidationResult {
  final bool isValid;
  final String message;
  final String normalizedAccountNumber;

  const PaymentAccountValidationResult._({
    required this.isValid,
    required this.message,
    required this.normalizedAccountNumber,
  });

  factory PaymentAccountValidationResult.valid({
    required String normalizedAccountNumber,
    required String message,
  }) =>
      PaymentAccountValidationResult._(
        isValid: true,
        message: message,
        normalizedAccountNumber: normalizedAccountNumber,
      );

  factory PaymentAccountValidationResult.invalid(String message) =>
      PaymentAccountValidationResult._(
        isValid: false,
        message: message,
        normalizedAccountNumber: '',
      );
}

const supportedPaymentDestinations = <PaymentDestination>[
  PaymentDestination(
    code: 'VCB',
    name: 'Vietcombank',
    shortName: 'VCB',
    type: PaymentDestinationType.bank,
  ),
  PaymentDestination(
    code: 'TCB',
    name: 'Techcombank',
    shortName: 'TCB',
    type: PaymentDestinationType.bank,
  ),
  PaymentDestination(
    code: 'MB',
    name: 'MB Bank',
    shortName: 'MB',
    type: PaymentDestinationType.bank,
  ),
  PaymentDestination(
    code: 'ACB',
    name: 'ACB',
    shortName: 'ACB',
    type: PaymentDestinationType.bank,
  ),
  PaymentDestination(
    code: 'BIDV',
    name: 'BIDV',
    shortName: 'BIDV',
    type: PaymentDestinationType.bank,
  ),
  PaymentDestination(
    code: 'CTG',
    name: 'VietinBank',
    shortName: 'VietinBank',
    type: PaymentDestinationType.bank,
  ),
  PaymentDestination(
    code: 'VPB',
    name: 'VPBank',
    shortName: 'VPBank',
    type: PaymentDestinationType.bank,
  ),
  PaymentDestination(
    code: 'TPB',
    name: 'TPBank',
    shortName: 'TPBank',
    type: PaymentDestinationType.bank,
  ),
  PaymentDestination(
    code: 'STB',
    name: 'Sacombank',
    shortName: 'Sacombank',
    type: PaymentDestinationType.bank,
  ),
  PaymentDestination(
    code: 'VIB',
    name: 'VIB',
    shortName: 'VIB',
    type: PaymentDestinationType.bank,
  ),
  PaymentDestination(
    code: 'AGR',
    name: 'Agribank',
    shortName: 'Agribank',
    type: PaymentDestinationType.bank,
  ),
  PaymentDestination(
    code: 'MOMO',
    name: 'MoMo',
    shortName: 'MoMo',
    type: PaymentDestinationType.wallet,
    minLength: 10,
    maxLength: 10,
  ),
  PaymentDestination(
    code: 'ZALOPAY',
    name: 'ZaloPay',
    shortName: 'ZaloPay',
    type: PaymentDestinationType.wallet,
    minLength: 10,
    maxLength: 10,
  ),
  PaymentDestination(
    code: 'VNPAY',
    name: 'VNPay Wallet',
    shortName: 'VNPay',
    type: PaymentDestinationType.wallet,
    minLength: 10,
    maxLength: 10,
  ),
  PaymentDestination(
    code: 'VIETTELMONEY',
    name: 'Viettel Money',
    shortName: 'Viettel Money',
    type: PaymentDestinationType.wallet,
    minLength: 10,
    maxLength: 10,
  ),
];

PaymentDestination? findPaymentDestinationByCode(String code) {
  final normalized = code.trim().toUpperCase();
  if (normalized.isEmpty) return null;
  for (final destination in supportedPaymentDestinations) {
    if (destination.code.toUpperCase() == normalized) {
      return destination;
    }
  }
  return null;
}

PaymentDestination? findPaymentDestinationByName(String name) {
  final normalized = name.trim().toLowerCase();
  if (normalized.isEmpty) return null;
  for (final destination in supportedPaymentDestinations) {
    if (destination.name.toLowerCase() == normalized ||
        destination.shortName.toLowerCase() == normalized) {
      return destination;
    }
  }
  return null;
}

class PaymentAccountConfig {
  final String destinationCode;
  final String bankName;
  final String accountNumber;
  final String accountHolder;

  const PaymentAccountConfig({
    required this.destinationCode,
    required this.bankName,
    required this.accountNumber,
    required this.accountHolder,
  });

  const PaymentAccountConfig.empty()
      : destinationCode = '',
        bankName = '',
        accountNumber = '',
        accountHolder = '';

  PaymentDestination? get destination =>
      findPaymentDestinationByCode(destinationCode) ??
      findPaymentDestinationByName(bankName);

  String get destinationName => destination?.name ?? bankName.trim();

  bool get isConfigured =>
      destinationName.isNotEmpty && accountNumber.trim().isNotEmpty;

  String get displayValue {
    if (!isConfigured) return 'Chưa cấu hình';
    return '$destinationName (${accountNumber.trim()})';
  }

  String get displaySubtitle {
    if (!isConfigured) {
      return 'Cần cấu hình để tạo hoặc tham gia chuyến đi';
    }
    final holder = accountHolder.trim();
    return holder.isEmpty ? 'Tài khoản nhận tiền đã sẵn sàng' : holder;
  }
}

class PaymentAccountController extends StateNotifier<PaymentAccountConfig> {
  PaymentAccountController() : super(const PaymentAccountConfig.empty()) {
    _load();
  }

  static const _destinationCodeKey = 'payment_account_destination_code';
  static const _bankNameKey = 'payment_account_bank_name';
  static const _accountNumberKey = 'payment_account_number';
  static const _accountHolderKey = 'payment_account_holder';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final bankName = prefs.getString(_bankNameKey) ?? '';
    final destinationCode = prefs.getString(_destinationCodeKey) ??
        findPaymentDestinationByName(bankName)?.code ??
        '';
    state = PaymentAccountConfig(
      destinationCode: destinationCode,
      bankName: bankName,
      accountNumber: prefs.getString(_accountNumberKey) ?? '',
      accountHolder: prefs.getString(_accountHolderKey) ?? '',
    );
  }

  Future<void> save({
    required PaymentDestination destination,
    required String accountNumber,
    String accountHolder = '',
  }) async {
    final validation = destination.validateAccountNumber(accountNumber);
    if (!validation.isValid) {
      throw ArgumentError(validation.message);
    }

    final next = PaymentAccountConfig(
      destinationCode: destination.code,
      bankName: destination.name,
      accountNumber: validation.normalizedAccountNumber,
      accountHolder: accountHolder.trim(),
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_destinationCodeKey, next.destinationCode);
    await prefs.setString(_bankNameKey, next.bankName);
    await prefs.setString(_accountNumberKey, next.accountNumber);
    await prefs.setString(_accountHolderKey, next.accountHolder);
    state = next;
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_destinationCodeKey);
    await prefs.remove(_bankNameKey);
    await prefs.remove(_accountNumberKey);
    await prefs.remove(_accountHolderKey);
    state = const PaymentAccountConfig.empty();
  }
}

final paymentAccountProvider =
    StateNotifierProvider<PaymentAccountController, PaymentAccountConfig>(
  (ref) => PaymentAccountController(),
);

String? _normalizeVietnamPhone(String value) {
  var digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('84') && digits.length == 11) {
    digits = '0${digits.substring(2)}';
  }

  if (!RegExp(r'^(03|05|07|08|09)\d{8}$').hasMatch(digits)) {
    return null;
  }

  return digits;
}
