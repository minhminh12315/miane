import '../models/notification_model.dart';

abstract class NotificationRepository {
  Future<List<NotificationModel>> getNotifications();
  Future<void> markAsRead(String id);
  Future<void> markAllAsRead();
  Future<void> registerDevice({
    required String fcmToken,
    required String platform,
  });
  Future<void> unregisterDevice(String fcmToken);
}
