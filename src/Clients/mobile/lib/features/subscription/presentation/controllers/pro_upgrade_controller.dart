import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../auth/data/repositories/auth_repository_impl.dart';
import '../../../auth/presentation/controllers/app_auth_provider.dart';
import '../../data/services/iap_service.dart';

part 'pro_upgrade_controller.g.dart';

enum ProUpgradeStatus { idle, purchasing, success, error }

class ProUpgradeState {
  final ProUpgradeStatus status;
  final String? errorMessage;

  const ProUpgradeState({
    this.status = ProUpgradeStatus.idle,
    this.errorMessage,
  });

  ProUpgradeState copyWith({ProUpgradeStatus? status, String? errorMessage}) {
    return ProUpgradeState(
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }
}

@riverpod
class ProUpgradeController extends _$ProUpgradeController {
  final _iapService = IapService();
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  @override
  ProUpgradeState build() {
    _subscription = _iapService.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (Object error) {
        state = state.copyWith(
          status: ProUpgradeStatus.error,
          errorMessage: error.toString(),
        );
      },
    );
    ref.onDispose(() => _subscription?.cancel());
    return const ProUpgradeState();
  }

  Future<void> purchasePro() async {
    state =
        state.copyWith(status: ProUpgradeStatus.purchasing, errorMessage: null);

    final available = await _iapService.isAvailable();
    if (!available) {
      state = state.copyWith(
        status: ProUpgradeStatus.error,
        errorMessage:
            'Cửa hàng ứng dụng hiện không khả dụng trên thiết bị này.',
      );
      return;
    }

    final product = await _iapService.getProProduct();
    if (product == null) {
      state = state.copyWith(
        status: ProUpgradeStatus.error,
        errorMessage: 'Không tìm thấy gói MIANE VIP. Vui lòng thử lại sau.',
      );
      return;
    }

    try {
      await _iapService.buyPro(product);
      // Purchase result arrives asynchronously via purchaseStream.
    } catch (e) {
      state = state.copyWith(
        status: ProUpgradeStatus.error,
        errorMessage: 'Không thể khởi tạo giao dịch: $e',
      );
    }
  }

  void reset() {
    state = const ProUpgradeState();
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          state = state.copyWith(status: ProUpgradeStatus.purchasing);
          break;

        case PurchaseStatus.error:
          state = state.copyWith(
            status: ProUpgradeStatus.error,
            errorMessage: purchase.error?.message ?? 'Giao dịch thất bại.',
          );
          await _iapService.completePurchase(purchase);
          break;

        case PurchaseStatus.canceled:
          state = state.copyWith(status: ProUpgradeStatus.idle);
          await _iapService.completePurchase(purchase);
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _confirmWithBackend(purchase);
          break;
      }
    }
  }

  Future<void> _confirmWithBackend(PurchaseDetails purchase) async {
    try {
      // DEV NOTE: trusts the local purchase result — no server-side receipt
      // verification yet. See AuthController.UpgradeToPro remarks.
      await ref.read(authRepositoryProvider).upgradeToPro();
      ref.invalidate(currentUserTierProvider);
      state = state.copyWith(status: ProUpgradeStatus.success);
    } catch (e) {
      state = state.copyWith(
        status: ProUpgradeStatus.error,
        errorMessage:
            'Thanh toán thành công nhưng không thể nâng cấp tài khoản: $e',
      );
    } finally {
      await _iapService.completePurchase(purchase);
    }
  }
}
