import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/auth/domain/models/auth_models.dart';
import 'package:mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:mobile/features/auth/presentation/controllers/app_auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAuthRepository implements AuthRepository {
  bool loginGoogleCalled = false;
  String? passedToken;

  @override
  Future<AuthResponseModel> login(String email, String password) async {
    throw UnimplementedError();
  }

  @override
  Future<AuthResponseModel> register(String email, String password, String fullName) async {
    throw UnimplementedError();
  }

  @override
  Future<void> sendRegistrationOtp(String email, String password, String fullName) async {
    throw UnimplementedError();
  }

  @override
  Future<AuthResponseModel> verifyRegistrationOtp(String email, String otpCode) async {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() async {
    throw UnimplementedError();
  }

  @override
  Future<AuthResponseModel> upgradeToPro() async {
    throw UnimplementedError();
  }

  @override
  Future<AuthResponseModel> loginWithGoogle(String idToken) async {
    loginGoogleCalled = true;
    passedToken = idToken;
    return AuthResponseModel(
      accessToken: 'dummy_access_token',
      refreshToken: 'dummy_refresh_token',
      user: UserModel(id: '1', email: 'test@google.com', fullName: 'Google User'),
    );
  }

  @override
  Future<UserModel?> getMe() async => null;

  @override
  Future<void> saveToken(String accessToken, String refreshToken) async {}

  @override
  Future<String?> getToken() async => null;

  @override
  Future<void> clearSession() async {}
}

void main() {
  test('AppAuth loginWithGoogle action changes state and calls repository', () async {
    SharedPreferences.setMockInitialValues({});
    final mockRepo = MockAuthRepository();
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
    container.listen(appAuthProvider, (previous, next) {});

    // Initial state check
    expect(container.read(appAuthProvider), AppAuthStatus.initializing);
    
    // Pump microtasks to finish initial state check
    await Future.delayed(const Duration(milliseconds: 50));
    expect(container.read(appAuthProvider), AppAuthStatus.welcome);

    // Execute login with Google
    await container.read(appAuthProvider.notifier).loginWithGoogle('test_google_token');

    expect(mockRepo.loginGoogleCalled, true);
    expect(mockRepo.passedToken, 'test_google_token');
    expect(container.read(appAuthProvider), AppAuthStatus.authenticated);
  });
}
