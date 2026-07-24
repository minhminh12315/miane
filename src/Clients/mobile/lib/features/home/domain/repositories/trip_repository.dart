import '../models/trip_leg_model.dart';
import '../models/trip_models.dart';

abstract class TripRepository {
  Future<List<TripModel>> getTrips();
  Future<TripDetailModel> getTrip(String id);
  Future<Map<String, dynamic>> createTrip(
      String name, String? description, String? baseCurrency);
  Future<TripCreationResult> createTripDraft(TripCreationDraft draft);
  Future<String> uploadTripCover(
    String tripId, {
    required List<int> fileBytes,
    required String fileName,
  });
  Future<Map<String, dynamic>> joinTrip(String inviteCode, String? nickName);
  Future<void> deleteTrip(String tripId);
  Future<void> leaveTrip(String tripId);
  Future<List<TripFileModel>> getTripFiles(String tripId);
  Future<TripFileModel> addTripFile(String tripId, TripFileDraft draft);
  Future<TripFileModel> uploadTripFile(String tripId, TripLocalFileDraft draft);
  Future<TripFileModel> addTripNote(String tripId, TripNoteDraft draft);
  Future<void> deleteTripFile(String tripId, String fileId);

  Future<void> updateTripDates(
    String tripId, {
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<void> updateTripInfo(
    String tripId, {
    String? name,
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<List<TripLegModel>> getLegs(String tripId);
  Future<void> addLeg(
    String tripId, {
    required String name,
    String? destinationCity,
    String? destinationCountry,
    DateTime? startDate,
    DateTime? endDate,
    String? notes,
  });
  Future<void> deleteLeg(String tripId, String legId);
}
