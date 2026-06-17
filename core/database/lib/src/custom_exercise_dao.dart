import 'dart:async';

import 'package:smart_trainner_core_database/src/custom_exercise_entity.dart';

abstract interface class CustomExerciseDao {
  Stream<List<CustomExerciseEntity>> observeAll();

  Stream<List<CustomExerciseEntity>> observeByOwner(String ownerUserId);

  Future<void> upsert(CustomExerciseEntity exercise);
}

class InMemoryCustomExerciseDao implements CustomExerciseDao {
  final _changes = StreamController<void>.broadcast();
  final _exercises = <CustomExerciseEntity>[];

  @override
  Stream<List<CustomExerciseEntity>> observeAll() async* {
    yield _queryAll();
    await for (final _ in _changes.stream) {
      yield _queryAll();
    }
  }

  @override
  Stream<List<CustomExerciseEntity>> observeByOwner(String ownerUserId) async* {
    yield _queryByOwner(ownerUserId);
    await for (final _ in _changes.stream) {
      yield _queryByOwner(ownerUserId);
    }
  }

  @override
  Future<void> upsert(CustomExerciseEntity exercise) async {
    final existingIndex = _exercises.indexWhere(
      (existing) => existing.id == exercise.id,
    );
    if (existingIndex >= 0) {
      _exercises[existingIndex] = exercise;
    } else {
      _exercises.add(exercise);
    }
    _changes.add(null);
  }

  void dispose() {
    _changes.close();
  }

  List<CustomExerciseEntity> _queryByOwner(String ownerUserId) {
    return (_queryAll()
        .where((exercise) => exercise.ownerUserId == ownerUserId)
        .toList());
  }

  List<CustomExerciseEntity> _queryAll() {
    return List<CustomExerciseEntity>.of(_exercises)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }
}
