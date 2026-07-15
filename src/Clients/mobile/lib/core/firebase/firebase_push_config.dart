import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebasePushConfig {
  static const String webApiKey =
      String.fromEnvironment('FIREBASE_WEB_API_KEY');
  static const String webAuthDomain =
      String.fromEnvironment('FIREBASE_WEB_AUTH_DOMAIN');
  static const String webProjectId =
      String.fromEnvironment('FIREBASE_WEB_PROJECT_ID');
  static const String webStorageBucket =
      String.fromEnvironment('FIREBASE_WEB_STORAGE_BUCKET');
  static const String webMessagingSenderId =
      String.fromEnvironment('FIREBASE_WEB_MESSAGING_SENDER_ID');
  static const String webAppId = String.fromEnvironment('FIREBASE_WEB_APP_ID');
  static const String webMeasurementId =
      String.fromEnvironment('FIREBASE_WEB_MEASUREMENT_ID');
  static const String webVapidKey =
      String.fromEnvironment('FIREBASE_WEB_VAPID_KEY');

  static const String iosApiKey =
      String.fromEnvironment('FIREBASE_IOS_API_KEY');
  static const String iosProjectId =
      String.fromEnvironment('FIREBASE_IOS_PROJECT_ID');
  static const String iosStorageBucket =
      String.fromEnvironment('FIREBASE_IOS_STORAGE_BUCKET');
  static const String iosMessagingSenderId =
      String.fromEnvironment('FIREBASE_IOS_MESSAGING_SENDER_ID');
  static const String iosAppId = String.fromEnvironment('FIREBASE_IOS_APP_ID');
  static const String iosBundleId =
      String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID');
  static const String iosClientId =
      String.fromEnvironment('FIREBASE_IOS_CLIENT_ID');

  static bool get hasPushOptions {
    if (kIsWeb) return _hasWebOptions && webVapidKey.isNotEmpty;

    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS => _hasIosOptions,
      _ => false,
    };
  }

  static FirebaseOptions get options {
    if (kIsWeb) return _webOptions;

    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS => _iosOptions,
      _ => throw UnsupportedError(
          'Firebase push is only configured for web and iOS.',
        ),
    };
  }

  static bool get _hasWebOptions =>
      webApiKey.isNotEmpty &&
      webProjectId.isNotEmpty &&
      webMessagingSenderId.isNotEmpty &&
      webAppId.isNotEmpty;

  static bool get _hasIosOptions =>
      iosApiKey.isNotEmpty &&
      iosProjectId.isNotEmpty &&
      iosMessagingSenderId.isNotEmpty &&
      iosAppId.isNotEmpty &&
      iosBundleId.isNotEmpty;

  static FirebaseOptions get _webOptions => FirebaseOptions(
        apiKey: webApiKey,
        authDomain: webAuthDomain.isEmpty ? null : webAuthDomain,
        projectId: webProjectId,
        storageBucket: webStorageBucket.isEmpty ? null : webStorageBucket,
        messagingSenderId: webMessagingSenderId,
        appId: webAppId,
        measurementId: webMeasurementId.isEmpty ? null : webMeasurementId,
      );

  static FirebaseOptions get _iosOptions => FirebaseOptions(
        apiKey: iosApiKey,
        projectId: iosProjectId,
        storageBucket: iosStorageBucket.isEmpty ? null : iosStorageBucket,
        messagingSenderId: iosMessagingSenderId,
        appId: iosAppId,
        iosBundleId: iosBundleId,
        iosClientId: iosClientId.isEmpty ? null : iosClientId,
      );
}
