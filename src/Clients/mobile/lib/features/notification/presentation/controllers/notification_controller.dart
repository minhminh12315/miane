import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../auth/presentation/controllers/app_auth_provider.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../domain/models/notification_model.dart';

part 'notification_controller.g.dart';

@riverpod
class Notifications extends _$Notifications {
  @override
  Future<List<NotificationModel>> build() async {
    ref.watch(authSessionRevisionProvider);
    final repo = ref.watch(notificationRepositoryProvider);
    return repo.getNotifications();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(notificationRepositoryProvider);
      return repo.getNotifications();
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
}
