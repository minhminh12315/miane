import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/firebase/firebase_push_config.dart';
import '../../domain/repositories/notification_repository.dart';

class PushNotificationPreference {
  final bool enabled;
  final bool configured;
  final bool supported;
  final bool busy;
  final String? token;
  final String? errorMessage;

  const PushNotificationPreference({
    required this.enabled,
    required this.configured,
    required this.supported,
    this.busy = false,
    this.token,
    this.errorMessage,
  });

  bool get canToggle => configured && supported && !busy;

  String get subtitle {
    if (!configured) {
      return 'Chưa cấu hình Firebase push.';
    }
    if (!supported) {
      return 'Thiết bị hoặc trình duyệt chưa hỗ trợ.';
    }
    if (busy) {
      return 'Đang cập nhật...';
    }
    if (errorMessage != null && errorMessage!.isNotEmpty) {
      return errorMessage!;
    }
    return enabled ? 'Đang nhận thông báo.' : 'Đang tắt.';
  }

  PushNotificationPreference copyWith({
    bool? enabled,
    bool? configured,
    bool? supported,
    bool? busy,
    String? token,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PushNotificationPreference(
      enabled: enabled ?? this.enabled,
      configured: configured ?? this.configured,
      supported: supported ?? this.supported,
      busy: busy ?? this.busy,
      token: token ?? this.token,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class PushNotificationUnavailableException implements Exception {
  final String message;

  const PushNotificationUnavailableException(this.message);

  @override
  String toString() => message;
}

class PushNotificationService {
  static const String _enabledKey = 'push_notifications_enabled';
  static const String _tokenKey = 'push_notifications_fcm_token';
  static const int _apnsTokenRetryCount = 12;
  static const Duration _apnsTokenRetryDelay = Duration(milliseconds: 500);

  final NotificationRepository _notificationRepository;
  StreamSubscription<String>? _tokenRefreshSubscription;
  bool _initialized = false;

  PushNotificationService(this._notificationRepository);

  Future<PushNotificationPreference> loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final configured = FirebasePushConfig.hasPushOptions;
    final supported = configured ? await _isSupported() : false;
    final enabled = prefs.getBool(_enabledKey) ?? false;

    return PushNotificationPreference(
      enabled: enabled && configured && supported,
      configured: configured,
      supported: supported,
      token: prefs.getString(_tokenKey),
    );
  }

  Future<PushNotificationPreference> enable() async {
    await _ensureAvailable();

    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (!_isPermissionGranted(settings.authorizationStatus)) {
      throw const PushNotificationUnavailableException(
        'Bạn chưa cấp quyền nhận thông báo.',
      );
    }

    final token = await _getFcmToken();
    if (token == null || token.isEmpty) {
      throw const PushNotificationUnavailableException(
        'Firebase chưa trả về FCM token.',
      );
    }

    await _notificationRepository.registerDevice(
      fcmToken: token,
      platform: _platformName,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, true);
    await prefs.setString(_tokenKey, token);

    return PushNotificationPreference(
      enabled: true,
      configured: true,
      supported: true,
      token: token,
    );
  }

  Future<PushNotificationPreference> disable() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);

    if (token != null && token.isNotEmpty) {
      await _notificationRepository.unregisterDevice(token);
    }

    await _deleteFirebaseTokenIfAvailable();
    await prefs.setBool(_enabledKey, false);
    await prefs.remove(_tokenKey);

    final configured = FirebasePushConfig.hasPushOptions;
    final supported = configured ? await _isSupported() : false;
    return PushNotificationPreference(
      enabled: false,
      configured: configured,
      supported: supported,
    );
  }

  Future<PushNotificationPreference> disableBestEffort() async {
    try {
      return await disable();
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_enabledKey, false);
      await prefs.remove(_tokenKey);
      return PushNotificationPreference(
        enabled: false,
        configured: FirebasePushConfig.hasPushOptions,
        supported: false,
      );
    }
  }

  Future<PushNotificationPreference> syncEnabledDevice() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_enabledKey) ?? false;
    if (!enabled) {
      return loadPreference();
    }

    await _ensureAvailable();
    final token = await _getFcmToken();
    if (token == null || token.isEmpty) {
      return loadPreference();
    }

    await _notificationRepository.registerDevice(
      fcmToken: token,
      platform: _platformName,
    );
    await prefs.setString(_tokenKey, token);

    return PushNotificationPreference(
      enabled: true,
      configured: true,
      supported: true,
      token: token,
    );
  }

  Future<void> _ensureAvailable() async {
    if (!FirebasePushConfig.hasPushOptions) {
      throw const PushNotificationUnavailableException(
        'Thiếu cấu hình Firebase push.',
      );
    }

    await _ensureInitialized();
    if (!await FirebaseMessaging.instance.isSupported()) {
      throw const PushNotificationUnavailableException(
        'Thiết bị hoặc trình duyệt chưa hỗ trợ push notification.',
      );
    }
  }

  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: FirebasePushConfig.options);
    }

    await _configureAppleForegroundPresentation();

    _tokenRefreshSubscription ??=
        FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_enabledKey) != true) return;

      await _notificationRepository.registerDevice(
        fcmToken: token,
        platform: _platformName,
      );
      await prefs.setString(_tokenKey, token);
    });

    _initialized = true;
  }

  Future<String?> _getFcmToken() async {
    await _ensureAppleApnsTokenIfNeeded();

    return FirebaseMessaging.instance.getToken(
      vapidKey: kIsWeb ? FirebasePushConfig.webVapidKey : null,
    );
  }

  Future<void> _ensureAppleApnsTokenIfNeeded() async {
    if (!_isApplePlatform) return;

    for (var attempt = 0; attempt < _apnsTokenRetryCount; attempt++) {
      final token = await FirebaseMessaging.instance.getAPNSToken();
      if (token != null && token.isNotEmpty) return;
      await Future<void>.delayed(_apnsTokenRetryDelay);
    }

    throw const PushNotificationUnavailableException(
      'iOS chưa nhận được APNs token. Hãy chạy trên iPhone thật và kiểm tra Push Notifications, Background Modes, APNs key trong Firebase.',
    );
  }

  Future<void> _configureAppleForegroundPresentation() async {
    if (!_isApplePlatform) return;

    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<bool> _isSupported() async {
    try {
      await _ensureInitialized();
      return FirebaseMessaging.instance.isSupported();
    } catch (_) {
      return false;
    }
  }

  Future<void> _deleteFirebaseTokenIfAvailable() async {
    try {
      if (!FirebasePushConfig.hasPushOptions) return;
      await _ensureInitialized();
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {
      // Local preference and backend opt-out are the source of truth.
    }
  }

  bool _isPermissionGranted(AuthorizationStatus status) =>
      status == AuthorizationStatus.authorized ||
      status == AuthorizationStatus.provisional;

  bool get _isApplePlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  String get _platformName {
    if (kIsWeb) return 'web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      TargetPlatform.macOS => 'macos',
      TargetPlatform.windows => 'windows',
      TargetPlatform.linux => 'linux',
      TargetPlatform.fuchsia => 'fuchsia',
    };
  }
}
