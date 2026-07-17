import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/payments/viet_qr_payment.dart';
import '../../data/repositories/expense_repository_impl.dart';
import '../../domain/models/expense_models.dart';

part 'pool_controller.g.dart';

@riverpod
class TripPoolController extends _$TripPoolController {
  @override
  Future<TripPoolModel?> build(String tripId) async {
    final repo = ref.watch(expenseRepositoryProvider);
    return repo.getPool(tripId);
  }

  Future<void> contribute(double amount, String currency) async {
    final repo = ref.read(expenseRepositoryProvider);
    await repo.contributeToPool(tripId, amount, currency);
    ref.invalidateSelf();
    await future;
  }

  Future<VietQrPaymentQr> generateContributionQr(
    double amount,
    String currency,
  ) async {
    final repo = ref.read(expenseRepositoryProvider);
    return repo.generateFundContributionQr(tripId, amount, currency);
  }
}
