import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:smart_trainner_core_domain/smart_trainner_core_domain.dart'
    show ObserveLatestWorkoutLogsUseCase;
import 'package:smart_trainner_core_model/smart_trainner_core_model.dart';
import 'package:smart_trainner_feature_exercise_domain/smart_trainner_feature_exercise_domain.dart'
    show GetExerciseUseCase;

class ExerciseDetailUiState {
  const ExerciseDetailUiState({
    this.exercise,
    this.latestWorkoutLog,
    this.showRecordAction = false,
  });

  final Exercise? exercise;
  final WorkoutLog? latestWorkoutLog;
  final bool showRecordAction;
}

class ExerciseDetailViewModel extends ChangeNotifier {
  ExerciseDetailViewModel({
    required ObserveLatestWorkoutLogsUseCase observeLatestWorkoutLogs,
    required GetExerciseUseCase getExercise,
  }) : _getExercise = getExercise {
    _subscription = observeLatestWorkoutLogs().listen((logs) {
      _latestWorkoutLogs = logs;
      _rebuildState();
    });
  }

  final GetExerciseUseCase _getExercise;
  StreamSubscription<List<WorkoutLog>>? _subscription;
  var _latestWorkoutLogs = <WorkoutLog>[];
  ExerciseId? _selectedExerciseId;
  bool _showRecordAction = false;

  ExerciseDetailUiState state = const ExerciseDetailUiState();

  Future<void> updateSelection(
    ExerciseId? exerciseId, {
    required bool shouldShowRecordAction,
  }) async {
    if (exerciseId == null) {
      _selectedExerciseId = null;
      _showRecordAction = false;
      state = const ExerciseDetailUiState();
      notifyListeners();
      return;
    }
    _showRecordAction = shouldShowRecordAction;
    if (_selectedExerciseId == exerciseId && state.exercise?.id == exerciseId) {
      _rebuildState();
      return;
    }
    _selectedExerciseId = exerciseId;
    final exercise = await _getExercise(exerciseId);
    if (_selectedExerciseId == exerciseId) {
      state = ExerciseDetailUiState(
        exercise: exercise,
        latestWorkoutLog: exercise == null
            ? null
            : _latestWorkoutLogs.latestForExercise(exercise.id),
        showRecordAction: _showRecordAction && exercise != null,
      );
      notifyListeners();
    }
  }

  void _rebuildState() {
    final exercise = state.exercise?.id == _selectedExerciseId
        ? state.exercise
        : null;
    state = ExerciseDetailUiState(
      exercise: exercise,
      latestWorkoutLog: exercise == null
          ? null
          : _latestWorkoutLogs.latestForExercise(exercise.id),
      showRecordAction: _showRecordAction && exercise != null,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

extension on List<WorkoutLog> {
  WorkoutLog? latestForExercise(ExerciseId exerciseId) {
    final logs = where((log) => log.exerciseId == exerciseId).toList()
      ..sort((a, b) => b.performedAt.compareTo(a.performedAt));
    return logs.isEmpty ? null : logs.first;
  }
}
