import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart'
    show StateNotifier, StateNotifierProvider;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/repositories/trip_repository_impl.dart';
import '../../domain/models/trip_models.dart';

part 'trips_provider.g.dart';

@riverpod
class Trips extends _$Trips {
  @override
  Future<List<TripModel>> build() async {
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
    await future;
    return result;
  }

  Future<void> joinTrip(String inviteCode, String? nickName) async {
    final repo = ref.read(tripRepositoryProvider);
    await repo.joinTrip(inviteCode, nickName);
    ref.invalidateSelf();
    await future;
  }
}

final tripDetailsProvider =
    FutureProvider.family<TripDetailModel, String>((ref, tripId) async {
  final repo = ref.watch(tripRepositoryProvider);
  return repo.getTrip(tripId);
});

final tripFilesProvider =
    FutureProvider.family<List<TripFileModel>, String>((ref, tripId) async {
  final repo = ref.watch(tripRepositoryProvider);
  return repo.getTripFiles(tripId);
});

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
  (ref) => TripCoverMemory(),
);
