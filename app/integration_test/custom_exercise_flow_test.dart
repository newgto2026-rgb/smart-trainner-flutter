import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:smart_trainner_flutter/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('custom exercise add flow', (tester) async {
    await tester.pumpWidget(const SmartTrainnerApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('training_tab_exercises')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('training_add_custom_exercise_button')),
    );
    await tester.pumpAndSettle();

    await _enterTextInCustomForm(
      tester,
      'training_custom_exercise_name_input',
      'Custom Hinge',
    );
    await _selectDropdown(
      tester,
      dropdownKey: 'training_custom_exercise_muscle_group_dropdown',
      optionKey: 'training_custom_exercise_muscle_group_option_lowerBody',
    );
    await _selectDropdown(
      tester,
      dropdownKey: 'training_custom_exercise_equipment_dropdown',
      optionKey: 'training_custom_exercise_equipment_option_dumbbell',
    );
    await _selectDropdown(
      tester,
      dropdownKey: 'training_custom_exercise_difficulty_dropdown',
      optionKey: 'training_custom_exercise_difficulty_option_beginner',
    );
    await _enterTextInCustomForm(
      tester,
      'training_custom_exercise_summary_input',
      'A custom posterior-chain movement.',
    );
    await _enterTextInCustomForm(
      tester,
      'training_custom_exercise_instructions_input',
      'Hinge at the hips.\nStand tall.',
    );
    await _enterTextInCustomForm(
      tester,
      'training_custom_exercise_safety_input',
      'Keep the spine neutral.',
    );

    await _scrollUntilVisible(tester, 'training_custom_exercise_save_button');
    await tester.tap(
      find.byKey(const Key('training_custom_exercise_save_button')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('training_custom_exercise_saved_owner_message')),
      findsOneWidget,
    );
  });
}

Future<void> _enterTextInCustomForm(
  WidgetTester tester,
  String key,
  String text,
) async {
  final finder = await _scrollUntilVisible(tester, key);
  await tester.tap(finder.hitTestable());
  await tester.pumpAndSettle();
  tester.testTextInput.enterText(text);
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pumpAndSettle();
}

Future<void> _selectDropdown(
  WidgetTester tester, {
  required String dropdownKey,
  required String optionKey,
}) async {
  final dropdown = await _scrollUntilVisible(tester, dropdownKey);
  await tester.tap(dropdown.hitTestable());
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(Key(optionKey)).last);
  await tester.pumpAndSettle();
}

Future<Finder> _scrollUntilVisible(WidgetTester tester, String key) async {
  final finder = find.byKey(Key(key));
  for (
    var attempt = 0;
    attempt < 16 && finder.hitTestable().evaluate().isEmpty;
    attempt++
  ) {
    await tester.drag(
      find.byKey(const Key('training_custom_exercise_form_scroll')),
      const Offset(0, -320),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
  }
  expect(finder, findsOneWidget);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  expect(finder.hitTestable(), findsOneWidget);
  return finder;
}
