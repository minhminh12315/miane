import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';
import 'package:mobile/features/auth/presentation/screens/welcome_flow_screen.dart';

void main() {
  testWidgets('WelcomeFlowScreen renders on Deep Abyss canvas', (tester) async {
    await tester.pumpWidget(const MianeApp());
    expect(find.byType(WelcomeFlowScreen), findsOneWidget);
  });
}
