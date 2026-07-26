import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/payments/viet_qr_payment.dart';
import '../../domain/models/expense_models.dart';
import '../../domain/repositories/expense_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final ApiClient _apiClient;

  ExpenseRepositoryImpl(this._apiClient);

  @override
  Future<List<ExpenseModel>> getExpenses(String tripId) async {
    final response = await _apiClient.get(ApiEndpoints.tripExpenses(tripId));
    if (response is! List) return [];
    return response
        .whereType<Map>()
        .map((json) => ExpenseModel.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }

  @override
  Future<TripBalancesModel> getBalances(String tripId) async {
    final response = await _apiClient.get(ApiEndpoints.tripBalances(tripId));
    if (response is! Map) {
      throw const FormatException('Unexpected balances payload.');
    }
    return TripBalancesModel.fromJson(Map<String, dynamic>.from(response));
  }

  @override
  Future<void> createExpense({
    required String tripId,
    required String description,
    required double amount,
    required String currency,
    required String tripBaseCurrency,
    required int splitType,
    required List<Map<String, dynamic>> splits,
  }) async {
    await _apiClient.post(
      ApiEndpoints.expenses,
      body: {
        'tripId': tripId,
        'description': description,
        'amount': amount,
        'currency': currency,
        'tripBaseCurrency': tripBaseCurrency,
        'splitType': splitType,
        'splits': splits,
      },
    );
  }

  @override
  Future<void> settleDebt(String debtRecordId) async {
    await _apiClient.post(
      ApiEndpoints.settleDebt,
      body: {
        'debtRecordId': debtRecordId,
      },
    );
  }

  @override
  Future<VietQrPaymentQr> generateDebtPaymentQr(String debtRecordId) async {
    final response = await _apiClient.post(
      ApiEndpoints.generateDebtVietQr(debtRecordId),
      body: {
        'template': 'compact',
        'format': 'text',
      },
    );

    if (response is Map<String, dynamic>) {
      return VietQrPaymentQr.fromJson(response);
    }

    throw ApiException(500, 'Không thể tạo mã VietQR trả nợ.');
  }

  @override
  Future<TripPoolModel?> getPool(String tripId) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.getPool(tripId));
      if (response is Map) {
        return TripPoolModel.fromJson(Map<String, dynamic>.from(response));
      }
    } catch (_) {}
    return null;
  }
}

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ExpenseRepositoryImpl(apiClient);
});
