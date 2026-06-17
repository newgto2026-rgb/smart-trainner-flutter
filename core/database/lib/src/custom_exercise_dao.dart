import 'dart:async';

import 'package:smart_trainner_core_database/src/custom_exercise_entity.dart';

abstract interface class CustomExerciseDao {
  Stream<List<CustomExerciseEntity>> observeAll();

  Stream<List<CustomExerciseEntity>> observeByOwner(String ownerUserId);

  Future<CustomExerciseEntity?> getById(String id);

  Future<void> upsert(CustomExerciseEntity exercise);
}

class InMemoryCustomExerciseDao implements CustomExerciseDao {
  final _changes = StreamController<void>.broadcast();
  final _exercises = <CustomExerciseEntity>[];

  @override
  Stream<List<CustomExerciseEntity>> observeAll() {
    late final StreamController<List<CustomExerciseEntity>> controller;
    StreamSubscription<void>? subscription;

    controller = StreamController<List<CustomExerciseEntity>>.broadcast(
      onListen: () {
        controller.add(_queryAll());
        subscription = _changes.stream.listen((_) {
          if (!controller.isClosed) {
            controller.add(_queryAll());
          }
        });
      },
      onCancel: () async {
        await subscription?.cancel();
      },
    );

    return controller.stream;
  }

  @override
  Stream<List<CustomExerciseEntity>> observeByOwner(String ownerUserId) {
    late final StreamController<List<CustomExerciseEntity>> controller;
    StreamSubscription<void>? subscription;

    controller = StreamController<List<CustomExerciseEntity>>.broadcast(
      onListen: () {
        controller.add(_queryByOwner(ownerUserId));
        subscription = _changes.stream.listen((_) {
          if (!controller.isClosed) {
            controller.add(_queryByOwner(ownerUserId));
          }
        });
      },
      onCancel: () async {
        await subscription?.cancel();
      },
    );

    return controller.stream;
  }

  @override
  Future<CustomExerciseEntity?> getById(String id) async {
    for (final exercise in _exercises) {
      if (exercise.id == id) {
        return exercise;
      }
    }
    return null;
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
