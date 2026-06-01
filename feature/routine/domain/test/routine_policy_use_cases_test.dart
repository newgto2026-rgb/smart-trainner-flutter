import 'package:smart_trainner_core_model/smart_trainner_core_model.dart';
import 'package:smart_trainner_feature_routine_domain/smart_trainner_feature_routine_domain.dart';
import 'package:test/test.dart';

void main() {
  const recommendRoutine = RecommendRoutineUseCase();
  const evaluateReadiness = EvaluateRoutineReadinessUseCase();
  const resolveRoutineCycleCompletion = ResolveRoutineCycleCompletionUseCase();
  final templates = routinePolicyTemplates();

  test('recommendRoutine beginner two days recommends full body', () {
    final recommendation = recommendRoutine(
      input: const RoutineRecommendationInput(
        daysPerWeek: 2,
        sessionMinutes: 45,
        experience: TrainingExperience.beginner,
        feeling: RoutineFeeling.appRecommended,
      ),
      templates: templates,
    );

    expect(recommendation.primaryTemplateId, 'beginner-full-body-2day');
  });

  test(
    'recommendRoutine beginner five days does not default to body part split',
    () {
      final recommendation = recommendRoutine(
        input: const RoutineRecommendationInput(
          daysPerWeek: 5,
          sessionMinutes: 60,
          experience: TrainingExperience.beginner,
          feeling: RoutineFeeling.focusedBodyPart,
        ),
        templates: templates,
      );

      expect(
        recommendation.primaryTemplateId,
        isNot('intermediate-body-part-5day'),
      );
      expect(
        templates
            .firstWhere((entry) => entry.id == recommendation.primaryTemplateId)
            .structure,
        RoutineStructure.fullBody,
      );
    },
  );

  test(
    'recommendRoutine intermediate focused four days recommends body part split',
    () {
      final recommendation = recommendRoutine(
        input: const RoutineRecommendationInput(
          daysPerWeek: 4,
          sessionMinutes: 60,
          experience: TrainingExperience.intermediate,
          feeling: RoutineFeeling.focusedBodyPart,
        ),
        templates: templates,
      );

      expect(
        recommendation.primaryTemplateId,
        'intermediate-body-part-4day-60',
      );
    },
  );

  test(
    'recommendRoutine balanced full body keeps away from body part split',
    () {
      final recommendation = recommendRoutine(
        input: const RoutineRecommendationInput(
          daysPerWeek: 4,
          sessionMinutes: 60,
          experience: TrainingExperience.intermediate,
          feeling: RoutineFeeling.balancedFullBody,
        ),
        templates: templates,
      );

      expect(recommendation.primaryTemplateId, 'beginner-full-body-3day');
    },
  );

  test('recommendRoutine focused body part honors session length variants', () {
    final inputs = <int>[30, 45, 60].map((minutes) {
      return RoutineRecommendationInput(
        daysPerWeek: 4,
        sessionMinutes: minutes,
        experience: TrainingExperience.intermediate,
        feeling: RoutineFeeling.focusedBodyPart,
      );
    });

    final recommendations = inputs
        .map(
          (input) => recommendRoutine(
            input: input,
            templates: templates,
          ).primaryTemplateId,
        )
        .toList();

    expect(recommendations, <String>[
      'intermediate-body-part-4day-30',
      'intermediate-body-part-4day',
      'intermediate-body-part-4day-60',
    ]);
  });

  test(
    'recommendRoutine excludes custom routines from recommendation candidates',
    () {
      final sourceTemplate = templates.firstWhere(
        (entry) => entry.id == 'intermediate-body-part-4day-60',
      );
      final customTemplate = template(
        id: 'custom-lift-party',
        daysPerWeek: sourceTemplate.daysPerWeek,
        sessionMinutes: sourceTemplate.sessionMinutes,
        structure: sourceTemplate.structure,
        experience: sourceTemplate.recommendedExperience,
        focusSummary: sourceTemplate.focusSummary,
        source: RoutineSource.custom,
      );

      final recommendation = recommendRoutine(
        input: const RoutineRecommendationInput(
          daysPerWeek: 4,
          sessionMinutes: 60,
          experience: TrainingExperience.intermediate,
          feeling: RoutineFeeling.focusedBodyPart,
        ),
        templates: <PlanTemplate>[customTemplate, ...templates],
      );

      expect(
        recommendation.primaryTemplateId,
        'intermediate-body-part-4day-60',
      );
      expect(
        recommendation.alternativeTemplateIds,
        isNot(contains('custom-lift-party')),
      );
    },
  );

  test('resolveRoutineCycleCompletion excludes logs before current cycle', () {
    final currentCycleStart = DateTime.utc(2026, 5, 24, 12);
    final progress = RoutineProgress(
      templateId: 'intermediate-body-part-4day',
      dayIndex: 0,
      lastCompletedDayIndex: 3,
      lastCompletedAt: currentCycleStart,
      startedAt: DateTime.utc(2026, 5, 20),
      cycleStartedAt: currentCycleStart,
    );

    final result = resolveRoutineCycleCompletion(
      logs: <WorkoutLog>[
        completedLog(
          id: 1,
          plannedExerciseId: 'day-1-exercise',
          performedAt: DateTime.utc(2026, 5, 24, 11, 59),
        ),
        completedLog(
          id: 2,
          plannedExerciseId: 'day-2-exercise',
          performedAt: DateTime.utc(2026, 5, 24, 12, 1),
        ),
      ],
      progress: progress,
    );

    expect(result, <PlannedExerciseId>{
      const PlannedExerciseId('day-2-exercise'),
    });
  });

  test('evaluateReadiness returns warning before minimum recovery', () {
    final result = evaluateReadiness(
      lastCompletedAt: DateTime.utc(2026, 5, 24, 9),
      now: DateTime.utc(2026, 5, 24, 20),
      minRecoveryHours: 24,
    );

    expect(result.ready, isFalse);
    expect(result.remainingRecoveryHours, 13);
    expect(result.warningCode, 'minimum_recovery_not_met');
  });
}

