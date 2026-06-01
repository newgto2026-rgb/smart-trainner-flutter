import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_trainner_flutter/main.dart';

void runTrainingUiFlowTests() {
  testWidgets('home shows today training and analysis tabs', (tester) async {
    await _pumpApp(tester);

    expect(find.byKey(const Key('training_app_title')), findsOneWidget);
    expect(
      find.byKey(const Key('training_section_title_today')),
      findsOneWidget,
    );
    await _scrollUntilVisible(tester, 'training_next_routine_day_card');
    expect(
      find.byKey(const Key('training_next_routine_day_card')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('training_next_routine_time_estimate')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('training_next_routine_badge_duration')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('training_tab_home')), findsOneWidget);
    expect(find.byKey(const Key('training_tab_analysis')), findsOneWidget);
    expect(find.byKey(const Key('training_tab_record')), findsNothing);
  });

  testWidgets('weekly summary only appears on analysis tab', (tester) async {
    await _pumpApp(tester);

    expect(find.byKey(const Key('training_summary_band')), findsNothing);

    await _tapKey(tester, 'training_tab_plan');
    expect(find.byKey(const Key('training_summary_band')), findsNothing);

    await _tapKey(tester, 'training_tab_exercises');
    expect(find.byKey(const Key('training_summary_band')), findsNothing);

    await _tapKey(tester, 'training_tab_analysis');
    expect(find.byKey(const Key('training_summary_band')), findsOneWidget);
  });

  testWidgets('exercise detail shows step images', (tester) async {
    await _pumpApp(tester);
    await _tapKey(tester, 'training_tab_exercises');

    await _tapKey(tester, 'training_exercise_row_romanian_deadlift');

    for (var index = 0; index < 5; index++) {
      await _scrollUntilVisible(tester, 'training_step_image_$index');
      expect(find.byKey(Key('training_step_image_$index')), findsOneWidget);
    }
    expect(find.byKey(const Key('training_step_image_5')), findsNothing);

    await _tapKey(tester, 'training_step_image_0');
    expect(
      find.byKey(const Key('training_exercise_image_viewer')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('training_exercise_image_viewer_image')),
      findsOneWidget,
    );
    await _tapKey(tester, 'training_close_exercise_image_viewer');
    expect(
      find.byKey(const Key('training_exercise_image_viewer')),
      findsNothing,
    );
  });

  testWidgets('machine shoulder press detail shows exactly three step images', (
    tester,
  ) async {
    await _pumpApp(tester);
    await _tapKey(tester, 'training_tab_exercises');

    await _tapKey(tester, 'training_exercise_row_machine_shoulder_press');

    for (var index = 0; index < 3; index++) {
      await _scrollUntilVisible(tester, 'training_step_image_$index');
      expect(find.byKey(Key('training_step_image_$index')), findsOneWidget);
    }
    expect(find.byKey(const Key('training_step_image_3')), findsNothing);
  });

  testWidgets('record flow saves workout', (tester) async {
    await _pumpApp(tester);
    await _tapKey(tester, 'training_tab_plan');

    await _tapKey(tester, 'training_plan_exercise_leg_press');
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
      find.byKey(const Key('training_set_rest_input_0')),
      '75',
    );
    await tester.enterText(
      find.byKey(const Key('training_set_weight_input_1')),
      '85',
    );
    await _tapKey(tester, 'training_add_set_button');
    await _scrollUntilVisible(tester, 'training_set_weight_input_3');
    await tester.enterText(
      find.byKey(const Key('training_set_weight_input_3')),
      '90',
    );
    await _tapKey(tester, 'training_save_record');
    expect(find.byKey(const Key('training_record_dialog')), findsNothing);
  });

  testWidgets('exercise method during workout hides start record action', (
    tester,
  ) async {
    await _pumpApp(tester);

    await _tapKey(tester, 'training_home_start_workout');
    expect(find.byKey(const Key('training_record_dialog')), findsOneWidget);

    await _tapKey(tester, 'training_show_exercise_method');
    expect(
      find.byKey(const Key('training_exercise_detail_dialog')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('training_detail_start_record')), findsNothing);
  });

  testWidgets('modal dialog blocks bottom tab changes', (tester) async {
    await _pumpApp(tester);
    await _tapKey(tester, 'training_tab_plan');
    await _tapKey(tester, 'training_find_routine_button');

    expect(
      find.byKey(const Key('training_routine_library_dialog')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const Key('training_tab_analysis')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('training_routine_library_dialog')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('training_summary_band')), findsNothing);
  });

  testWidgets('default routine copy opens custom routine builder', (
    tester,
  ) async {
    await _pumpApp(tester);
    await _tapKey(tester, 'training_tab_plan');
    await _tapKey(tester, 'training_find_routine_button');

    await _tapKey(tester, 'training_copy_template_beginner-full-body-2day');
    expect(
      find.byKey(const Key('training_routine_library_dialog')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('training_custom_routine_builder')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('training_custom_focus_selected_FULL_BODY')),
      findsOneWidget,
    );

    await _tapKey(tester, 'training_save_custom_routine');
    expect(
      find.byKey(const Key('training_custom_routine_builder')),
      findsNothing,
    );
    await _tapKey(tester, 'training_find_routine_button');
    await _scrollUntilVisible(tester, 'training_custom_template_card');
    expect(
      find.byKey(const Key('training_custom_template_card')),
      findsOneWidget,
    );
  });

  testWidgets('focused routine selection and completion advances next day', (
    tester,
  ) async {
    await _pumpApp(tester);
    await _tapKey(tester, 'training_tab_plan');

    expect(
      find.byKey(
        const Key('training_template_card_intermediate-body-part-4day-60'),
      ),
      findsNothing,
    );
    await _tapKey(tester, 'training_find_routine_button');
    expect(
      find.byKey(const Key('training_routine_library_dialog')),
      findsOneWidget,
    );
    await _scrollUntilVisible(
      tester,
      'training_template_card_intermediate-body-part-4day-60',
    );
    expect(
      find.byKey(
        const Key('training_template_card_intermediate-body-part-4day-60'),
      ),
      findsOneWidget,
    );

    await _tapKey(tester, 'training_find_recommended_routine_button');
    expect(
      find.byKey(const Key('training_routine_settings_dialog')),
      findsOneWidget,
    );
    await _tapKey(tester, 'training_show_recommendations');
    expect(
      find.byKey(const Key('training_routine_recommendations_dialog')),
      findsOneWidget,
    );
    await _scrollUntilVisible(
      tester,
      'training_routine_preview_intermediate-body-part-4day-60',
    );
    expect(
      find.byKey(
        const Key('training_routine_preview_intermediate-body-part-4day-60'),
      ),
      findsOneWidget,
    );
    await _tapKey(tester, 'training_start_preview_routine');

    await _tapKey(tester, 'training_tab_home');
    expect(
      find.byKey(const Key('training_next_routine_day_1')),
      findsOneWidget,
    );
    await _tapKey(tester, 'training_complete_routine_day');
    expect(
      find.byKey(const Key('training_next_routine_day_2')),
      findsOneWidget,
    );
  });

  testWidgets(
    'custom routine builder saves selects edits and advances four day routine',
    (tester) async {
      await _pumpApp(tester);
      await _tapKey(tester, 'training_tab_plan');

      await _tapKey(tester, 'training_create_custom_routine_button');
      expect(
        find.byKey(const Key('training_custom_routine_builder')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('training_save_start_custom_routine')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('training_custom_exercise_leg_press_0')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('training_custom_day_empty')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('training_custom_focus_selector')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('training_custom_focus_selected_none')),
        findsOneWidget,
      );
      await _tapKey(tester, 'training_custom_focus_selector');
      expect(
        find.byKey(const Key('training_custom_focus_none')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('training_custom_focus_FULL_BODY')),
        findsNothing,
      );

      await tester.enterText(
        find.byKey(const Key('training_custom_routine_name')),
        'My 4 Day Split',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      await _tapKey(tester, 'training_custom_focus_CHEST');
      expect(
        find.byKey(const Key('training_custom_exercise_group_BACK')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('training_custom_exercise_group_LOWER_BODY')),
        findsNothing,
      );
      await _tapKey(tester, 'training_custom_exercise_group_CHEST');
      await _tapKey(tester, 'training_custom_add_exercise_machine_chest_press');
      expect(
        find.byKey(
          const Key('training_custom_add_exercise_machine_chest_press'),
        ),
        findsNothing,
      );

      await _tapKey(tester, 'training_add_custom_day');
      await _tapKey(tester, 'training_custom_day_tab_1');
      expect(
        find.byKey(const Key('training_custom_day_empty')),
        findsOneWidget,
      );
      await _selectCustomFocus(tester, 'training_custom_focus_LOWER_BODY');
      await _tapKey(tester, 'training_custom_exercise_group_LOWER_BODY');
      await _tapKey(tester, 'training_custom_add_exercise_leg_press');
      await _tapKey(tester, 'training_custom_add_exercise_goblet_squat');
      await _selectCustomFocus(tester, 'training_custom_focus_CHEST');
      expect(
        find.byKey(const Key('training_custom_exercise_leg_press_0')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('training_custom_exercise_goblet_squat_1')),
        findsNothing,
      );
      await _selectCustomFocus(tester, 'training_custom_focus_LOWER_BODY');
      await _tapKey(tester, 'training_custom_exercise_group_LOWER_BODY');
      await _tapKey(tester, 'training_custom_add_exercise_leg_press');
      await _tapKey(tester, 'training_custom_add_exercise_goblet_squat');
      await _tapKey(tester, 'training_custom_move_up_1');
      expect(
        find.byKey(const Key('training_custom_exercise_goblet_squat_0')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('training_custom_exercise_leg_press_1')),
        findsOneWidget,
      );
      await _tapKey(tester, 'training_custom_move_down_0');
      expect(
        find.byKey(const Key('training_custom_exercise_leg_press_0')),
        findsOneWidget,
      );

      await _tapKey(tester, 'training_add_custom_day');
      await _tapKey(tester, 'training_custom_day_tab_2');
      await _selectCustomFocus(tester, 'training_custom_focus_BACK');
      await _tapKey(tester, 'training_custom_exercise_group_BACK');
      await _tapKey(tester, 'training_custom_add_exercise_lat_pulldown');

      await _tapKey(tester, 'training_add_custom_day');
      await _tapKey(tester, 'training_custom_day_tab_3');
      await _selectCustomFocus(tester, 'training_custom_focus_SHOULDERS');
      await _tapKey(tester, 'training_custom_exercise_group_SHOULDERS');
      await _tapKey(
        tester,
        'training_custom_add_exercise_machine_shoulder_press',
      );
      await _tapKey(tester, 'training_save_custom_routine');
      expect(
        find.byKey(const Key('training_custom_routine_builder')),
        findsNothing,
      );

      await _tapKey(tester, 'training_find_routine_button');
      await _scrollUntilVisible(tester, 'training_custom_template_card');
      expect(
        find.byKey(const Key('training_custom_template_card')),
        findsOneWidget,
      );
      _expectCustomRoutineFlowDaysVisible();
      await _tapKey(tester, 'training_edit_custom_template_card');
      expect(
        find.byKey(const Key('training_custom_routine_builder')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('training_custom_focus_selected_CHEST')),
        findsOneWidget,
      );
      await _tapKey(tester, 'training_custom_day_tab_1');
      expect(
        find.byKey(const Key('training_custom_focus_selected_LOWER_BODY')),
        findsOneWidget,
      );
      await _tapKey(tester, 'training_save_custom_routine');
      expect(
        find.byKey(const Key('training_custom_routine_builder')),
        findsNothing,
      );

      await _tapKey(tester, 'training_find_routine_button');
      await _scrollUntilVisible(tester, 'training_custom_template_card');
      expect(
        find.byKey(const Key('training_custom_template_card')),
        findsOneWidget,
      );
      await _tapKey(tester, 'training_custom_template_card');
      expect(
        find.byKey(const Key('training_routine_library_dialog')),
        findsNothing,
      );
      _expectCustomRoutineFlowDaysVisible();
      await _tapKey(tester, 'training_edit_current_custom_routine');
      expect(
        find.byKey(const Key('training_custom_routine_builder')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('training_custom_focus_selected_CHEST')),
        findsOneWidget,
      );
      await _tapKey(tester, 'training_save_custom_routine');
      expect(
        find.byKey(const Key('training_custom_routine_builder')),
        findsNothing,
      );

      await _tapKey(tester, 'training_tab_home');
      expect(
        find.byKey(const Key('training_home_routine_source_custom')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('training_next_routine_day_1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('training_next_routine_focus_CHEST')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('training_next_routine_time_estimate')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('training_next_routine_badge_duration')),
        findsNothing,
      );
      await _tapKey(tester, 'training_complete_routine_day');
      expect(
        find.byKey(const Key('training_next_routine_day_2')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('training_next_routine_focus_LOWER_BODY')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('training_next_routine_plan_title')),
        findsOneWidget,
      );
      expect(find.textContaining(RegExp('레그 프레스|Leg Press')), findsOneWidget);
      expect(
        find.byKey(const Key('training_next_routine_time_estimate')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('training_next_routine_badge_duration')),
        findsNothing,
      );
    },
  );
}

Future<void> _pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(const SmartTrainnerApp());
  await tester.pump(const Duration(milliseconds: 1700));
  await tester.pumpAndSettle();
}

Future<void> _tapKey(WidgetTester tester, String key) async {
  await _scrollUntilVisible(tester, key);
  await tester.tap(find.byKey(Key(key)));
  await tester.pumpAndSettle();
}

Future<void> _selectCustomFocus(WidgetTester tester, String optionKey) async {
  await _tapKey(tester, 'training_custom_focus_selector');
  await _tapKey(tester, optionKey);
}

void _expectCustomRoutineFlowDaysVisible() {
  expect(
    find.byKey(const Key('training_routine_flow_custom-test')),
    findsOneWidget,
  );
  for (var dayNumber = 1; dayNumber <= 4; dayNumber++) {
    expect(
      find.byKey(Key('training_routine_flow_custom-test_day_$dayNumber')),
      findsOneWidget,
    );
  }
}

Future<void> _scrollUntilVisible(WidgetTester tester, String key) async {
  final finder = find.byKey(Key(key));
  if (finder.evaluate().isNotEmpty) {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    return;
  }

  Object? lastError;
  final scrollableFinders = <Finder>[
    ..._activeOverlayScrollables(),
    find.byType(Scrollable),
  ];
  for (final delta in <double>[360, -360]) {
    for (final scrollableFinder in scrollableFinders) {
      final count = scrollableFinder.evaluate().length;
      if (count == 0) {
        continue;
      }
      for (var index = count - 1; index >= 0; index--) {
        try {
          final found = await _dragUntilBuilt(
            tester,
            finder,
            delta,
            scrollable: scrollableFinder.at(index),
          );
          if (found) {
            await tester.ensureVisible(finder);
            await tester.pumpAndSettle();
            return;
          }
        } catch (error) {
          lastError = error;
        }
      }
    }
  }
  if (lastError != null) {
    throw TestFailure('Could not scroll to $key: $lastError');
  }
  expect(finder, findsOneWidget);
}

Future<bool> _dragUntilBuilt(
  WidgetTester tester,
  Finder finder,
  double delta, {
  required Finder scrollable,
}) async {
  final scrollableWidget = tester.widget<Scrollable>(scrollable);
  final moveStep = switch (scrollableWidget.axisDirection) {
    AxisDirection.up => Offset(0, delta),
    AxisDirection.down => Offset(0, -delta),
    AxisDirection.left => Offset(delta, 0),
    AxisDirection.right => Offset(-delta, 0),
  };
  for (var attempt = 0; attempt < 80; attempt++) {
    if (finder.evaluate().isNotEmpty) {
      return true;
    }
    await tester.drag(scrollable, moveStep, warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 50));
  }
  return finder.evaluate().isNotEmpty;
}

List<Finder> _activeOverlayScrollables() {
  const overlayKeys = <String>[
    'training_custom_routine_builder',
    'training_routine_library_dialog',
    'training_routine_recommendations_dialog',
    'training_record_dialog',
    'training_exercise_detail_dialog',
  ];
  return overlayKeys
      .map((key) {
        return find.descendant(
          of: find.byKey(Key(key)),
          matching: find.byType(Scrollable),
        );
      })
      .where((finder) => finder.evaluate().isNotEmpty)
      .toList();
}
