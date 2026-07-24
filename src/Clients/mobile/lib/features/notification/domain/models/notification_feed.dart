import 'notification_model.dart';

class NotificationFeed {
  final List<NotificationModel> notifications;
  final int unreadCount;

  const NotificationFeed({
    required this.notifications,
    required this.unreadCount,
  });

  String? get latestId =>
      notifications.isEmpty ? null : notifications.first.id;
}
