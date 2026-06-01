import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_trainner_core_domain/smart_trainner_core_domain.dart';
import 'package:smart_trainner_core_model/smart_trainner_core_model.dart';
import 'package:smart_trainner_feature_exercise_domain/smart_trainner_feature_exercise_domain.dart'
    as exercise_domain;
import 'package:smart_trainner_feature_exercise_impl/smart_trainner_feature_exercise_impl.dart';

void main() {
  late FakeExerciseRepository repository;

  setUp(() {
    repository = FakeExerciseRepository();
  });

  tearDown(() {
    repository.dispose();
  });

  ExerciseDetailViewModel viewModel() {
    return ExerciseDetailViewModel(
      observeLatestWorkoutLogs: ObserveLatestWorkoutLogsUseCase(repository),
      getExercise: exercise_domain.GetExerciseUseCase(repository),
    );
  }

  test('updateSelection loads exercise and latest workout log', () async {
    final olderLog = workoutLog(
      id: 1,
      exerciseId: const ExerciseId('chest_press'),
      performedAt: DateTime(2026, 5, 23, 9),
    );
    final latestLog = workoutLog(
      id: 2,
      exerciseId: const ExerciseId('chest_press'),
      performedAt: DateTime(2026, 5, 24, 9),
    );
    repository.setLatestLogs(<WorkoutLog>[olderLog, latestLog]);
    final vm = viewModel();
    addTearDown(vm.dispose);

    await vm.updateSelection(
      const ExerciseId('chest_press'),
      shouldShowRecordAction: true,
    );

    expect(vm.state.exercise?.id.value, 'chest_press');
    expect(vm.state.latestWorkoutLog?.id, latestLog.id);
    expect(vm.state.showRecordAction, isTrue);
  });

  test('updateSelection null clears detail state', () async {
    final vm = viewModel();
    addTearDown(vm.dispose);

    await vm.updateSelection(
      const ExerciseId('chest_press'),
      shouldShowRecordAction: true,
    );
    await vm.updateSelection(null, shouldShowRecordAction: true);

    expect(vm.state.exercise, isNull);
    expect(vm.state.latestWorkoutLog, isNull);
    expect(vm.state.showRecordAction, isFalse);
  });
}

class FakeExerciseRepository
    implements ExerciseRepository, WorkoutLogRepository {
  final _latestLogController = StreamController<List<WorkoutLog>>.broadcast();
  final _exercises = <Exercise>[
    exercise('chest_press', MuscleGroup.chest),
    exercise('back_pull', MuscleGroup.back),
  ];
  var _latestLogs = <WorkoutLog>[];

  void setLatestLogs(List<WorkoutLog> value) {
    _latestLogs = value;
    _latestLogController.add(value);
  }

  @override
  Stream<List<WorkoutLog>> observeLatestWorkoutLogs() async* {
    yield _latestLogs;
    yield* _latestLogController.stream;
  }

  @override
  Stream<List<WorkoutLog>> observeWorkoutLogs(DateTime weekStartDate) {
    throw UnsupportedError('Not used by exercise detail tests');
  }

  @override
  Future<Exercise?> getExercise(ExerciseId id) async {
    return _exercises.where((exercise) => exercise.id == id).firstOrNull;
  }

  @override
  Stream<List<Exercise>> observeExercises() {
    throw UnsupportedError('Not used by exercise detail tests');
  }

  void dispose() {
    _latestLogController.close();
  }
}

extension _IterableFirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => this.isEmpty ? null : first;
}

Exercise exercise(String id, MuscleGroup muscleGroup) {
  return Exercise(
    id: ExerciseId(id),
    name: id,
    muscleGroup: muscleGroup,
    equipment: EquipmentType.machine,
    difficulty: DifficultyLevel.intermediate,
    imageKey: id,
    summary: '',
    instructions: const <String>[],
    safetyCues: const <String>[],
    defaultSets: 3,
    defaultRepRange: const RepRange(8, 12),
    defaultDurationMinutes: null,
    restSeconds: 90,
  );
}

WorkoutLog workoutLog({
  required int id,
  required ExerciseId exerciseId,
  required DateTime performedAt,
}) {
  return WorkoutLog(
    id: WorkoutLogId(id),
    sessionId: const UserSessionId('local-default'),
    plannedExerciseId: PlannedExerciseId('planned_${exerciseId.value}'),
    exerciseId: exerciseId,
    performedAt: performedAt,
    sets: 3,
    reps: 8,
    weightKg: 40,
    durationMinutes: null,
    memo: '',
    completed: true,
  );
}
