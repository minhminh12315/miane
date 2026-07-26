import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/models/trip_leg_model.dart';
import '../../domain/models/trip_models.dart';
import '../../domain/repositories/trip_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TripRepositoryImpl implements TripRepository {
  final ApiClient _apiClient;

  TripRepositoryImpl(this._apiClient);

  @override
  Future<List<TripModel>> getTrips() async {
    final response = await _apiClient.get(ApiEndpoints.trips);
    if (response is! List) return [];
    return response
        .whereType<Map>()
        .map((json) => TripModel.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }

  @override
  Future<TripDetailModel> getTrip(String id) async {
    final response = await _apiClient.get('${ApiEndpoints.trips}/$id');
    if (response is! Map) {
      throw const FormatException('Unexpected trip payload.');
    }
    return TripDetailModel.fromJson(Map<String, dynamic>.from(response));
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
    if (response is! Map) {
      throw const FormatException('Unexpected create-trip payload.');
    }
    return Map<String, dynamic>.from(response);
  }

  @override
  Future<TripCreationResult> createTripDraft(TripCreationDraft draft) async {
    final response = await _apiClient.post(
      ApiEndpoints.trips,
      body: draft.toApiJson(),
    );
    if (response is! Map) {
      throw const FormatException('Unexpected create-trip draft payload.');
    }
    return TripCreationResult.fromJson(Map<String, dynamic>.from(response));
  }

  @override
  Future<String> uploadTripCover(
    String tripId, {
    required List<int> fileBytes,
    required String fileName,
  }) async {
    final response = await _apiClient.postMultipart(
      ApiEndpoints.uploadTripCover(tripId),
      fileBytes: fileBytes,
      fileName: fileName,
    );
    if (response is! Map<String, dynamic>) {
      throw ApiException(500, 'Phản hồi tải ảnh bìa không hợp lệ.');
    }
    return (response['coverImageUrl'] ?? '').toString();
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
    if (response is! Map) {
      throw const FormatException('Unexpected join-trip payload.');
    }
    return Map<String, dynamic>.from(response);
  }

  @override
  Future<void> deleteTrip(String tripId) async {
    await _apiClient.delete(ApiEndpoints.trip(tripId));
  }

  @override
  Future<void> leaveTrip(String tripId) async {
    await _apiClient.post(ApiEndpoints.leaveTrip(tripId));
  }

  @override
  Future<List<TripFileModel>> getTripFiles(String tripId) async {
    final response = await _apiClient.get(ApiEndpoints.tripFiles(tripId));
    if (response is List) {
      return response
          .map((json) => TripFileModel.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<TripFileModel> addTripFile(
    String tripId,
    TripFileDraft draft,
  ) async {
    final response = await _apiClient.post(
      ApiEndpoints.tripFiles(tripId),
      body: draft.toApiJson(),
    );
    return TripFileModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<TripFileModel> uploadTripFile(
    String tripId,
    TripLocalFileDraft draft,
  ) async {
    final response = await _apiClient.postMultipart(
      ApiEndpoints.uploadTripFile(tripId),
      filePath: draft.filePath,
      fileBytes: draft.fileBytes,
      fileName: draft.fileName,
      fields: {
        'folder': draft.folder,
        if (draft.tags.isNotEmpty) 'tags': draft.tags.join(','),
      },
    );
    return TripFileModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<TripFileModel> addTripNote(
    String tripId,
    TripNoteDraft draft,
  ) async {
    final response = await _apiClient.post(
      ApiEndpoints.tripNotes(tripId),
      body: draft.toApiJson(),
    );
    return TripFileModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<void> deleteTripFile(String tripId, String fileId) async {
    await _apiClient.delete(ApiEndpoints.tripFile(tripId, fileId));
  }

  @override
  Future<void> updateTripDates(
    String tripId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await _apiClient.put(
      '${ApiEndpoints.trips}/$tripId',
      body: {
        if (startDate != null) 'startDate': _dateToApi(startDate),
        if (endDate != null) 'endDate': _dateToApi(endDate),
      },
    );
  }

  @override
  Future<void> updateTripInfo(
    String tripId, {
    String? name,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await _apiClient.put(
      '${ApiEndpoints.trips}/$tripId',
      body: {
        if (name != null) 'name': name,
        if (startDate != null) 'startDate': _dateToApi(startDate),
        if (endDate != null) 'endDate': _dateToApi(endDate),
      },
    );
  }

  @override
  Future<List<TripLegModel>> getLegs(String tripId) async {
    final response = await _apiClient.get(ApiEndpoints.tripLegs(tripId));
    if (response is List) {
      return response
          .map((json) => TripLegModel.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<void> addLeg(
    String tripId, {
    required String name,
    String? destinationCity,
    String? destinationCountry,
    DateTime? startDate,
    DateTime? endDate,
    String? notes,
  }) async {
    await _apiClient.post(
      ApiEndpoints.tripLegs(tripId),
      body: {
        'name': name,
        if (destinationCity != null) 'destinationCity': destinationCity,
        if (destinationCountry != null)
          'destinationCountry': destinationCountry,
        if (startDate != null) 'startDate': _dateToApi(startDate),
        if (endDate != null) 'endDate': _dateToApi(endDate),
        if (notes != null) 'notes': notes,
      },
    );
  }

  @override
  Future<void> deleteLeg(String tripId, String legId) async {
    await _apiClient.delete(ApiEndpoints.tripLeg(tripId, legId));
  }
}

String _dateToApi(DateTime date) =>
    DateTime.utc(date.year, date.month, date.day).toIso8601String();

final tripRepositoryProvider = Provider<TripRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return TripRepositoryImpl(apiClient);
});
