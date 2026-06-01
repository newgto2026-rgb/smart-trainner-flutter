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
