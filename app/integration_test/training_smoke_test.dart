import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:smart_trainner_flutter/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('training app smoke test', (tester) async {
    await tester.pumpWidget(const SmartTrainnerApp());

    expect(find.byType(SmartTrainnerApp), findsOneWidget);
  });
}
