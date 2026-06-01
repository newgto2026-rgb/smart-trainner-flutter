import 'package:flutter_test/flutter_test.dart';
import 'package:smart_trainner_flutter/main.dart';

void main() {
  testWidgets('app boots through the training feature entry', (tester) async {
    await tester.pumpWidget(const SmartTrainnerApp());

    expect(find.byType(SmartTrainnerApp), findsOneWidget);
  });
}
