import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Access/refresh tokens live in platform secure storage (Keychain /
/// EncryptedSharedPreferences). Migrates once from legacy SharedPreferences.
class TokenStore {
  TokenStore._();

  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';

  static const FlutterSecureStorage _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static Future<void> save(String accessToken, String refreshToken) async {
    await _secure.write(key: _accessKey, value: accessToken);
    await _secure.write(key: _refreshKey, value: refreshToken);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessKey);
    await prefs.remove(_refreshKey);
  }

  static Future<String?> getAccessToken() async {
    await _migrateFromPrefsIfNeeded();
    return _secure.read(key: _accessKey);
  }

  static Future<String?> getRefreshToken() async {
    await _migrateFromPrefsIfNeeded();
    return _secure.read(key: _refreshKey);
  }

  static Future<void> clear() async {
    await _secure.delete(key: _accessKey);
    await _secure.delete(key: _refreshKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessKey);
    await prefs.remove(_refreshKey);
  }

  static Future<void> _migrateFromPrefsIfNeeded() async {
    final existing = await _secure.read(key: _accessKey);
    if (existing != null && existing.isNotEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final legacyAccess = prefs.getString(_accessKey);
    final legacyRefresh = prefs.getString(_refreshKey);
    if (legacyAccess != null &&
        legacyAccess.isNotEmpty &&
        legacyRefresh != null &&
        legacyRefresh.isNotEmpty) {
      await _secure.write(key: _accessKey, value: legacyAccess);
      await _secure.write(key: _refreshKey, value: legacyRefresh);
      await prefs.remove(_accessKey);
      await prefs.remove(_refreshKey);
    }
  }
}
