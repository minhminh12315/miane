import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/payments/viet_qr_payment.dart';

enum PaymentDestinationType { bank, wallet }

class PaymentDestination {
  final String code;
  final String bin;
  final String name;
  final String shortName;
  final String logoUrl;
  final PaymentDestinationType type;
  final bool transferSupported;
  final bool lookupSupported;
  final int minLength;
  final int maxLength;

  const PaymentDestination({
    required this.code,
    required this.bin,
    required this.name,
    required this.shortName,
    required this.type,
    this.logoUrl = '',
    this.transferSupported = true,
    this.lookupSupported = false,
    this.minLength = 6,
    this.maxLength = 19,
  });

  factory PaymentDestination.fromVietQrJson(Map<String, dynamic> json) {
    return PaymentDestination(
      code: (json['code'] ?? '').toString(),
      bin: (json['bin'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      shortName: (json['shortName'] ?? json['code'] ?? '').toString(),
      logoUrl: (json['logo'] ?? '').toString(),
      type: PaymentDestinationType.bank,
      transferSupported: json['transferSupported'] == true,
      lookupSupported: json['lookupSupported'] == true,
    );
  }

  bool get isWallet => type == PaymentDestinationType.wallet;
  bool get isBank => type == PaymentDestinationType.bank;

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
          'Số tài khoản hợp lệ về định dạng. VietQR sẽ dùng tên tài khoản bạn nhập.',
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

  PaymentAccountValidationResult copyWith({
    bool? isValid,
    String? message,
    String? normalizedAccountNumber,
  }) {
    return PaymentAccountValidationResult._(
      isValid: isValid ?? this.isValid,
      message: message ?? this.message,
      normalizedAccountNumber:
          normalizedAccountNumber ?? this.normalizedAccountNumber,
    );
  }
}

const supportedPaymentDestinations = <PaymentDestination>[
  PaymentDestination(
    code: 'VCB',
    bin: '970436',
    name: 'Vietcombank',
    shortName: 'VCB',
    type: PaymentDestinationType.bank,
  ),
  PaymentDestination(
    code: 'TCB',
    bin: '970407',
    name: 'Techcombank',
    shortName: 'TCB',
    type: PaymentDestinationType.bank,
  ),
  PaymentDestination(
    code: 'MBB',
    bin: '970422',
    name: 'MB Bank',
    shortName: 'MB',
    type: PaymentDestinationType.bank,
  ),
  PaymentDestination(
    code: 'ACB',
    bin: '970416',
    name: 'ACB',
    shortName: 'ACB',
    type: PaymentDestinationType.bank,
  ),
  PaymentDestination(
    code: 'BIDV',
    bin: '970418',
    name: 'BIDV',
    shortName: 'BIDV',
    type: PaymentDestinationType.bank,
  ),
  PaymentDestination(
    code: 'ICB',
    bin: '970415',
    name: 'VietinBank',
    shortName: 'VietinBank',
    type: PaymentDestinationType.bank,
  ),
  PaymentDestination(
    code: 'VPB',
    bin: '970432',
    name: 'VPBank',
    shortName: 'VPBank',
    type: PaymentDestinationType.bank,
  ),
  PaymentDestination(
    code: 'TPB',
    bin: '970423',
    name: 'TPBank',
    shortName: 'TPBank',
    type: PaymentDestinationType.bank,
  ),
  PaymentDestination(
    code: 'STB',
    bin: '970403',
    name: 'Sacombank',
    shortName: 'Sacombank',
    type: PaymentDestinationType.bank,
  ),
  PaymentDestination(
    code: 'VIB',
    bin: '970441',
    name: 'VIB',
    shortName: 'VIB',
    type: PaymentDestinationType.bank,
  ),
  PaymentDestination(
    code: 'VBA',
    bin: '970405',
    name: 'Agribank',
    shortName: 'Agribank',
    type: PaymentDestinationType.bank,
  ),
  PaymentDestination(
    code: 'MOMO',
    bin: '',
    name: 'MoMo',
    shortName: 'MoMo',
    type: PaymentDestinationType.wallet,
    minLength: 10,
    maxLength: 10,
  ),
  PaymentDestination(
    code: 'ZALOPAY',
    bin: '',
    name: 'ZaloPay',
    shortName: 'ZaloPay',
    type: PaymentDestinationType.wallet,
    minLength: 10,
    maxLength: 10,
  ),
  PaymentDestination(
    code: 'VNPAY',
    bin: '',
    name: 'VNPay Wallet',
    shortName: 'VNPay',
    type: PaymentDestinationType.wallet,
    minLength: 10,
    maxLength: 10,
  ),
  PaymentDestination(
    code: 'VIETTELMONEY',
    bin: '',
    name: 'Viettel Money',
    shortName: 'Viettel Money',
    type: PaymentDestinationType.wallet,
    minLength: 10,
    maxLength: 10,
  ),
];

PaymentDestination? findPaymentDestinationByCode(
  String code, {
  Iterable<PaymentDestination> destinations = supportedPaymentDestinations,
}) {
  final normalized = code.trim().toUpperCase();
  if (normalized.isEmpty) return null;
  for (final destination in destinations) {
    if (destination.code.toUpperCase() == normalized ||
        destination.bin == normalized) {
      return destination;
    }
  }
  return null;
}

PaymentDestination? findPaymentDestinationByName(
  String name, {
  Iterable<PaymentDestination> destinations = supportedPaymentDestinations,
}) {
  final normalized = name.trim().toLowerCase();
  if (normalized.isEmpty) return null;
  for (final destination in destinations) {
    if (destination.name.toLowerCase() == normalized ||
        destination.shortName.toLowerCase() == normalized) {
      return destination;
    }
  }
  return null;
}

PaymentDestination? findPaymentDestinationByBin(
  String bin, {
  Iterable<PaymentDestination> destinations = supportedPaymentDestinations,
}) {
  final normalized = bin.trim();
  if (normalized.isEmpty) return null;
  for (final destination in destinations) {
    if (destination.bin == normalized) {
      return destination;
    }
  }
  return null;
}

class PaymentAccountConfig {
  final String destinationCode;
  final String bankBin;
  final String bankName;
  final String bankLogoUrl;
  final String accountNumber;
  final String accountHolder;

  const PaymentAccountConfig({
    required this.destinationCode,
    required this.bankBin,
    required this.bankName,
    required this.bankLogoUrl,
    required this.accountNumber,
    required this.accountHolder,
  });

  const PaymentAccountConfig.empty()
      : destinationCode = '',
        bankBin = '',
        bankName = '',
        bankLogoUrl = '',
        accountNumber = '',
        accountHolder = '';

  factory PaymentAccountConfig.fromPaymentMethodJson(
    Map<String, dynamic> json,
  ) {
    return PaymentAccountConfig(
      destinationCode: (json['bankCode'] ?? '').toString(),
      bankBin: (json['bankBin'] ?? '').toString(),
      bankName: (json['bankName'] ??
              json['bankShortName'] ??
              json['displayName'] ??
              '')
          .toString(),
      bankLogoUrl: (json['bankLogoUrl'] ?? '').toString(),
      accountNumber: (json['accountNumber'] ?? '').toString(),
      accountHolder: (json['accountName'] ?? '').toString(),
    );
  }

  PaymentDestination? get destination => resolveDestination();

  PaymentDestination? resolveDestination([
    Iterable<PaymentDestination> destinations = supportedPaymentDestinations,
  ]) {
    return findPaymentDestinationByBin(bankBin, destinations: destinations) ??
        findPaymentDestinationByCode(destinationCode,
            destinations: destinations) ??
        findPaymentDestinationByName(bankName, destinations: destinations);
  }

  String get destinationName => destination?.name ?? bankName.trim();
  bool get isBank => bankBin.trim().isNotEmpty;

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
  final ApiClient _apiClient;

  PaymentAccountController(this._apiClient)
      : super(const PaymentAccountConfig.empty()) {
    _load();
  }

  static const _destinationCodeKey = 'payment_account_destination_code';
  static const _bankBinKey = 'payment_account_bank_bin';
  static const _bankNameKey = 'payment_account_bank_name';
  static const _bankLogoUrlKey = 'payment_account_bank_logo_url';
  static const _accountNumberKey = 'payment_account_number';
  static const _accountHolderKey = 'payment_account_holder';

  Future<void> _load() async {
    await _loadLocal();
    await refreshFromServer();
  }

  Future<void> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final bankName = prefs.getString(_bankNameKey) ?? '';
    final bankBin = prefs.getString(_bankBinKey) ?? '';
    final destinationCode = prefs.getString(_destinationCodeKey) ??
        findPaymentDestinationByName(bankName)?.code ??
        '';
    state = PaymentAccountConfig(
      destinationCode: destinationCode,
      bankBin: bankBin,
      bankName: bankName,
      bankLogoUrl: prefs.getString(_bankLogoUrlKey) ?? '',
      accountNumber: prefs.getString(_accountNumberKey) ?? '',
      accountHolder: prefs.getString(_accountHolderKey) ?? '',
    );
  }

  Future<void> refreshFromServer() async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.defaultReceivePaymentMethod,
      );
      if (response is! Map<String, dynamic>) {
        return;
      }

