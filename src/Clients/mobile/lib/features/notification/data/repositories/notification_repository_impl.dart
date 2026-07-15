import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/models/notification_model.dart';
import '../../domain/repositories/notification_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final ApiClient _apiClient;

  NotificationRepositoryImpl(this._apiClient);

  @override
  Future<List<NotificationModel>> getNotifications() async {
    final response = await _apiClient.get(ApiEndpoints.notifications);
    if (response is Map && response.containsKey('notifications')) {
      final list = response['notifications'] as List;
      return list.map((json) => NotificationModel.fromJson(json)).toList();
    }
    return [];
  }

  @override
  Future<void> markAsRead(String id) async {
    await _apiClient.put('${ApiEndpoints.notifications}/$id/read');
  }

  @override
  Future<void> markAllAsRead() async {
    await _apiClient.put('${ApiEndpoints.notifications}/read-all');
  }

  @override
  Future<void> registerDevice({
    required String fcmToken,
    required String platform,
  }) async {
    await _apiClient.post(
      ApiEndpoints.registerNotificationDevice,
      body: {
        'fcmToken': fcmToken,
        'platform': platform,
      },
    );
  }

  @override
  Future<void> unregisterDevice(String fcmToken) async {
    await _apiClient.delete(ApiEndpoints.notificationDevice(fcmToken));
  }
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return NotificationRepositoryImpl(apiClient);
});
