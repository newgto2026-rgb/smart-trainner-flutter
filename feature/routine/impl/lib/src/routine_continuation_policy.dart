import 'package:smart_trainner_core_model/smart_trainner_core_model.dart';

class CustomRoutineBuilderState {
  const CustomRoutineBuilderState({this.visible = false});

  final bool visible;
}

class RoutineUiState {
  const RoutineUiState({
    this.plan,
    this.completedPlannedExerciseIds = const <PlannedExerciseId>{},
    this.customRoutineBuilder = const CustomRoutineBuilderState(),
  });

  final WeeklyPlan? plan;
  final Set<PlannedExerciseId> completedPlannedExerciseIds;
  final CustomRoutineBuilderState customRoutineBuilder;

  PlannedExercise? nextPlannedExerciseAfterSaved(PlannedExercise saved) {
    final day = plan?.days.firstWhereOrNull(
      (day) => day.exercises.any((exercise) => exercise.id == saved.id),
    );
    if (day == null) {
      return null;
    }
    final savedIndex = day.exercises.indexWhere(
      (exercise) => exercise.id == saved.id,
    );
    for (var index = savedIndex + 1; index < day.exercises.length; index++) {
      final candidate = day.exercises[index];
      if (!completedPlannedExerciseIds.contains(candidate.id)) {
        return candidate;
      }
    }
    return null;
  }

  PlannedExercise? recordablePlannedExerciseFor(ExerciseId exerciseId) {
    if (customRoutineBuilder.visible) {
      return null;
    }
    return plan?.days
        .expand((day) => day.exercises)
        .firstWhereOrNull((planned) => planned.exercise.id == exerciseId);
  }
}

class RoutineContinuationPolicy {
  const RoutineContinuationPolicy();

  PlannedExercise? nextPlannedExerciseAfterSaved({
    required WeeklyPlan plan,
    required Set<PlannedExerciseId> completedIds,
    required PlannedExercise saved,
  }) {
    final exercises = plan.days.expand((day) => day.exercises).toList();
    final savedIndex = exercises.indexWhere(
      (exercise) => exercise.id == saved.id,
    );
    if (savedIndex < 0) {
      return exercises.firstWhere(
        (exercise) => !completedIds.contains(exercise.id),
        orElse: () => saved,
      );
    }
    for (var index = savedIndex + 1; index < exercises.length; index++) {
      final candidate = exercises[index];
      if (!completedIds.contains(candidate.id)) {
        return candidate;
      }
    }
    return null;
  }
}

extension _IterableFirstWhereOrNull<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T value) test) {
    for (final value in this) {
      if (test(value)) {
        return value;
      }
    }
    return null;
  }
}
