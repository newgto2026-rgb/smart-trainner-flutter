import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:smart_trainner_core_domain/smart_trainner_core_domain.dart'
    show ObserveExercisesUseCase, ObserveLatestWorkoutLogsUseCase;
import 'package:smart_trainner_core_model/smart_trainner_core_model.dart';
import 'package:smart_trainner_feature_analysis_domain/smart_trainner_feature_analysis_domain.dart'
    show ObserveWeeklySummaryUseCase;

class AnalysisUiState {
  const AnalysisUiState({
    this.recentLogs = const <RecentWorkoutLogUiModel>[],
    this.summary,
  });

  final List<RecentWorkoutLogUiModel> recentLogs;
  final WeeklySummary? summary;
}

class RecentWorkoutLogUiModel {
  const RecentWorkoutLogUiModel({required this.log, required this.exercise});

  final WorkoutLog log;
  final Exercise? exercise;
}

class AnalysisViewModel extends ChangeNotifier {
  AnalysisViewModel({
    required ObserveLatestWorkoutLogsUseCase observeLatestWorkoutLogs,
    required ObserveWeeklySummaryUseCase observeWeeklySummary,
    required ObserveExercisesUseCase observeExercises,
    required DateTime Function() now,
  }) : _observeWeeklySummary = observeWeeklySummary,
       _now = now {
    _subscriptions
      ..add(
        observeLatestWorkoutLogs().listen((logs) {
          _latestLogs = logs;
          _rebuildState();
        }),
      )
      ..add(
        observeExercises().listen((exercises) {
          _exercises = exercises;
          _rebuildState();
        }),
      );
    _subscribeSummary();
  }

  final ObserveWeeklySummaryUseCase _observeWeeklySummary;
  final DateTime Function() _now;
  AnalysisUiState state = const AnalysisUiState();
  final _subscriptions = <StreamSubscription<dynamic>>[];
  StreamSubscription<WeeklySummary>? _summarySubscription;
  var _latestLogs = <WorkoutLog>[];
  var _exercises = <Exercise>[];
  DateTime? _weekStartDate;

  void refreshWeekStart() {
    final nextWeekStart = _mondayOf(_now());
    if (_weekStartDate == nextWeekStart) {
      return;
    }
    _weekStartDate = nextWeekStart;
    _summarySubscription?.cancel();
    _summarySubscription = _observeWeeklySummary(nextWeekStart).listen((
      summary,
    ) {
      state = AnalysisUiState(recentLogs: state.recentLogs, summary: summary);
      notifyListeners();
    });
  }

  void _subscribeSummary() {
    refreshWeekStart();
  }

  void _rebuildState() {
    final exercisesById = {
      for (final exercise in _exercises) exercise.id: exercise,
    };
    final recentLogs = _latestLogs.toList()
      ..sort((a, b) => b.performedAt.compareTo(a.performedAt));
    state = AnalysisUiState(
      recentLogs: recentLogs.take(_recentWorkoutLogLimit).map((log) {
        return RecentWorkoutLogUiModel(
          log: log,
          exercise: exercisesById[log.exerciseId],
        );
      }).toList(),
      summary: state.summary,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _summarySubscription?.cancel();
    super.dispose();
  }
}

const _recentWorkoutLogLimit = 3;

DateTime _mondayOf(DateTime date) {
  final normalized = normalizeDate(date);
  return normalized.subtract(
    Duration(days: normalized.weekday - DateTime.monday),
  );
}
