import '../models/trip_models.dart';

abstract class TripRepository {
  Future<List<TripModel>> getTrips();
  Future<TripDetailModel> getTrip(String id);
  Future<Map<String, dynamic>> createTrip(
      String name, String? description, String? baseCurrency);
  Future<TripCreationResult> createTripDraft(TripCreationDraft draft);
  Future<Map<String, dynamic>> joinTrip(String inviteCode, String? nickName);
  Future<void> leaveTrip(String tripId);
}
