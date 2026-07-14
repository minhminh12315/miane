import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PaymentAccountConfig {
  final String bankName;
  final String accountNumber;
  final String accountHolder;

  const PaymentAccountConfig({
    required this.bankName,
    required this.accountNumber,
    required this.accountHolder,
  });

  const PaymentAccountConfig.empty()
      : bankName = '',
        accountNumber = '',
        accountHolder = '';

  bool get isConfigured =>
      bankName.trim().isNotEmpty && accountNumber.trim().isNotEmpty;

  String get displayValue {
    if (!isConfigured) return 'Chưa cấu hình';
    return '${bankName.trim()} (${accountNumber.trim()})';
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

  static const _bankNameKey = 'payment_account_bank_name';
  static const _accountNumberKey = 'payment_account_number';
  static const _accountHolderKey = 'payment_account_holder';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = PaymentAccountConfig(
      bankName: prefs.getString(_bankNameKey) ?? '',
      accountNumber: prefs.getString(_accountNumberKey) ?? '',
      accountHolder: prefs.getString(_accountHolderKey) ?? '',
    );
  }

  Future<void> save({
    required String bankName,
    required String accountNumber,
    String accountHolder = '',
  }) async {
    final next = PaymentAccountConfig(
      bankName: bankName.trim(),
      accountNumber: accountNumber.trim(),
      accountHolder: accountHolder.trim(),
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_bankNameKey, next.bankName);
    await prefs.setString(_accountNumberKey, next.accountNumber);
    await prefs.setString(_accountHolderKey, next.accountHolder);
    state = next;
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
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
