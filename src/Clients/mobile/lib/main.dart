import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/auth/presentation/controllers/app_auth_provider.dart';
import 'features/auth/presentation/screens/welcome_flow_screen.dart';
import 'features/auth/presentation/screens/auth_gate_screen.dart';
import 'features/user_profile/presentation/screens/initial_setup_screen.dart';
import 'features/home/presentation/screens/main_layout_screen.dart';

import 'core/theme/app_theme.dart';

void main() {
  runApp(const MianeApp());
}

class MianeApp extends StatelessWidget {
  const MianeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        title: 'MIANE',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppTheme.iosBlue,
            primary: AppTheme.iosBlue,
            secondary: AppTheme.iosIndigo,
            surface: AppTheme.surfaceDark,
          ),
          scaffoldBackgroundColor: AppTheme.canvasDark,
        ),
        home: Consumer(
          builder: (context, ref, child) {
            ref.listen<AppAuthStatus>(appAuthProvider, (previous, next) {
              if (next == AppAuthStatus.unauthenticated || next == AppAuthStatus.welcome) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            });
            
            final authStatus = ref.watch(appAuthProvider);
            switch (authStatus) {
              case AppAuthStatus.welcome:
                return const WelcomeFlowScreen();
              case AppAuthStatus.unauthenticated:
                return const AuthGateScreen();
              case AppAuthStatus.needsSetup:
                return const InitialSetupScreen();
              case AppAuthStatus.authenticated:
                return const MainLayoutScreen();
            }
          },
        ),
      ),
    );
  }
}
