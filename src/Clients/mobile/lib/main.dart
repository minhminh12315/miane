import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/presentation/controllers/app_auth_provider.dart';
import 'features/auth/presentation/screens/auth_gate_screen.dart';
import 'features/auth/presentation/screens/welcome_flow_screen.dart';
import 'features/home/presentation/screens/main_layout_screen.dart';

void main() {
  runApp(const MianeApp());
}

class MianeApp extends StatelessWidget {
  const MianeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: CupertinoApp(
        title: 'MIANE',
        debugShowCheckedModeBanner: false,
        locale: const Locale('vi', 'VN'),
        supportedLocales: const [
          Locale('vi', 'VN'),
          Locale('en', 'US'),
        ],
        localizationsDelegates: const [
          GlobalCupertinoLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        theme: AppTheme.cupertinoTheme,
        home: Consumer(
          builder: (context, ref, child) {
            ref.listen<AppAuthStatus>(appAuthProvider, (previous, next) {
              if (next == AppAuthStatus.unauthenticated ||
                  next == AppAuthStatus.welcome) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            });

            final authStatus = ref.watch(appAuthProvider);
            switch (authStatus) {
              case AppAuthStatus.initializing:
                return const _AppBootSplash();
              case AppAuthStatus.welcome:
                return const WelcomeFlowScreen();
              case AppAuthStatus.unauthenticated:
                return const AuthGateScreen();
              case AppAuthStatus.authenticated:
                return const MainLayoutScreen();
            }
          },
        ),
      ),
    );
  }
}

class _AppBootSplash extends StatelessWidget {
  const _AppBootSplash();

  @override
  Widget build(BuildContext context) {
    return const CupertinoPageScaffold(
      backgroundColor: AppTheme.canvasDark,
      child: Center(
        child: CupertinoActivityIndicator(radius: 12),
      ),
    );
  }
}
