import 'package:jwt_decoder/jwt_decoder.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/token_store.dart';
import '../../domain/models/auth_models.dart';
import '../../domain/repositories/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient _apiClient;

  AuthRepositoryImpl(this._apiClient);

  @override
  Future<AuthResponseModel> login(String email, String password) async {
    final response = await _apiClient.post(
      ApiEndpoints.login,
      body: {'email': email, 'password': password},
      authenticated: false,
    );
    final authResponse = AuthResponseModel.fromJson(response);
    await saveToken(authResponse.accessToken, authResponse.refreshToken);
    return authResponse;
  }

  @override
  Future<AuthResponseModel> register(
      String email, String password, String fullName) async {
    final response = await _apiClient.post(
      ApiEndpoints.register,
      body: {
        'email': email,
        'password': password,
        'fullName': fullName,
      },
      authenticated: false,
    );
    final authResponse = AuthResponseModel.fromJson(response);
    await saveToken(authResponse.accessToken, authResponse.refreshToken);
    return authResponse;
  }

  @override
  Future<void> sendRegistrationOtp(
      String email, String password, String fullName) async {
    await _apiClient.post(
      ApiEndpoints.sendRegistrationOtp,
      body: {
        'email': email,
        'password': password,
        'fullName': fullName,
      },
      authenticated: false,
    );
  }

  @override
  Future<AuthResponseModel> verifyRegistrationOtp(
      String email, String otpCode) async {
    final response = await _apiClient.post(
      ApiEndpoints.verifyRegistrationOtp,
      body: {
        'email': email,
        'otpCode': otpCode,
      },
      authenticated: false,
    );
    final authResponse = AuthResponseModel.fromJson(response);
    await saveToken(authResponse.accessToken, authResponse.refreshToken);
    return authResponse;
  }

  @override
  Future<void> sendPasswordResetOtp(String email) async {
    await _apiClient.post(
      ApiEndpoints.forgotPassword,
      body: {'email': email},
      authenticated: false,
    );
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String otpCode,
    required String newPassword,
  }) async {
    await _apiClient.post(
      ApiEndpoints.resetPassword,
      body: {
        'email': email,
        'otpCode': otpCode,
        'newPassword': newPassword,
      },
      authenticated: false,
    );
  }

  @override
  Future<AuthResponseModel> upgradeToPro({
    required String platform,
    required String receiptData,
    String? productId,
    String? transactionId,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.upgradePro,
      body: {
        'platform': platform,
        'receiptData': receiptData,
        'productId': productId,
        'transactionId': transactionId,
      },
    );
    final authResponse = AuthResponseModel.fromJson(response);
    await saveToken(authResponse.accessToken, authResponse.refreshToken);
    return authResponse;
  }

  @override
  Future<AuthResponseModel> loginWithGoogle(String idToken) async {
    final response = await _apiClient.post(
      ApiEndpoints.googleLogin,
      body: {'idToken': idToken},
      authenticated: false,
    );
    final authResponse = AuthResponseModel.fromJson(response);
    await saveToken(authResponse.accessToken, authResponse.refreshToken);
    return authResponse;
  }

  @override
  Future<void> logout() async {
    try {
      await _apiClient.post(ApiEndpoints.logout);
    } catch (_) {}
    await clearSession();
  }

  @override
  Future<bool> restoreSession() async {
    final token = await getToken();
    if (token == null || token.isEmpty) return false;

    try {
      if (!JwtDecoder.isExpired(token)) return true;
      final restored = await _apiClient.refreshSession();
      if (!restored) await clearSession();
      return restored;
    } catch (_) {
      await clearSession();
      return false;
    }
  }

  @override
  Future<UserModel?> getMe() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.me);
      if (response != null) {
        return UserModel.fromJson(response);
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<UserModel> updateMe({
    required String fullName,
    String? avatarUrl,
  }) async {
    final response = await _apiClient.put(
      ApiEndpoints.me,
      body: {
        'fullName': fullName,
        'avatarUrl': avatarUrl,
      },
    );
    return UserModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<UserModel> uploadAvatar({
    required List<int> fileBytes,
    required String fileName,
  }) async {
    final response = await _apiClient.postMultipart(
      ApiEndpoints.uploadAvatar,
      fileBytes: fileBytes,
      fileName: fileName,
    );
    return UserModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<void> saveToken(String accessToken, String refreshToken) async {
    if (accessToken.isEmpty || refreshToken.isEmpty) {
      throw StateError('Cannot save empty auth tokens.');
    }
    await TokenStore.save(accessToken, refreshToken);
  }

  @override
  Future<String?> getToken() async {
    return TokenStore.getAccessToken();
  }

  @override
  Future<void> clearSession() async {
    await TokenStore.clear();
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRepositoryImpl(apiClient);
});
