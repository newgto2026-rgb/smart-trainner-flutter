import 'dart:async';

import 'package:smart_trainner_core_database/src/custom_routine_entity.dart';

abstract interface class CustomRoutineDao {
  Stream<List<CustomRoutineWithDays>> observeForSession(String sessionId);

  Future<CustomRoutineWithDays?> getById({
    required String sessionId,
    required String routineId,
  });

  Future<void> upsertFull({
    required CustomRoutineEntity routine,
    required List<CustomRoutineDayWrite> days,
  });

  Future<int> deleteRoutine({
    required String sessionId,
    required String routineId,
  });
}

class InMemoryCustomRoutineDao implements CustomRoutineDao {
  final _changes = StreamController<void>.broadcast();
  final _routines = <CustomRoutineEntity>[];
  final _days = <CustomRoutineDayEntity>[];
  final _exercises = <CustomRoutineExerciseEntity>[];

  @override
  Stream<List<CustomRoutineWithDays>> observeForSession(
    String sessionId,
  ) async* {
    yield _query(sessionId);
    await for (final _ in _changes.stream) {
      yield _query(sessionId);
    }
  }

  @override
  Future<CustomRoutineWithDays?> getById({
    required String sessionId,
    required String routineId,
  }) async {
    final routines = _query(
      sessionId,
    ).where((entry) => entry.routine.id == routineId);
    return routines.isEmpty ? null : routines.single;
  }

  @override
  Future<void> upsertFull({
    required CustomRoutineEntity routine,
    required List<CustomRoutineDayWrite> days,
  }) async {
    final existingIndex = _routines.indexWhere(
      (entry) => entry.id == routine.id,
    );
    if (existingIndex >= 0) {
      _routines[existingIndex] = routine;
    } else {
      _routines.add(routine);
    }

    final existingDayIds = _days
        .where((day) => day.routineId == routine.id)
        .map((day) => day.id)
        .toSet();
    _days.removeWhere((day) => day.routineId == routine.id);
    _exercises.removeWhere(
      (exercise) => existingDayIds.contains(exercise.dayId),
    );

    _days.addAll(days.map((entry) => entry.day));
    _exercises.addAll(days.expand((entry) => entry.exercises));
    _changes.add(null);
  }

  @override
  Future<int> deleteRoutine({
    required String sessionId,
    required String routineId,
  }) async {
    final before = _routines.length;
    _routines.removeWhere(
      (routine) => routine.sessionId == sessionId && routine.id == routineId,
    );
    final deleted = before - _routines.length;
    if (deleted == 0) {
      return 0;
    }
    final dayIds = _days
        .where((day) => day.routineId == routineId)
        .map((day) => day.id)
        .toSet();
    _days.removeWhere((day) => day.routineId == routineId);
    _exercises.removeWhere((exercise) => dayIds.contains(exercise.dayId));
    _changes.add(null);
    return deleted;
  }

  void dispose() {
    _changes.close();
  }

  List<CustomRoutineWithDays> _query(String sessionId) {
    final routines =
        _routines.where((routine) => routine.sessionId == sessionId).toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return routines.map((routine) {
      final days = _days.where((day) => day.routineId == routine.id).toList()
        ..sort((a, b) => a.dayIndex.compareTo(b.dayIndex));
      return CustomRoutineWithDays(
        routine: routine,
        days: days.map((day) {
          final exercises =
              _exercises.where((exercise) => exercise.dayId == day.id).toList()
                ..sort((a, b) => a.slotIndex.compareTo(b.slotIndex));
          return CustomRoutineDayWithExercises(day: day, exercises: exercises);
        }).toList(),
      );
    }).toList();
  }
}
