import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/models/expense_models.dart';
import '../../domain/repositories/expense_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final ApiClient _apiClient;

  ExpenseRepositoryImpl(this._apiClient);

  @override
  Future<List<ExpenseModel>> getExpenses(String tripId) async {
    final response = await _apiClient.get(ApiEndpoints.tripExpenses(tripId));
    if (response is List) {
      return response.map((json) => ExpenseModel.fromJson(json)).toList();
    }
    return [];
  }

  @override
  Future<TripBalancesModel> getBalances(String tripId) async {
    final response = await _apiClient.get(ApiEndpoints.tripBalances(tripId));
    return TripBalancesModel.fromJson(response);
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
  Future<TripPoolModel?> getPool(String tripId) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.getPool(tripId));
      if (response != null) {
        return TripPoolModel.fromJson(response);
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<void> contributeToPool(String tripId, double amount, String currency) async {
    await _apiClient.post(
      ApiEndpoints.contributeToPool,
      body: {
        'tripId': tripId,
        'amount': amount,
        'currency': currency,
      },
    );
  }
}

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ExpenseRepositoryImpl(apiClient);
});
