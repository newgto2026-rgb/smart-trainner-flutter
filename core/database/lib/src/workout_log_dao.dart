import 'dart:async';

import 'package:smart_trainner_core_database/src/workout_log_entity.dart';

abstract interface class WorkoutLogDao {
  Stream<List<WorkoutLogWithSets>> observeBetween({
    required String sessionId,
    required String startDate,
    required String endDate,
  });

  Future<int> upsert(WorkoutLogEntity log);

  Future<void> insertSetLogs(List<WorkoutSetLogEntity> setLogs);

  Future<void> upsertWithSets({
    required WorkoutLogEntity log,
    required List<WorkoutSetLogEntity> setLogs,
  });
}

class InMemoryWorkoutLogDao implements WorkoutLogDao {
  final _changes = StreamController<void>.broadcast();
  final _logs = <WorkoutLogEntity>[];
  final _setLogs = <WorkoutSetLogEntity>[];
  var _nextLogId = 1;
  var _nextSetLogId = 1;

  @override
  Stream<List<WorkoutLogWithSets>> observeBetween({
    required String sessionId,
    required String startDate,
    required String endDate,
  }) async* {
    yield _queryBetween(
      sessionId: sessionId,
      startDate: startDate,
      endDate: endDate,
    );
    await for (final _ in _changes.stream) {
      yield _queryBetween(
        sessionId: sessionId,
        startDate: startDate,
        endDate: endDate,
      );
    }
  }

  @override
  Future<int> upsert(WorkoutLogEntity log) async {
    final existingIndex = _logs.indexWhere(
      (existing) =>
          existing.sessionId == log.sessionId &&
          existing.plannedExerciseId == log.plannedExerciseId,
    );
    if (existingIndex >= 0) {
      final id = _logs[existingIndex].id;
      _logs[existingIndex] = log.copyWith(id: id);
      _setLogs.removeWhere((setLog) => setLog.workoutLogId == id);
      _changes.add(null);
      return id;
    }

    final id = _nextLogId++;
    _logs.add(log.copyWith(id: id));
    _changes.add(null);
    return id;
  }

  @override
  Future<void> insertSetLogs(List<WorkoutSetLogEntity> setLogs) async {
    for (final setLog in setLogs) {
      final existingIndex = _setLogs.indexWhere(
        (existing) =>
            existing.workoutLogId == setLog.workoutLogId &&
            existing.setIndex == setLog.setIndex,
      );
      final next = setLog.copyWith(
        id: existingIndex >= 0 ? _setLogs[existingIndex].id : _nextSetLogId++,
      );
      if (existingIndex >= 0) {
        _setLogs[existingIndex] = next;
      } else {
        _setLogs.add(next);
      }
    }
    _changes.add(null);
  }

  @override
  Future<void> upsertWithSets({
    required WorkoutLogEntity log,
    required List<WorkoutSetLogEntity> setLogs,
  }) async {
    final workoutLogId = await upsert(log);
    await insertSetLogs(
      setLogs
          .map((setLog) => setLog.copyWith(workoutLogId: workoutLogId))
          .toList(),
    );
  }

  void dispose() {
    _changes.close();
  }

  List<WorkoutLogWithSets> _queryBetween({
    required String sessionId,
    required String startDate,
    required String endDate,
  }) {
    final logs =
        _logs
            .where(
              (log) =>
                  log.sessionId == sessionId &&
                  log.performedDate.compareTo(startDate) >= 0 &&
                  log.performedDate.compareTo(endDate) <= 0,
            )
            .toList()
          ..sort((a, b) => b.performedAt.compareTo(a.performedAt));
    return logs
        .map(
          (log) => WorkoutLogWithSets(
            log: log,
            setLogs:
                (_setLogs
                    .where((setLog) => setLog.workoutLogId == log.id)
                    .toList()
                  ..sort((a, b) => a.setIndex.compareTo(b.setIndex))),
          ),
        )
        .toList();
  }
}
