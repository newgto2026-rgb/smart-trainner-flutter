import 'package:collection/collection.dart';
import 'package:smart_trainner_core_model/smart_trainner_core_model.dart';

class RecommendRoutineUseCase {
  const RecommendRoutineUseCase();

  RoutineRecommendation call({
    required RoutineRecommendationInput input,
    required List<PlanTemplate> templates,
  }) {
    final systemTemplates = templates
        .where((template) => template.source == RoutineSource.system)
        .toList();
    if (systemTemplates.isEmpty) {
      throw StateError('At least one system routine template is required.');
    }
    final eligible =
        systemTemplates
            .where(
              (template) =>
                  template.daysPerWeek <= input.daysPerWeek &&
                  template.sessionMinutes <= input.sessionMinutes &&
                  _isExperienceEligible(input.experience, template),
            )
            .toList()
          ..sort((a, b) => a.id.compareTo(b.id));
    final eligibleByExperience = systemTemplates
        .where((template) => _isExperienceEligible(input.experience, template))
        .toList();
    final candidates = eligible.isNotEmpty
        ? eligible
        : eligibleByExperience.isNotEmpty
        ? eligibleByExperience
        : systemTemplates;

    final primary =
        switch ((input.experience, input.feeling, input.daysPerWeek)) {
          (TrainingExperience.beginner, _, <= 2) => candidates.bestFullBody(
            daysPerWeek: 2,
          ),
          (TrainingExperience.beginner, _, _) => candidates.bestFullBody(
            daysPerWeek: input.daysPerWeek.clamp(1, 3).toInt(),
          ),
          (
            TrainingExperience.intermediate,
            RoutineFeeling.focusedBodyPart,
            >= 4,
          ) =>
            candidates.bestBodyPart(input) ?? candidates.bestBalanced(input),
          (
            TrainingExperience.intermediate,
            RoutineFeeling.balancedFullBody,
            _,
          ) =>
            candidates.bestFullBody(
                  daysPerWeek: input.daysPerWeek.clamp(1, 3).toInt(),
                ) ??
                candidates.bestBalanced(input),
          (TrainingExperience.intermediate, _, >= 4) =>
            candidates.bestBodyPart(input) ?? candidates.bestBalanced(input),
          _ =>
            candidates.bestBalanced(input) ??
                candidates.bestFullBody(daysPerWeek: input.daysPerWeek),
        } ??
        candidates.first;

    final alternatives = candidates
        .where((template) => template.id != primary.id)
        .sorted(_routineAlternativeComparator(input, primary))
        .take(2)
        .map((template) => template.id)
        .toList();

    return RoutineRecommendation(
      primaryTemplateId: primary.id,
      alternativeTemplateIds: alternatives,
      reasonCode: switch (primary.structure) {
        RoutineStructure.fullBody => 'full_body_frequency',
        RoutineStructure.balancedSplit => 'balanced_recovery',
        RoutineStructure.bodyPartSplit => 'focused_body_part_cycle',
      },
    );
  }

  bool _isExperienceEligible(
    TrainingExperience experience,
    PlanTemplate template,
  ) {
    return switch (experience) {
      TrainingExperience.beginner =>
        template.recommendedExperience == TrainingExperience.beginner &&
            !(template.structure == RoutineStructure.bodyPartSplit &&
                template.daysPerWeek >= 5),
      TrainingExperience.intermediate => true,
    };
  }
}

class EvaluateRoutineReadinessUseCase {
  const EvaluateRoutineReadinessUseCase();

  RoutineReadiness call({
    required DateTime? lastCompletedAt,
    required DateTime now,
    required int minRecoveryHours,
  }) {
    if (lastCompletedAt == null) {
      return const RoutineReadiness(
        ready: true,
        remainingRecoveryHours: 0,
        warningCode: null,
      );
    }
    final elapsedHours = now
        .difference(lastCompletedAt)
        .inHours
        .clamp(0, 1 << 31)
        .toInt();
    final remaining = (minRecoveryHours - elapsedHours)
        .clamp(0, 1 << 31)
        .toInt();
    return RoutineReadiness(
      ready: remaining == 0,
      remainingRecoveryHours: remaining,
      warningCode: remaining == 0 ? null : 'minimum_recovery_not_met',
    );
  }
}

