import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:smart_trainner_core_domain/smart_trainner_core_domain.dart';
import 'package:smart_trainner_core_model/smart_trainner_core_model.dart';

class ExerciseCatalogUiState {
  const ExerciseCatalogUiState({
    this.exercises = const <Exercise>[],
    this.latestWorkoutLogs = const <WorkoutLog>[],
    this.selectedExerciseId,
  });

  final List<Exercise> exercises;
  final List<WorkoutLog> latestWorkoutLogs;
  final ExerciseId? selectedExerciseId;
}

class ExerciseCatalogViewModel extends ChangeNotifier {
  ExerciseCatalogViewModel({
    required ObserveExercisesUseCase observeExercises,
    required ObserveLatestWorkoutLogsUseCase observeLatestWorkoutLogs,
  }) {
    _subscriptions
      ..add(
        observeExercises().listen((exercises) {
          state = ExerciseCatalogUiState(
            exercises: exercises,
            latestWorkoutLogs: state.latestWorkoutLogs,
            selectedExerciseId: state.selectedExerciseId,
          );
          notifyListeners();
        }),
      )
      ..add(
        observeLatestWorkoutLogs().listen((logs) {
          state = ExerciseCatalogUiState(
            exercises: state.exercises,
            latestWorkoutLogs: logs,
            selectedExerciseId: state.selectedExerciseId,
          );
          notifyListeners();
        }),
      );
  }

  ExerciseCatalogUiState state = const ExerciseCatalogUiState();
  final _subscriptions = <StreamSubscription<dynamic>>[];

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }
}
