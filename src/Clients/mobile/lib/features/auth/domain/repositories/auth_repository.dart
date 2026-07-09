import '../models/auth_models.dart';

abstract class AuthRepository {
  Future<AuthResponseModel> login(String email, String password);
  Future<AuthResponseModel> register(String email, String password, String fullName);
  Future<AuthResponseModel> loginWithGoogle(String idToken);
  Future<void> logout();
  Future<UserModel?> getMe();
  Future<void> saveToken(String accessToken, String refreshToken);
  Future<String?> getToken();
  Future<void> clearSession();
}
