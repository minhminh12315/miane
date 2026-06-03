class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String eventType;
  final DateTime sentAt;
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.eventType,
    required this.sentAt,
    required this.isRead,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      eventType: json['eventType'] as String? ?? '',
      sentAt: json['sentAt'] != null
          ? DateTime.parse(json['sentAt'] as String)
          : DateTime.now(),
      isRead: json['isRead'] as bool? ?? false,
    );
  }
}
