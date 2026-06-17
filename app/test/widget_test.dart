import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_trainner_flutter/main.dart';

void main() {
  testWidgets('home shows today training and analysis tabs', (tester) async {
    await _pumpApp(tester);

    expect(find.byKey(const Key('training_app_title')), findsOneWidget);
    expect(
      find.byKey(const Key('training_section_title_training_today_title')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('training_tab_home')), findsOneWidget);
    expect(find.byKey(const Key('training_tab_analysis')), findsOneWidget);
    expect(find.byKey(const Key('training_tab_record')), findsNothing);
  });

  testWidgets('weekly summary only appears on analysis tab', (tester) async {
    await _pumpApp(tester);

    expect(find.byKey(const Key('training_summary_band')), findsNothing);

    await _tapTab(tester, 'training_tab_plan');
    expect(find.byKey(const Key('training_summary_band')), findsNothing);

    await _tapTab(tester, 'training_tab_exercises');
    expect(find.byKey(const Key('training_summary_band')), findsNothing);

    await _tapTab(tester, 'training_tab_analysis');
    expect(find.byKey(const Key('training_summary_band')), findsOneWidget);
  });

  testWidgets('exercise detail shows step images', (tester) async {
    await _pumpApp(tester);
    await _tapTab(tester, 'training_tab_exercises');

    await _scrollToAndTap(tester, 'training_exercise_row_romanian_deadlift');

    for (var index = 0; index < 5; index++) {
      await _scrollUntilVisible(tester, 'training_step_image_$index');
      expect(find.byKey(Key('training_step_image_$index')), findsOneWidget);
    }
    expect(find.byKey(const Key('training_step_image_5')), findsNothing);
  });

  testWidgets('machine shoulder press detail shows exactly three step images', (
    tester,
  ) async {
    await _pumpApp(tester);
    await _tapTab(tester, 'training_tab_exercises');

    await _scrollToAndTap(
      tester,
      'training_exercise_row_machine_shoulder_press',
    );

    for (var index = 0; index < 3; index++) {
      await _scrollUntilVisible(tester, 'training_step_image_$index');
      expect(find.byKey(Key('training_step_image_$index')), findsOneWidget);
    }
    expect(find.byKey(const Key('training_step_image_3')), findsNothing);
  });

  testWidgets('record flow saves workout', (tester) async {
    await _pumpApp(tester);
    await _tapTab(tester, 'training_tab_plan');

    await _scrollToAndTap(tester, 'training_plan_exercise_leg_press');
    expect(find.byKey(const Key('training_record_dialog')), findsOneWidget);
    expect(
      find.byKey(const Key('training_record_selected_exercise')),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const Key('training_set_reps_input_0')),
      '10',
    );
    await tester.enterText(
      find.byKey(const Key('training_set_weight_input_0')),
      '80',
    );
    await tester.enterText(
      find.byKey(const Key('training_set_weight_input_1')),
      '85',
    );
    await tester.tap(find.byKey(const Key('training_add_set_button')));
    await tester.pumpAndSettle();

    final dialogScrollable = find.byType(Scrollable).last;
    await _scrollUntilVisible(
      tester,
      'training_set_weight_input_3',
      scrollable: dialogScrollable,
    );
    await tester.enterText(
      find.byKey(const Key('training_set_weight_input_3')),
      '90',
    );
    await _scrollUntilVisible(
      tester,
      'training_save_record',
      scrollable: dialogScrollable,
    );
    await tester.tap(find.byKey(const Key('training_save_record')));
    await tester.pumpAndSettle();

    await _scrollUntilVisible(
      tester,
      'training_record_saved_message',
      scrollable: dialogScrollable,
    );
    expect(
      find.byKey(const Key('training_record_saved_message')),
      findsOneWidget,
    );
  });

  testWidgets('custom exercise flow saves a private owned exercise', (
    tester,
  ) async {
    await _pumpApp(tester);
    await _tapTab(tester, 'training_tab_exercises');

    await tester.tap(
      find.byKey(const Key('training_add_custom_exercise_button')),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('training_custom_exercise_name_input')),
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
    await tester.enterText(
      find.byKey(const Key('training_custom_exercise_summary_input')),
      'A custom posterior-chain movement.',
    );
    await tester.enterText(
      find.byKey(const Key('training_custom_exercise_instructions_input')),
      'Hinge at the hips.\nStand tall.',
    );
    await tester.enterText(
      find.byKey(const Key('training_custom_exercise_safety_input')),
      'Keep the spine neutral.',
    );

    await _scrollCustomFormUntilVisible(
      tester,
      'training_custom_exercise_save_button',
    );
    await tester.tap(
      find.byKey(const Key('training_custom_exercise_save_button')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('training_custom_exercise_saved_owner_message')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('training_exercise_source_badge_owned')),
      findsOneWidget,
    );

    await tester.tap(find.text('운동 목록'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('training_my_exercises_section')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const Key('training_exercise_row_custom_local_default_custom_hinge'),
      ),
      findsOneWidget,
    );
  });
}

Future<void> _pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(const SmartTrainnerApp());
  await tester.pumpAndSettle();
}

Future<void> _tapTab(WidgetTester tester, String key) async {
  await tester.tap(find.byKey(Key(key)));
  await tester.pumpAndSettle();
}

Future<void> _scrollToAndTap(WidgetTester tester, String key) async {
  await _scrollUntilVisible(tester, key);
  await tester.tap(find.byKey(Key(key)));
  await tester.pumpAndSettle();
}

Future<void> _scrollUntilVisible(
  WidgetTester tester,
  String key, {
  Finder? scrollable,
}) async {
  final finder = find.byKey(Key(key));
  await tester.scrollUntilVisible(finder, 350, scrollable: scrollable);
  await tester.pumpAndSettle();
}

Future<void> _selectDropdown(
  WidgetTester tester, {
  required String dropdownKey,
  required String optionKey,
}) async {
  await _scrollCustomFormUntilVisible(tester, dropdownKey);
  await tester.tap(find.byKey(Key(dropdownKey)));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(Key(optionKey)).last);
  await tester.pumpAndSettle();
}

Future<void> _scrollCustomFormUntilVisible(
  WidgetTester tester,
  String key,
) async {
  final finder = find.byKey(Key(key));
  for (var attempt = 0; attempt < 12 && finder.evaluate().isEmpty; attempt++) {
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
}
