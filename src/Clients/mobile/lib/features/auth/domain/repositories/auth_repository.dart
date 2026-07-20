import '../models/auth_models.dart';

abstract class AuthRepository {
  Future<AuthResponseModel> login(String email, String password);
  Future<AuthResponseModel> register(
      String email, String password, String fullName);
  Future<void> sendRegistrationOtp(
      String email, String password, String fullName);
  Future<AuthResponseModel> verifyRegistrationOtp(String email, String otpCode);
  Future<void> sendPasswordResetOtp(String email);
  Future<void> resetPassword({
    required String email,
    required String otpCode,
    required String newPassword,
  });
  Future<void> logout();
  Future<AuthResponseModel> upgradeToPro();
  Future<AuthResponseModel> loginWithGoogle(String idToken);
  Future<bool> restoreSession();
  Future<UserModel?> getMe();
  Future<UserModel> updateMe({
    required String fullName,
    String? avatarUrl,
  });
  Future<UserModel> uploadAvatar({
    required List<int> fileBytes,
    required String fileName,
  });
  Future<void> saveToken(String accessToken, String refreshToken);
  Future<String?> getToken();
  Future<void> clearSession();
}
