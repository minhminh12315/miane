import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../../data/repositories/auth_repository_impl.dart';

part 'app_auth_provider.g.dart';

enum AppAuthStatus {
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
    return AppAuthStatus.welcome;
  }

  Future<void> _checkInitialState() async {
    try {
      final repo = ref.read(authRepositoryProvider);
      final token = await repo.getToken();
      if (token != null && token.isNotEmpty) {
        state = AppAuthStatus.authenticated;
      }
    } catch (_) {}
  }

  void completeWelcome() {
    state = AppAuthStatus.unauthenticated;
  }

  Future<void> login(String email, String password) async {
    final repo = ref.read(authRepositoryProvider);
    await repo.login(email, password);
    state = AppAuthStatus.authenticated;
  }

  Future<void> register(String email, String password, String fullName) async {
    final repo = ref.read(authRepositoryProvider);
    await repo.register(email, password, fullName);
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
    final repo = ref.read(authRepositoryProvider);
    await repo.logout();
    state = AppAuthStatus.unauthenticated;
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


