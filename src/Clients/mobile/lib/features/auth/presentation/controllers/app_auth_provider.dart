import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/models/auth_models.dart';
import '../../../notification/presentation/controllers/push_notification_controller.dart';

part 'app_auth_provider.g.dart';

enum AppAuthStatus {
  initializing,
  welcome,
  unauthenticated,
  needsSetup,
  authenticated,
}

/// Changes whenever the authenticated identity changes. User-scoped providers
/// watch this value so data from the previous account cannot survive a switch.
final authSessionRevisionProvider = StateProvider<int>((ref) => 0);

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
      if (await repo.restoreSession()) {
        _advanceSessionRevision();
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
    _completeAuthentication();
  }

  Future<void> loginWithGoogle(String idToken) async {
    final repo = ref.read(authRepositoryProvider);
    await repo.loginWithGoogle(idToken);
    _completeAuthentication();
  }

  Future<void> register(String email, String password, String fullName) async {
    final repo = ref.read(authRepositoryProvider);
    await repo.register(email, password, fullName);
    _completeAuthentication();
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
    _completeAuthentication();
  }

  void completeSetup() {
    state = AppAuthStatus.authenticated;
  }

  Future<void> logout() async {
    final repo = ref.read(authRepositoryProvider);
    try {
      await ref
          .read(pushNotificationSettingsProvider.notifier)
          .disableBestEffort();
    } catch (_) {
      // Push cleanup must never prevent auth cleanup.
    }
    try {
      await GoogleSignIn().signOut();
    } catch (_) {
      // The user may have authenticated by email instead of Google.
    }
    try {
      await repo.logout();
    } catch (_) {
      // Server logout is best effort; local credentials are authoritative.
    } finally {
      try {
        await repo.clearSession();
      } finally {
        _advanceSessionRevision();
        state = AppAuthStatus.unauthenticated;
      }
    }
  }

  void _completeAuthentication() {
    _advanceSessionRevision();
    state = AppAuthStatus.authenticated;
  }

  void _advanceSessionRevision() {
    ref.read(authSessionRevisionProvider.notifier).state++;
  }
}

final currentUserIdProvider = FutureProvider<String?>((ref) async {
  ref.watch(authSessionRevisionProvider);
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

final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  ref.watch(authSessionRevisionProvider);
  final repo = ref.watch(authRepositoryProvider);
  final user = await repo.getMe();
  if (user != null) return user;

  final token = await repo.getToken();
  if (token != null && token.isNotEmpty) {
    try {
      final decoded = JwtDecoder.decode(token);
      return UserModel(
        id: decoded['sub'] as String? ?? decoded['nameid'] as String? ?? '',
        email: decoded['email'] as String? ??
            decoded['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress']
                as String? ??
            '',
        fullName: decoded['FullName'] as String? ?? '',
        userTier: int.tryParse(decoded['UserTier']?.toString() ?? '') ?? 0,
      );
    } catch (_) {}
  }
  return null;
});

/// 0 = Basic, 1 = Pro. Decoded from the JWT's `UserTier` claim — invalidate
/// this provider after any call that reissues tokens (login, upgrade-pro).
final currentUserTierProvider = FutureProvider<int>((ref) async {
  ref.watch(authSessionRevisionProvider);
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