class ResolveRoutineCycleCompletionUseCase {
  const ResolveRoutineCycleCompletionUseCase();

  Set<PlannedExerciseId> call({
    required List<WorkoutLog> logs,
    required RoutineProgress progress,
  }) {
    final cycleStartedAt = progress.cycleStartedAt;
    return logs
        .where((log) => log.completed)
        .where(
          (log) =>
              cycleStartedAt == null ||
              !log.performedAt.isBefore(cycleStartedAt),
        )
        .map((log) => log.plannedExerciseId)
        .toSet();
  }
}

const _bodyPartBaseFocus = <RoutineFocus>[
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

extension on List<PlanTemplate> {
  PlanTemplate? bestFullBody({required int daysPerWeek}) {
    return _minWith(
      where((template) => template.structure == RoutineStructure.fullBody),
      (a, b) => _compareInts(
        (a.daysPerWeek - daysPerWeek).abs(),
        (b.daysPerWeek - daysPerWeek).abs(),
      ).ifZero(_compareInts(a.daysPerWeek, b.daysPerWeek)),
    );
  }

  PlanTemplate? bestBalanced(RoutineRecommendationInput input) {
    return _minWith(
      where((template) => template.structure == RoutineStructure.balancedSplit),
      (a, b) => _compareTemplateFit(input, a, b),
    );
  }

  PlanTemplate? bestBodyPart(RoutineRecommendationInput input) {
    return _minWith(
      where(
        (template) =>
            template.structure == RoutineStructure.bodyPartSplit &&
            template.focusSummary.toSet().containsAll(_bodyPartBaseFocus),
      ),
      (a, b) => _compareTemplateFit(input, a, b),
    );
  }
}

PlanTemplate? _minWith(
  Iterable<PlanTemplate> templates,
  int Function(PlanTemplate a, PlanTemplate b) compare,
) {
  final iterator = templates.iterator;
  if (!iterator.moveNext()) {
    return null;
  }
  var best = iterator.current;
  while (iterator.moveNext()) {
    final candidate = iterator.current;
    if (compare(candidate, best) < 0) {
      best = candidate;
    }
  }
  return best;
}

int _compareTemplateFit(
  RoutineRecommendationInput input,
  PlanTemplate a,
  PlanTemplate b,
) {
  return _compareInts(
        (a.daysPerWeek - input.daysPerWeek).abs(),
        (b.daysPerWeek - input.daysPerWeek).abs(),
      )
      .ifZero(
        _compareInts(
          (a.sessionMinutes - input.sessionMinutes).abs(),
          (b.sessionMinutes - input.sessionMinutes).abs(),
        ),
      )
      .ifZero(_compareInts(b.sessionMinutes, a.sessionMinutes));
}

int Function(PlanTemplate, PlanTemplate) _routineAlternativeComparator(
  RoutineRecommendationInput input,
  PlanTemplate primary,
) {
  return (a, b) {
    return _compareInts(
          a.structure == primary.structure ? 1 : 0,
          b.structure == primary.structure ? 1 : 0,
        )
        .ifZero(
          _compareInts(
            (a.daysPerWeek - input.daysPerWeek).abs(),
            (b.daysPerWeek - input.daysPerWeek).abs(),
          ),
        )
        .ifZero(
          _compareInts(
            a.sessionMinutes <= input.sessionMinutes ? 0 : 1,
            b.sessionMinutes <= input.sessionMinutes ? 0 : 1,
          ),
        );
  };
}

int _compareInts(int a, int b) => a.compareTo(b);

extension on int {
  int ifZero(int next) => this == 0 ? next : this;
}
