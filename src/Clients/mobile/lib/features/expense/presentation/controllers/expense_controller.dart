import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/repositories/expense_repository_impl.dart';
import '../../domain/models/expense_models.dart';

part 'expense_controller.g.dart';

@riverpod
class TripExpenses extends _$TripExpenses {
  @override
  Future<List<ExpenseModel>> build(String tripId) async {
    final repo = ref.watch(expenseRepositoryProvider);
    return repo.getExpenses(tripId);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(expenseRepositoryProvider);
      return repo.getExpenses(tripId);
    });
  }

  Future<void> createExpense({
    required String description,
    required double amount,
    required String currency,
    required String tripBaseCurrency,
    required int splitType,
    required List<Map<String, dynamic>> splits,
  }) async {
    final repo = ref.read(expenseRepositoryProvider);
    await repo.createExpense(
      tripId: tripId,
      description: description,
      amount: amount,
      currency: currency,
      tripBaseCurrency: tripBaseCurrency,
      splitType: splitType,
      splits: splits,
    );
    ref.invalidateSelf();
    await future;
  }
}

@riverpod
class TripBalances extends _$TripBalances {
  @override
  Future<TripBalancesModel> build(String tripId) async {
    final repo = ref.watch(expenseRepositoryProvider);
    return repo.getBalances(tripId);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(expenseRepositoryProvider);
      return repo.getBalances(tripId);
    });
  }

  Future<void> settle(String debtRecordId) async {
    final repo = ref.read(expenseRepositoryProvider);
    await repo.settleDebt(debtRecordId);
    ref.invalidateSelf();
    await future;
  }
}