List<PlanTemplate> routinePolicyTemplates() {
  const bodyPartFocus = <RoutineFocus>[
    RoutineFocus.back,
    RoutineFocus.chest,
    RoutineFocus.lowerBody,
    RoutineFocus.shoulders,
    RoutineFocus.arms,
    RoutineFocus.biceps,
    RoutineFocus.triceps,
    RoutineFocus.push,
    RoutineFocus.pull,
  ];
  return <PlanTemplate>[
    template(
      id: 'beginner-full-body-2day',
      daysPerWeek: 2,
      sessionMinutes: 30,
      structure: RoutineStructure.fullBody,
      experience: TrainingExperience.beginner,
      focusSummary: <RoutineFocus>[RoutineFocus.fullBody],
    ),
    template(
      id: 'beginner-full-body-3day',
      daysPerWeek: 3,
      sessionMinutes: 45,
      structure: RoutineStructure.fullBody,
      experience: TrainingExperience.beginner,
      focusSummary: <RoutineFocus>[RoutineFocus.fullBody],
    ),
    template(
      id: 'intermediate-balanced-4day',
      daysPerWeek: 4,
      sessionMinutes: 45,
      structure: RoutineStructure.balancedSplit,
      experience: TrainingExperience.intermediate,
      focusSummary: <RoutineFocus>[
        RoutineFocus.upperBody,
        RoutineFocus.lowerBody,
      ],
    ),
    template(
      id: 'intermediate-body-part-4day-30',
      daysPerWeek: 4,
      sessionMinutes: 30,
      structure: RoutineStructure.bodyPartSplit,
      experience: TrainingExperience.intermediate,
      focusSummary: bodyPartFocus,
    ),
    template(
      id: 'intermediate-body-part-4day',
      daysPerWeek: 4,
      sessionMinutes: 45,
      structure: RoutineStructure.bodyPartSplit,
      experience: TrainingExperience.intermediate,
      focusSummary: bodyPartFocus,
    ),
    template(
      id: 'intermediate-body-part-4day-60',
      daysPerWeek: 4,
      sessionMinutes: 60,
      structure: RoutineStructure.bodyPartSplit,
      experience: TrainingExperience.intermediate,
      focusSummary: bodyPartFocus,
    ),
    template(
      id: 'intermediate-body-part-5day',
      daysPerWeek: 5,
      sessionMinutes: 60,
      structure: RoutineStructure.bodyPartSplit,
      experience: TrainingExperience.intermediate,
      focusSummary: bodyPartFocus,
    ),
  ];
}

PlanTemplate template({
  required String id,
  required int daysPerWeek,
  required int sessionMinutes,
  required RoutineStructure structure,
  required TrainingExperience experience,
  required List<RoutineFocus> focusSummary,
  RoutineSource source = RoutineSource.system,
}) {
  return PlanTemplate(
    id: id,
    name: id,
    level: experience == TrainingExperience.beginner
        ? PlanLevel.beginner
        : PlanLevel.intermediate,
    daysPerWeek: daysPerWeek,
    description: id,
    days: const <PlanTemplateDay>[],
    structure: structure,
    recommendedExperience: experience,
    cycleLength: daysPerWeek,
    sessionMinutes: sessionMinutes,
    focusSummary: focusSummary,
    source: source,
  );
}

WorkoutLog completedLog({
  required int id,
  required String plannedExerciseId,
  required DateTime performedAt,
}) {
  return WorkoutLog(
    id: WorkoutLogId(id),
    sessionId: const UserSessionId('session'),
    plannedExerciseId: PlannedExerciseId(plannedExerciseId),
    exerciseId: ExerciseId('exercise-$id'),
    performedAt: performedAt,
    sets: 3,
    reps: 10,
    weightKg: null,
    durationMinutes: null,
    memo: '',
    completed: true,
  );
}
