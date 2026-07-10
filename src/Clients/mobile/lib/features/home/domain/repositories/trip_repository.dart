import '../models/trip_models.dart';

abstract class TripRepository {
  Future<List<TripModel>> getTrips();
  Future<TripDetailModel> getTrip(String id);
  Future<Map<String, dynamic>> createTrip(
      String name, String? description, String? baseCurrency);
  Future<TripCreationResult> createTripDraft(TripCreationDraft draft);
  Future<Map<String, dynamic>> joinTrip(String inviteCode, String? nickName);
  Future<void> leaveTrip(String tripId);
  Future<List<TripFileModel>> getTripFiles(String tripId);
  Future<TripFileModel> addTripFile(String tripId, TripFileDraft draft);
  Future<TripFileModel> uploadTripFile(String tripId, TripLocalFileDraft draft);
  Future<TripFileModel> addTripNote(String tripId, TripNoteDraft draft);
  Future<void> deleteTripFile(String tripId, String fileId);
}
