import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/presentation/screens/welcome_flow_screen.dart';
import 'package:mobile/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('WelcomeFlowScreen renders the iOS onboarding flow', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MianeApp());
    await tester.pump();

    expect(find.byType(WelcomeFlowScreen), findsOneWidget);
    expect(find.byType(PageView), findsOneWidget);
    expect(find.text('MIANE'), findsOneWidget);
    expect(find.text('Du lịch gọn hơn'), findsOneWidget);
    expect(find.widgetWithText(CupertinoButton, 'Tiếp tục'), findsOneWidget);
  });
}
