import 'package:flutter/material.dart';
import 'features/auth/presentation/screens/welcome_flow_screen.dart';

void main() {
  runApp(const MianeApp());
}

class MianeApp extends StatelessWidget {
  const MianeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MIANE',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D2C54),
          primary: const Color(0xFF0D2C54),
          secondary: const Color(0xFF4A90E2),
          surface: const Color(0xFF05101E),
        ),
        scaffoldBackgroundColor: const Color(0xFF05101E),
      ),
      home: const WelcomeFlowScreen(),
    );
  }
}
