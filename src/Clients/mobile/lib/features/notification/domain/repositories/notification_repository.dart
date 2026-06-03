import '../models/notification_model.dart';

abstract class NotificationRepository {
  Future<List<NotificationModel>> getNotifications();
  Future<void> markAsRead(String id);
  Future<void> markAllAsRead();
}
