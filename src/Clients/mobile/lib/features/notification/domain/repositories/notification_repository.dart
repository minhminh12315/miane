import '../models/notification_feed.dart';

abstract class NotificationRepository {
  Future<NotificationFeed> getNotifications();
  Future<void> markAsRead(String id);
  Future<void> markAllAsRead();
}
