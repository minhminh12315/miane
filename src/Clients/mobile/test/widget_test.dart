import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';
import 'package:mobile/features/auth/presentation/screens/welcome_flow_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('WelcomeFlowScreen renders on Deep Abyss canvas', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MianeApp());
    await tester.pump();

    expect(find.byType(WelcomeFlowScreen), findsOneWidget);
    expect(find.byType(PageView), findsNothing);

    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(PageView), findsNothing);

    await tester.pump(const Duration(milliseconds: 6200));
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.byType(PageView), findsOneWidget);
  });
}
