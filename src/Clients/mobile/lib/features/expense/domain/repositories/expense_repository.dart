import '../models/expense_models.dart';
import '../../../../core/payments/viet_qr_payment.dart';

abstract class ExpenseRepository {
  Future<List<ExpenseModel>> getExpenses(String tripId);
  Future<TripBalancesModel> getBalances(String tripId);
  Future<void> createExpense({
    required String tripId,
    required String description,
    required double amount,
    required String currency,
    required String tripBaseCurrency,
    required int splitType,
    required List<Map<String, dynamic>> splits,
  });
  Future<void> settleDebt(String debtRecordId);
  Future<VietQrPaymentQr> generateDebtPaymentQr(String debtRecordId);
  Future<TripPoolModel?> getPool(String tripId);
}
