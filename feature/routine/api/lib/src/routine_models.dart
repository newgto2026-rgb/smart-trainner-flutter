import 'package:smart_trainner_core_model/smart_trainner_core_model.dart';

class RoutineFeatureCallbacks {
  const RoutineFeatureCallbacks({
    this.onWorkoutStarted,
    this.onRoutineDayCompleted,
    this.onExerciseMethodSelected,
    this.onRecordSelected,
  });

  final void Function(PlannedExercise plannedExercise)? onWorkoutStarted;
  final void Function()? onRoutineDayCompleted;
  final void Function(ExerciseId exerciseId)? onExerciseMethodSelected;
  final void Function(PlannedExercise plannedExercise)? onRecordSelected;

  void workoutStarted(PlannedExercise plannedExercise) {
    onWorkoutStarted?.call(plannedExercise);
  }

  void routineDayCompleted() {
    onRoutineDayCompleted?.call();
  }

  void exerciseMethodSelected(ExerciseId exerciseId) {
    onExerciseMethodSelected?.call(exerciseId);
  }

  void recordSelected(PlannedExercise plannedExercise) {
    onRecordSelected?.call(plannedExercise);
  }
}

abstract interface class RoutineRouteState {
  String get currentRoutineName;

  PlannedExercise? nextPlannedExerciseAfterSaved(
    PlannedExercise plannedExercise,
  );

  PlannedExercise? recordablePlannedExerciseFor(ExerciseId exerciseId);
}
