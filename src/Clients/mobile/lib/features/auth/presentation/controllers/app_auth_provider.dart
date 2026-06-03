import 'package:riverpod_annotation/riverpod_annotation.dart';

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
    return AppAuthStatus.welcome;
  }

  void completeWelcome() {
    state = AppAuthStatus.unauthenticated;
  }

  void loginFake() {
    state = AppAuthStatus.authenticated;
  }

  void registerFake() {
    state = AppAuthStatus.needsSetup;
  }

  void completeSetup() {
    state = AppAuthStatus.authenticated;
  }

  void logout() {
    state = AppAuthStatus.unauthenticated;
  }
}
