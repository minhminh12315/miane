import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../auth/presentation/controllers/app_auth_provider.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../domain/models/notification_feed.dart';

part 'notification_controller.g.dart';

const _pollInterval = Duration(seconds: 15);

@riverpod
class Notifications extends _$Notifications {
  Timer? _pollTimer;
  String? _latestId;
  int _unreadCount = 0;

  @override
  Future<NotificationFeed> build() async {
    ref.watch(authSessionRevisionProvider);
    ref.onDispose(() => _pollTimer?.cancel());

    final feed = await _loadFeed();
    _rememberSnapshot(feed);
    _startPolling();

    return feed;
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final feed = await _loadFeed();
      _rememberSnapshot(feed);
      return feed;
    });
  }

  Future<void> read(String id) async {
    final repo = ref.read(notificationRepositoryProvider);
    await repo.markAsRead(id);
    ref.invalidateSelf();
    await future;
  }

  Future<void> readAll() async {
    final repo = ref.read(notificationRepositoryProvider);
    await repo.markAllAsRead();
    ref.invalidateSelf();
    await future;
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _pollForUpdates());
  }

  Future<void> _pollForUpdates() async {
    if (!ref.mounted) return;

    try {
      final feed = await _loadFeed();
      if (!_hasChanges(feed)) return;

      _rememberSnapshot(feed);
      state = AsyncValue.data(feed);
    } catch (_) {
      // Keep showing the last successful snapshot while polling retries.
    }
  }

  Future<NotificationFeed> _loadFeed() async {
    final repo = ref.read(notificationRepositoryProvider);
    return repo.getNotifications();
  }

  void _rememberSnapshot(NotificationFeed feed) {
    _latestId = feed.latestId;
    _unreadCount = feed.unreadCount;
  }

  bool _hasChanges(NotificationFeed feed) {
    if (feed.latestId != _latestId) return true;
    if (feed.unreadCount != _unreadCount) return true;
    if (feed.notifications.length !=
        (state.valueOrNull?.notifications.length ?? 0)) {
      return true;
    }
    return false;
  }
}

@riverpod
int notificationUnreadCount(NotificationUnreadCountRef ref) {
  return ref.watch(notificationsProvider).valueOrNull?.unreadCount ?? 0;
}
