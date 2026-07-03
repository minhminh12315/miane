import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/models/trip_models.dart';
import '../../domain/repositories/trip_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TripRepositoryImpl implements TripRepository {
  final ApiClient _apiClient;

  TripRepositoryImpl(this._apiClient);

  @override
  Future<List<TripModel>> getTrips() async {
    final response = await _apiClient.get(ApiEndpoints.trips);
    if (response is List) {
      return response.map((json) => TripModel.fromJson(json)).toList();
    }
    return [];
  }

  @override
  Future<TripDetailModel> getTrip(String id) async {
    final response = await _apiClient.get('${ApiEndpoints.trips}/$id');
    return TripDetailModel.fromJson(response);
  }

  @override
  Future<Map<String, dynamic>> createTrip(
    String name,
    String? description,
    String? baseCurrency,
  ) async {
    final response = await _apiClient.post(
      ApiEndpoints.trips,
      body: {
        'name': name,
        'description': description,
        'baseCurrency': baseCurrency ?? 'VND',
      },
    );
    return response as Map<String, dynamic>;
  }

  @override
  Future<TripCreationResult> createTripDraft(TripCreationDraft draft) async {
    final response = await _apiClient.post(
      ApiEndpoints.trips,
      body: draft.toApiJson(),
    );
    return TripCreationResult.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<Map<String, dynamic>> joinTrip(
    String inviteCode,
    String? nickName,
  ) async {
    final response = await _apiClient.post(
      ApiEndpoints.joinTrip,
      body: {
        'inviteCode': inviteCode,
        'nickName': nickName,
      },
    );
    return response as Map<String, dynamic>;
  }

  @override
  Future<void> leaveTrip(String tripId) async {
    await _apiClient.post(ApiEndpoints.leaveTrip(tripId));
  }
}

final tripRepositoryProvider = Provider<TripRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return TripRepositoryImpl(apiClient);
});
