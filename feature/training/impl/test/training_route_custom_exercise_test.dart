import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_trainner_core_domain/smart_trainner_core_domain.dart';
import 'package:smart_trainner_core_model/smart_trainner_core_model.dart';
import 'package:smart_trainner_feature_training_impl/src/training_route.dart';

void main() {
  testWidgets('custom exercise form validates required name', (tester) async {
    await _pumpRoute(tester);
    await _tapExercisesTab(tester);
    await tester.tap(
      find.byKey(const Key('training_add_custom_exercise_button')),
    );
    await tester.pumpAndSettle();

    await _scrollUntilVisible(tester, 'training_custom_exercise_save_button');
    await tester.tap(
      find.byKey(const Key('training_custom_exercise_save_button')),
    );
    await tester.pumpAndSettle();
    await _scrollCustomFormToTop(tester);

    expect(
      find.byKey(const Key('training_custom_exercise_error_name')),
      findsOneWidget,
    );
  });

  testWidgets('custom exercise saves and appears as owned exercise', (
    tester,
  ) async {
    await _pumpRoute(tester);
    await _tapExercisesTab(tester);
    await tester.tap(
      find.byKey(const Key('training_add_custom_exercise_button')),
    );
    await tester.pumpAndSettle();

    await _enterCustomFormText(
      tester,
      key: 'training_custom_exercise_name_input',
      text: 'Custom Hinge',
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
    await _enterCustomFormText(
      tester,
      key: 'training_custom_exercise_summary_input',
      text: 'A custom posterior-chain movement.',
    );
    await _enterCustomFormText(
      tester,
      key: 'training_custom_exercise_instructions_input',
      text: 'Hinge at the hips.\nStand tall.',
    );
    await _enterCustomFormText(
      tester,
      key: 'training_custom_exercise_safety_input',
      text: 'Keep the spine neutral.',
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
    expect(
      find.byKey(
        const Key(
          'training_exercise_thumb_placeholder_custom_local_default_custom_hinge',
        ),
      ),
      findsOneWidget,
    );
  });
}

Future<void> _pumpRoute(WidgetTester tester) async {
  final repository = _FakeTrainingRepository();
  await tester.pumpWidget(
    MaterialApp(
      home: TrainingRoute(
        observeExercises: ObserveExercisesUseCase(repository),
        observePlanTemplates: ObservePlanTemplatesUseCase(repository),
        observeCurrentWeeklyPlan: ObserveCurrentWeeklyPlanUseCase(repository),
        observeWorkoutLogs: ObserveWorkoutLogsUseCase(repository),
        observeWeeklySummary: ObserveWeeklySummaryUseCase(repository),
        createCustomExercise: CreateCustomExerciseUseCase(repository),
        selectPlanTemplate: SelectPlanTemplateUseCase(repository),
        saveWorkoutLog: SaveWorkoutLogUseCase(repository),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _scrollCustomFormToTop(WidgetTester tester) async {
  await tester.drag(
    find.byKey(const Key('training_custom_exercise_form_scroll')),
    const Offset(0, 900),
    warnIfMissed: false,
  );
  await tester.pumpAndSettle();
}

Future<void> _tapExercisesTab(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('training_tab_exercises')));
  await tester.pumpAndSettle();
}

Future<void> _selectDropdown(
  WidgetTester tester, {
  required String dropdownKey,
  required String optionKey,
}) async {
  await _scrollUntilVisible(tester, dropdownKey);
  await tester.tap(find.byKey(Key(dropdownKey)));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(Key(optionKey)).last);
  await tester.pumpAndSettle();
}

Future<void> _enterCustomFormText(
  WidgetTester tester, {
  required String key,
  required String text,
}) async {
  await _scrollUntilVisible(tester, key);
  await tester.enterText(find.byKey(Key(key)), text);
  await tester.pumpAndSettle();
}

Future<void> _scrollUntilVisible(WidgetTester tester, String key) async {
  final target = find.byKey(Key(key));
  for (var attempt = 0; attempt < 12 && target.evaluate().isEmpty; attempt++) {
    await tester.drag(
      find.byKey(const Key('training_custom_exercise_form_scroll')),
      const Offset(0, -320),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
  }
  expect(target, findsOneWidget);
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
}

class _FakeTrainingRepository implements TrainingRepository {
  final _exerciseController = StreamController<List<Exercise>>.broadcast();
  final _exercises = <Exercise>[
    Exercise(
      id: const ExerciseId('leg_press'),
      name: '레그 프레스',
      muscleGroup: MuscleGroup.lowerBody,
      equipment: EquipmentType.machine,
      difficulty: DifficultyLevel.beginner,
      imageKey: 'leg_press',
      summary: '하체 기본 운동입니다.',
      instructions: const <String>['발을 밀어냅니다.'],
      safetyCues: const <String>['무릎을 잠그지 않습니다.'],
      defaultSets: 3,
      defaultRepRange: const RepRange(8, 12),
      defaultDurationMinutes: null,
      restSeconds: 60,
    ),
  ];

  @override
  Stream<List<Exercise>> observeExercises() async* {
    yield List<Exercise>.of(_exercises);
    yield* _exerciseController.stream;
  }

  @override
  Stream<List<PlanTemplate>> observePlanTemplates() {
    return Stream<List<PlanTemplate>>.value(const <PlanTemplate>[]);
  }

  @override
  Stream<WeeklyPlan> observeCurrentWeeklyPlan(DateTime weekStartDate) {
    return Stream<WeeklyPlan>.value(
      WeeklyPlan(
        id: const PlanId('empty'),
        templateId: 'empty',
        name: 'Empty',
        weekStartDate: weekStartDate,
        days: const <WorkoutDayPlan>[],
      ),
    );
  }

  @override
  Stream<List<WorkoutLog>> observeWorkoutLogs(DateTime weekStartDate) {
    return Stream<List<WorkoutLog>>.value(const <WorkoutLog>[]);
  }

  @override
  Stream<WeeklySummary> observeWeeklySummary(DateTime weekStartDate) {
    return Stream<WeeklySummary>.value(
      WeeklySummary(
        weekStartDate: weekStartDate,
        plannedExerciseCount: 0,
        completedExerciseCount: 0,
        totalSets: 0,
        totalVolumeKg: 0,
        totalMinutes: 0,
        streakDays: 0,
        muscleBalance: const <MuscleGroup, int>{},
        insight: '아직 기록이 없습니다.',
      ),
    );
  }

  @override
  Future<Exercise?> getExercise(ExerciseId id) async {
    return _exercises.where((exercise) => exercise.id == id).firstOrNull;
  }

  @override
  Future<OperationResult<Exercise>> createCustomExercise(
    CustomExerciseInput input,
  ) async {
    final exercise = Exercise(
      id: const ExerciseId('custom_local_default_custom_hinge'),
      name: input.name,
      muscleGroup: input.muscleGroup,
      equipment: input.equipment,
      difficulty: input.difficulty,
      imageKey: 'custom_local_default_custom_hinge',
      imagePath: input.imagePath,
      summary: input.summary,
      instructions: input.instructions,
      safetyCues: input.safetyCues,
      defaultSets: input.defaultSets,
      defaultRepRange: input.defaultRepRange,
      defaultDurationMinutes: input.defaultDurationMinutes,
      restSeconds: input.restSeconds,
      metadata: const ExerciseSourceMetadata.userCreated(
        ownerUserId: 'local-default',
      ),
    );
    _exercises.add(exercise);
    _exerciseController.add(List<Exercise>.of(_exercises));
    return OperationResult<Exercise>.success(exercise);
  }

  @override
  Future<OperationResult<void>> selectPlanTemplate(String templateId) async {
    return OperationResult<void>.success();
  }

  @override
  Future<OperationResult<void>> saveWorkoutLog(WorkoutLogInput input) async {
    return OperationResult<void>.success();
  }
}

extension _IterableFirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => this.isEmpty ? null : first;
}
