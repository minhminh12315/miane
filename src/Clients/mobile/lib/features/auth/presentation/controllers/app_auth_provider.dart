import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../../data/repositories/auth_repository_impl.dart';

part 'app_auth_provider.g.dart';

enum AppAuthStatus {
  initializing,
  welcome,
  unauthenticated,
  needsSetup,
  authenticated,
}

@riverpod
class AppAuth extends _$AppAuth {
  @override
  AppAuthStatus build() {
    _checkInitialState();
    return AppAuthStatus.initializing;
  }

  Future<void> _checkInitialState() async {
    try {
      final repo = ref.read(authRepositoryProvider);
      final token = await repo.getToken();
      if (token != null && token.isNotEmpty) {
        state = AppAuthStatus.authenticated;
      } else {
        state = AppAuthStatus.welcome;
      }
    } catch (_) {
      state = AppAuthStatus.welcome;
    }
  }

  void completeWelcome() {
    state = AppAuthStatus.unauthenticated;
  }

  Future<void> login(String email, String password) async {
    final repo = ref.read(authRepositoryProvider);
    await repo.login(email, password);
    state = AppAuthStatus.authenticated;
  }

  Future<void> loginWithGoogle(String idToken) async {
    final repo = ref.read(authRepositoryProvider);
    await repo.loginWithGoogle(idToken);
    state = AppAuthStatus.authenticated;
  }

  Future<void> register(String email, String password, String fullName) async {
    final repo = ref.read(authRepositoryProvider);
    await repo.register(email, password, fullName);
    state = AppAuthStatus.authenticated;
  }

  /// Phase 1: Send OTP to email. Does NOT create the account yet.
  Future<void> sendRegistrationOtp(
      String email, String password, String fullName) async {
    final repo = ref.read(authRepositoryProvider);
    await repo.sendRegistrationOtp(email, password, fullName);
  }

  /// Phase 2: Verify OTP and create the account.
  Future<void> verifyRegistrationOtp(String email, String otpCode) async {
    final repo = ref.read(authRepositoryProvider);
    await repo.verifyRegistrationOtp(email, otpCode);
    state = AppAuthStatus.authenticated;
  }

  void completeSetup() {
    state = AppAuthStatus.authenticated;
  }

  Future<void> loginFake() async {
    // For quick testing and social bypass
    state = AppAuthStatus.authenticated;
  }

  Future<void> logout() async {
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.logout();
    } catch (_) {
      // Ignore errors on logout to ensure user can still sign out locally
    } finally {
      state = AppAuthStatus.unauthenticated;
    }
  }
}

final currentUserIdProvider = FutureProvider<String?>((ref) async {
  final repo = ref.watch(authRepositoryProvider);
  final token = await repo.getToken();
  if (token != null && token.isNotEmpty) {
    try {
      final decoded = JwtDecoder.decode(token);
      return decoded['sub'] as String? ?? decoded['nameid'] as String?;
    } catch (_) {}
  }
  return null;
});

/// 0 = Basic, 1 = Pro. Decoded from the JWT's `UserTier` claim — invalidate
/// this provider after any call that reissues tokens (login, upgrade-pro).
final currentUserTierProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(authRepositoryProvider);
  final token = await repo.getToken();
  if (token != null && token.isNotEmpty) {
    try {
      final decoded = JwtDecoder.decode(token);
      return int.tryParse(decoded['UserTier'].toString()) ?? 0;
    } catch (_) {}
  }
  return 0;
});
