import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart'
    show Ref, StateNotifier, StateNotifierProvider;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../auth/presentation/controllers/app_auth_provider.dart';
import '../../data/repositories/trip_repository_impl.dart';
import '../../domain/models/trip_leg_model.dart';
import '../../domain/models/trip_models.dart';
import '../../domain/repositories/trip_repository.dart';

part 'trips_provider.g.dart';

@riverpod
class Trips extends _$Trips {
  @override
  Future<List<TripModel>> build() async {
    ref.watch(authSessionRevisionProvider);
    final repo = ref.watch(tripRepositoryProvider);
    return repo.getTrips();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(tripRepositoryProvider);
      return repo.getTrips();
    });
  }

  Future<void> createTrip(
    String name,
    String? description,
    String? baseCurrency,
  ) async {
    final repo = ref.read(tripRepositoryProvider);
    await repo.createTrip(name, description, baseCurrency);
    ref.invalidateSelf();
    await future;
  }

  Future<TripCreationResult> createTripDraft(TripCreationDraft draft) async {
    final repo = ref.read(tripRepositoryProvider);
    final result = await repo.createTripDraft(draft);
    ref.invalidateSelf();
    return result;
  }

  Future<void> joinTrip(String inviteCode, String? nickName) async {
    final repo = ref.read(tripRepositoryProvider);
    await repo.joinTrip(inviteCode, nickName);
    ref.invalidateSelf();
    await future;
  }

  Future<void> deleteTrip(String tripId) async {
    final repo = ref.read(tripRepositoryProvider);
    await repo.deleteTrip(tripId);
    ref.invalidateSelf();
    await future;
  }
}

/// Updates a trip's start/end dates (e.g. when an added event falls outside
/// the current range). Refreshes the trip detail + list so the day plan and
/// date labels reflect the new range.
final updateTripDatesProvider = Provider((ref) => _UpdateTripDates(ref));

class _UpdateTripDates {
  final Ref _ref;
  _UpdateTripDates(this._ref);

  Future<void> call(
    String tripId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final repo = _ref.read(tripRepositoryProvider);
    await repo.updateTripDates(
      tripId,
      startDate: startDate,
      endDate: endDate,
    );
    _ref.invalidate(tripDetailsProvider(tripId));
    _ref.invalidate(tripsProvider);
  }
}

final tripDetailsProvider =
    FutureProvider.family<TripDetailModel, String>((ref, tripId) async {
  ref.watch(authSessionRevisionProvider);
  final repo = ref.watch(tripRepositoryProvider);
  return repo.getTrip(tripId);
});

final tripFilesProvider =
    FutureProvider.family<List<TripFileModel>, String>((ref, tripId) async {
  ref.watch(authSessionRevisionProvider);
  final repo = ref.watch(tripRepositoryProvider);
  return repo.getTripFiles(tripId);
});

/// Legs (segments) of a multi-stop trip, ordered.
final tripLegsProvider =
    FutureProvider.family<List<TripLegModel>, String>((ref, tripId) async {
  ref.watch(authSessionRevisionProvider);
  final repo = ref.watch(tripRepositoryProvider);
  return repo.getLegs(tripId);
});

/// Mutations for trip legs (add/delete), invalidating the legs list after.
final tripLegsActionsProvider = Provider((ref) => _TripLegsActions(ref));

class _TripLegsActions {
  final Ref _ref;
  _TripLegsActions(this._ref);

  Future<void> add(
    String tripId, {
    required String name,
    String? destinationCity,
    DateTime? startDate,
    DateTime? endDate,
    String? notes,
  }) async {
    final repo = _ref.read(tripRepositoryProvider);
    await repo.addLeg(
      tripId,
      name: name,
      destinationCity: destinationCity,
      startDate: startDate,
      endDate: endDate,
      notes: notes,
    );
    _ref.invalidate(tripLegsProvider(tripId));
  }

  Future<void> delete(String tripId, String legId) async {
    final repo = _ref.read(tripRepositoryProvider);
    await repo.deleteLeg(tripId, legId);
    _ref.invalidate(tripLegsProvider(tripId));
  }
}

class TripCoverMemory extends StateNotifier<Map<String, Uint8List>> {
  TripCoverMemory() : super(const {});

  void setCover(String tripId, Uint8List bytes) {
    if (tripId.isEmpty) return;
    state = {...state, tripId: bytes};
  }

  Uint8List? coverFor(String tripId) => state[tripId];
}

final tripCoverMemoryProvider =
    StateNotifierProvider<TripCoverMemory, Map<String, Uint8List>>(
  (ref) {
    ref.watch(authSessionRevisionProvider);
    return TripCoverMemory();
  },
);

class TripCoverUploadStatus {
  final bool isUploading;
  final String? errorMessage;

  const TripCoverUploadStatus({
    required this.isUploading,
    this.errorMessage,
  });
}

class TripCoverUploads
    extends StateNotifier<Map<String, TripCoverUploadStatus>> {
  final TripRepository _repository;
  final Ref _ref;

  TripCoverUploads(this._repository, this._ref) : super(const {});

  Future<void> upload({
    required String tripId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    state = {
      ...state,
      tripId: const TripCoverUploadStatus(isUploading: true),
    };

    try {
      await _repository.uploadTripCover(
        tripId,
        fileBytes: bytes,
        fileName: fileName,
      );
      final next = {...state}..remove(tripId);
      state = next;
      _ref.invalidate(tripsProvider);
    } catch (error) {
      state = {
        ...state,
        tripId: TripCoverUploadStatus(
          isUploading: false,
          errorMessage: error.toString().replaceAll('ApiException: ', ''),
        ),
      };
    }
  }
}

final tripCoverUploadProvider =
    StateNotifierProvider<TripCoverUploads, Map<String, TripCoverUploadStatus>>(
        (ref) {
  return TripCoverUploads(ref.watch(tripRepositoryProvider), ref);
});
