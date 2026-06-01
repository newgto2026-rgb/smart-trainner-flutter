import 'package:flutter_test/flutter_test.dart';
import 'package:smart_trainner_core_model/smart_trainner_core_model.dart';
import 'package:smart_trainner_feature_routine_impl/smart_trainner_feature_routine_impl.dart';

void main() {
  test(
    'nextPlannedExerciseAfterSaved returns next incomplete exercise in same day',
    () {
      final first = plannedExercise('back_pull');
      final skippedCompleted = plannedExercise('back_row');
      final next = plannedExercise('lat_pulldown');
      final state = RoutineUiState(
        plan: weeklyPlan(
          WorkoutDayPlan(
            date: DateTime(2026, 5, 18),
            title: 'Day 1',
            focus: 'Back',
            exercises: <PlannedExercise>[first, skippedCompleted, next],
            dayNumber: 1,
            primaryFocus: RoutineFocus.back,
            secondaryFocuses: const <RoutineFocus>[],
            minRecoveryHours: 24,
          ),
        ),
        completedPlannedExerciseIds: <PlannedExerciseId>{skippedCompleted.id},
      );

      expect(state.nextPlannedExerciseAfterSaved(first)?.id, next.id);
    },
  );

  test('nextPlannedExerciseAfterSaved does not continue into another day', () {
    final current = plannedExercise('back_pull');
    final nextDayExercise = plannedExercise('leg_press');
    final state = RoutineUiState(
      plan: weeklyPlan(
        WorkoutDayPlan(
          date: DateTime(2026, 5, 18),
          title: 'Day 1',
          focus: 'Back',
          exercises: <PlannedExercise>[current],
          dayNumber: 1,
          primaryFocus: RoutineFocus.back,
          secondaryFocuses: const <RoutineFocus>[],
          minRecoveryHours: 24,
        ),
        WorkoutDayPlan(
          date: DateTime(2026, 5, 19),
          title: 'Day 2',
          focus: 'Legs',
          exercises: <PlannedExercise>[nextDayExercise],
          dayNumber: 2,
          primaryFocus: RoutineFocus.lowerBody,
          secondaryFocuses: const <RoutineFocus>[],
          minRecoveryHours: 24,
        ),
      ),
    );

    expect(state.nextPlannedExerciseAfterSaved(current), isNull);
  });

  test(
    'recordablePlannedExerciseFor returns null when custom builder is visible',
    () {
      final planned = plannedExercise('back_pull');
      final state = RoutineUiState(
        plan: weeklyPlan(
          WorkoutDayPlan(
            date: DateTime(2026, 5, 18),
            title: 'Day 1',
            focus: 'Back',
            exercises: <PlannedExercise>[planned],
            dayNumber: 1,
            primaryFocus: RoutineFocus.back,
            secondaryFocuses: const <RoutineFocus>[],
            minRecoveryHours: 24,
          ),
        ),
        customRoutineBuilder: const CustomRoutineBuilderState(visible: true),
      );

      expect(state.recordablePlannedExerciseFor(planned.exercise.id), isNull);
    },
  );

  test(
    'recordablePlannedExerciseFor returns matching planned exercise when hidden',
    () {
      final planned = plannedExercise('back_pull');
      final state = RoutineUiState(
        plan: weeklyPlan(
          WorkoutDayPlan(
            date: DateTime(2026, 5, 18),
            title: 'Day 1',
            focus: 'Back',
            exercises: <PlannedExercise>[planned],
            dayNumber: 1,
            primaryFocus: RoutineFocus.back,
            secondaryFocuses: const <RoutineFocus>[],
            minRecoveryHours: 24,
          ),
        ),
      );

      expect(
        state.recordablePlannedExerciseFor(planned.exercise.id)?.id,
        planned.id,
      );
    },
  );
}

WeeklyPlan weeklyPlan(WorkoutDayPlan first, [WorkoutDayPlan? second]) {
  return WeeklyPlan(
    id: const PlanId('plan'),
    templateId: 'template',
    name: 'Template',
    weekStartDate: DateTime(2026, 5, 18),
    days: <WorkoutDayPlan>[first, if (second != null) second],
  );
}

PlannedExercise plannedExercise(String id) {
  return PlannedExercise(
    id: PlannedExerciseId('planned_$id'),
    exercise: exercise(id),
    sets: 3,
    repRange: const RepRange(8, 12),
    durationMinutes: null,
    restSeconds: 90,
    note: '',
  );
}

Exercise exercise(String id) {
  return Exercise(
    id: ExerciseId(id),
    name: id,
    muscleGroup: MuscleGroup.back,
    equipment: EquipmentType.machine,
    difficulty: DifficultyLevel.intermediate,
    imageKey: id,
    summary: '',
    instructions: const <String>[],
    safetyCues: const <String>[],
    defaultSets: 3,
    defaultRepRange: const RepRange(8, 12),
    defaultDurationMinutes: null,
    restSeconds: 90,
  );
}
