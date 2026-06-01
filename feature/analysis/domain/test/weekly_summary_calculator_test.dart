import 'package:smart_trainner_core_model/smart_trainner_core_model.dart';
import 'package:smart_trainner_feature_analysis_domain/smart_trainner_feature_analysis_domain.dart';
import 'package:test/test.dart';

void main() {
  final calculator = WeeklySummaryCalculator();
  final weekStart = DateTime(2026, 5, 18);

  test('calculate counts completion volume and muscle balance', () {
    final exercise = analysisExercise('leg_press', MuscleGroup.lowerBody);
    final planned = PlannedExercise(
      id: const PlannedExerciseId('2026-05-18_leg_press'),
      exercise: exercise,
      sets: 3,
      repRange: const RepRange(10, 12),
      durationMinutes: null,
      restSeconds: 90,
      note: '',
    );
    final plan = WeeklyPlan(
      id: const PlanId('plan'),
      templateId: 'beginner',
      name: '초보 주 3회',
      weekStartDate: weekStart,
      days: <WorkoutDayPlan>[
        WorkoutDayPlan(
          date: weekStart,
          title: '전신 A',
          focus: '전신',
          exercises: <PlannedExercise>[planned],
        ),
      ],
    );
    final logs = <WorkoutLog>[
      WorkoutLog(
        id: const WorkoutLogId(1),
        sessionId: const UserSessionId('local-default'),
        plannedExerciseId: planned.id,
        exerciseId: exercise.id,
        performedAt: DateTime(2026, 5, 18, 20),
        sets: 4,
        reps: null,
        weightKg: null,
        durationMinutes: null,
        memo: '',
        completed: true,
        setEntries: const <WorkoutSetLog>[
          WorkoutSetLog(
            order: 1,
            reps: 10,
            weightKg: 70,
            durationMinutes: null,
          ),
          WorkoutSetLog(
            order: 2,
            reps: 10,
            weightKg: 80,
            durationMinutes: null,
          ),
          WorkoutSetLog(order: 3, reps: 8, weightKg: 90, durationMinutes: null),
          WorkoutSetLog(order: 4, reps: 8, weightKg: 90, durationMinutes: null),
        ],
      ),
    ];

    final result = calculator.calculate(
      weekStartDate: weekStart,
      plan: plan,
      logs: logs,
    );

    expect(result.plannedExerciseCount, 1);
    expect(result.completedExerciseCount, 1);
    expect(result.completionRate, 100);
    expect(result.totalSets, 4);
    expect(result.totalVolumeKg, 2940);
    expect(result.muscleBalance[MuscleGroup.lowerBody], 1);
  });

  test('calculate empty logs returns coaching prompt', () {
    final result = calculator.calculate(
      weekStartDate: weekStart,
      plan: WeeklyPlan(
        id: const PlanId('plan'),
        templateId: 'intro',
        name: '입문',
        weekStartDate: weekStart,
        days: const <WorkoutDayPlan>[],
      ),
      logs: const <WorkoutLog>[],
    );

    expect(result.completionRate, 0);
    expect(result.insight, contains('플랜'));
  });

  test('calculate excludes full body from weakest muscle insight', () {
    const completedGroups = <MuscleGroup>[
      MuscleGroup.lowerBody,
      MuscleGroup.back,
      MuscleGroup.chest,
      MuscleGroup.shoulders,
      MuscleGroup.biceps,
      MuscleGroup.triceps,
      MuscleGroup.forearms,
      MuscleGroup.core,
    ];
    final completedExercises = completedGroups.map((group) {
      return plannedExercise(id: 'completed_${group.name}', muscleGroup: group);
    }).toList();
    final extraExercises = List<PlannedExercise>.generate(4, (index) {
      return plannedExercise(
        id: 'extra_lower_$index',
        muscleGroup: MuscleGroup.lowerBody,
      );
    });
    final plan = WeeklyPlan(
      id: const PlanId('plan'),
      templateId: 'balanced',
      name: '균형 루틴',
      weekStartDate: weekStart,
      days: <WorkoutDayPlan>[
        WorkoutDayPlan(
          date: weekStart,
          title: '균형',
          focus: '전신',
          exercises: <PlannedExercise>[
            ...completedExercises,
            ...extraExercises,
          ],
        ),
      ],
    );
    final logs = completedExercises.indexed.map((entry) {
      return completedLog(id: entry.$1 + 1, planned: entry.$2);
    }).toList();

    final result = calculator.calculate(
      weekStartDate: weekStart,
      plan: plan,
      logs: logs,
    );

    expect(result.completionRate, lessThan(80));
    expect(result.insight, isNot(contains(MuscleGroup.fullBody.displayName)));
    expect(result.insight, contains(MuscleGroup.lowerBody.displayName));
  });
}

PlannedExercise plannedExercise({
  required String id,
  required MuscleGroup muscleGroup,
}) {
  return PlannedExercise(
    id: PlannedExerciseId('2026-05-18_$id'),
    exercise: analysisExercise(id, muscleGroup),
    sets: 3,
    repRange: const RepRange(10, 12),
    durationMinutes: null,
    restSeconds: 90,
    note: '',
  );
}

WorkoutLog completedLog({required int id, required PlannedExercise planned}) {
  return WorkoutLog(
    id: WorkoutLogId(id),
    sessionId: const UserSessionId('local-default'),
    plannedExerciseId: planned.id,
    exerciseId: planned.exercise.id,
    performedAt: DateTime(2026, 5, 18, 20),
    sets: 3,
    reps: 10,
    weightKg: 10,
    durationMinutes: null,
    memo: '',
    completed: true,
  );
}

Exercise analysisExercise(String id, MuscleGroup muscleGroup) {
  return Exercise(
    id: ExerciseId(id),
    name: id,
    muscleGroup: muscleGroup,
    equipment: EquipmentType.machine,
    difficulty: DifficultyLevel.beginner,
    imageKey: id,
    summary: '',
    instructions: const <String>[],
    safetyCues: const <String>[],
    defaultSets: 3,
    defaultRepRange: const RepRange(10, 12),
    defaultDurationMinutes: null,
    restSeconds: 90,
  );
}