      final next = PaymentAccountConfig.fromPaymentMethodJson(response);
      await _persist(next);
      state = next;
    } catch (_) {
      // Keep the local fallback usable when the user is offline or logged out.
    }
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

    PaymentAccountConfig next;
    if (destination.isBank) {
      final response = await _apiClient.put(
        ApiEndpoints.defaultReceivePaymentMethod,
        body: {
          'bankBin': destination.bin,
          'bankCode': destination.code,
          'accountNumber': validation.normalizedAccountNumber,
          'accountName': accountHolder.trim(),
        },
      );

      if (response is Map<String, dynamic>) {
        next = PaymentAccountConfig.fromPaymentMethodJson(response);
      } else {
        next = PaymentAccountConfig(
          destinationCode: destination.code,
          bankBin: destination.bin,
          bankName: destination.name,
          bankLogoUrl: destination.logoUrl,
          accountNumber: validation.normalizedAccountNumber,
          accountHolder: accountHolder.trim(),
        );
      }
    } else {
      next = PaymentAccountConfig(
        destinationCode: destination.code,
        bankBin: destination.bin,
        bankName: destination.name,
        bankLogoUrl: destination.logoUrl,
        accountNumber: validation.normalizedAccountNumber,
        accountHolder: accountHolder.trim(),
      );
    }

    await _persist(next);
    state = next;
  }

  Future<VietQrPaymentQr> generateQr({
    required int amount,
    String addInfo = '',
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.generateVietQr,
      body: {
        'amount': amount,
        'addInfo': addInfo,
        'template': 'compact',
        'format': 'text',
      },
    );

    if (response is Map<String, dynamic>) {
      return VietQrPaymentQr.fromJson(response);
    }

    throw ApiException(500, 'Không thể tạo mã VietQR.');
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_destinationCodeKey);
    await prefs.remove(_bankBinKey);
    await prefs.remove(_bankNameKey);
    await prefs.remove(_bankLogoUrlKey);
    await prefs.remove(_accountNumberKey);
    await prefs.remove(_accountHolderKey);
    state = const PaymentAccountConfig.empty();
  }

  Future<void> _persist(PaymentAccountConfig next) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_destinationCodeKey, next.destinationCode);
    await prefs.setString(_bankBinKey, next.bankBin);
    await prefs.setString(_bankNameKey, next.bankName);
    await prefs.setString(_bankLogoUrlKey, next.bankLogoUrl);
    await prefs.setString(_accountNumberKey, next.accountNumber);
    await prefs.setString(_accountHolderKey, next.accountHolder);
  }
}

final paymentDestinationsProvider =
    FutureProvider<List<PaymentDestination>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  try {
    final response = await apiClient.get(ApiEndpoints.vietQrBanks);
    if (response is List) {
      final banks = response
          .whereType<Map<String, dynamic>>()
          .map(PaymentDestination.fromVietQrJson)
          .where((bank) => bank.bin.isNotEmpty && bank.transferSupported)
          .toList();
      if (banks.isNotEmpty) {
        final wallets = supportedPaymentDestinations
            .where((destination) => destination.isWallet)
            .toList();
        return [...banks, ...wallets];
      }
    }
  } catch (_) {
    // Fallback below keeps settings usable while offline.
  }

  return supportedPaymentDestinations;
});

final paymentAccountProvider =
    StateNotifierProvider<PaymentAccountController, PaymentAccountConfig>(
  (ref) => PaymentAccountController(ref.watch(apiClientProvider)),
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
