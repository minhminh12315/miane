import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/notification_repository_impl.dart';
import '../../data/services/push_notification_service.dart';

final pushNotificationServiceProvider =
    Provider<PushNotificationService>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return PushNotificationService(repository);
});

final pushNotificationSettingsProvider = StateNotifierProvider<
    PushNotificationSettingsController,
    AsyncValue<PushNotificationPreference>>((ref) {
  final service = ref.watch(pushNotificationServiceProvider);
  return PushNotificationSettingsController(service);
});

class PushNotificationSettingsController
    extends StateNotifier<AsyncValue<PushNotificationPreference>> {
  final PushNotificationService _service;

  PushNotificationSettingsController(this._service)
      : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = await AsyncValue.guard(_service.loadPreference);
  }

  Future<void> setEnabled(bool enabled) async {
    final previous = state.valueOrNull ?? await _service.loadPreference();
    state = AsyncValue.data(
      previous.copyWith(busy: true, clearError: true),
    );

    try {
      final next = enabled ? await _service.enable() : await _service.disable();
      state = AsyncValue.data(next);
    } catch (error) {
      state = AsyncValue.data(
        previous.copyWith(
          busy: false,
          errorMessage: error.toString(),
        ),
      );
      rethrow;
    }
  }

  Future<void> syncWithCurrentPreference() async {
    try {
      state = AsyncValue.data(await _service.syncEnabledDevice());
    } catch (_) {
      await load();
    }
  }

  Future<void> disableBestEffort() async {
    state = AsyncValue.data(await _service.disableBestEffort());
  }
}
