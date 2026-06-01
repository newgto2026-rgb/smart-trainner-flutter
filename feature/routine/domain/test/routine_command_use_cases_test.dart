import 'package:smart_trainner_core_domain/smart_trainner_core_domain.dart';
import 'package:smart_trainner_core_model/smart_trainner_core_model.dart';
import 'package:smart_trainner_feature_routine_domain/smart_trainner_feature_routine_domain.dart';
import 'package:test/test.dart';

void main() {
  const advanceRoutineDay = AdvanceRoutineDayUseCase();
  const validateCustomRoutine = ValidateCustomRoutineUseCase();

  test(
    'validateCustomRoutine accepts catalog exercises and repeated exercise slots',
    () {
      final result = validateCustomRoutine(
        input: customRoutine(
          exercises: <CustomRoutineExerciseInput>[
            customExercise('squat'),
            customExercise('squat'),
          ],
        ),
        availableExerciseIds: <ExerciseId>{const ExerciseId('squat')},
      );

      expect(result, isNull);
    },
  );

  test('validateCustomRoutine rejects empty day', () {
    final result = validateCustomRoutine(
      input: customRoutine(exercises: const <CustomRoutineExerciseInput>[]),
      availableExerciseIds: <ExerciseId>{const ExerciseId('squat')},
    );

    expect(result, CustomRoutineValidationError.emptyDay);
  });

  test('validateCustomRoutine rejects unknown exercise', () {
    final result = validateCustomRoutine(
      input: customRoutine(
        exercises: <CustomRoutineExerciseInput>[customExercise('unknown')],
      ),
      availableExerciseIds: <ExerciseId>{const ExerciseId('squat')},
    );

    expect(result, CustomRoutineValidationError.unknownExercise);
  });

  test('validateCustomRoutine rejects invalid rep range', () {
    final result = validateCustomRoutine(
      input: customRoutine(
        exercises: <CustomRoutineExerciseInput>[
          customExercise('squat', repRangeStart: 12, repRangeEnd: 8),
        ],
      ),
      availableExerciseIds: <ExerciseId>{const ExerciseId('squat')},
    );

    expect(result, CustomRoutineValidationError.reps);
  });

  test('advanceRoutineDay wraps to first day after last day', () {
    final nextDayIndex = advanceRoutineDay(
      completedDayIndex: 3,
      cycleLength: 4,
    );

    expect(nextDayIndex, 0);
  });

  test('completeRoutineDay marks new cycle start when routine wraps', () async {
    final repository = CapturingRoutineProgressRepository();
    final completedAt = DateTime.utc(2026, 5, 24, 12);
    final completeRoutineDay = CompleteRoutineDayUseCase(
      repository,
      advanceRoutineDay,
    );

    await completeRoutineDay(
      template: commandTemplate('intermediate-body-part-4day'),
      completedDayIndex: 3,
      completedAt: completedAt,
    );

    expect(repository.nextDayIndex, 0);
    expect(repository.newCycleStartedAt, completedAt);
  });

  test('completeRoutineDay keeps cycle start when routine continues', () async {
    final repository = CapturingRoutineProgressRepository();
    final completedAt = DateTime.utc(2026, 5, 24, 12);
    final completeRoutineDay = CompleteRoutineDayUseCase(
      repository,
      advanceRoutineDay,
    );

    await completeRoutineDay(
      template: commandTemplate('intermediate-body-part-4day'),
      completedDayIndex: 1,
      completedAt: completedAt,
    );

    expect(repository.nextDayIndex, 2);
    expect(repository.newCycleStartedAt, isNull);
  });
}

PlanTemplate commandTemplate(String id) {
  return PlanTemplate(
    id: id,
    name: id,
    level: PlanLevel.intermediate,
    daysPerWeek: 4,
    description: id,
    days: const <PlanTemplateDay>[],
    structure: RoutineStructure.bodyPartSplit,
    recommendedExperience: TrainingExperience.intermediate,
    cycleLength: 4,
    sessionMinutes: 45,
    focusSummary: const <RoutineFocus>[
      RoutineFocus.back,
      RoutineFocus.chest,
      RoutineFocus.lowerBody,
      RoutineFocus.shoulders,
      RoutineFocus.arms,
      RoutineFocus.biceps,
      RoutineFocus.triceps,
      RoutineFocus.push,
      RoutineFocus.pull,
    ],
  );
}

CustomRoutineInput customRoutine({
  required List<CustomRoutineExerciseInput> exercises,
}) {
  return CustomRoutineInput(
    name: 'My routine',
    days: <CustomRoutineDayInput>[
      CustomRoutineDayInput(
        title: '1일차',
        focus: '하체',
        primaryFocus: RoutineFocus.lowerBody,
        exercises: exercises,
      ),
    ],
  );
}

CustomRoutineExerciseInput customExercise(
  String exerciseId, {
  int? repRangeStart = 8,
  int? repRangeEnd = 12,
}) {
  return CustomRoutineExerciseInput(
    exerciseId: ExerciseId(exerciseId),
    sets: 3,
    repRangeStart: repRangeStart,
    repRangeEnd: repRangeEnd,
    durationMinutes: null,
    restSeconds: 90,
  );
}

class CapturingRoutineProgressRepository
    implements RoutineProgressCommandRepository {
  int? nextDayIndex;
  DateTime? newCycleStartedAt;

  @override
  Future<OperationResult<void>> startRoutine(String templateId) {
    throw UnsupportedError('Not used');
  }

  @override
  Future<OperationResult<void>> markRoutineDayCompleted({
    required int completedDayIndex,
    required int nextDayIndex,
    required DateTime completedAt,
    required DateTime? newCycleStartedAt,
  }) async {
    this.nextDayIndex = nextDayIndex;
    this.newCycleStartedAt = newCycleStartedAt;
    return OperationResult.success();
  }
}
