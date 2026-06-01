import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_trainner_core_domain/smart_trainner_core_domain.dart';
import 'package:smart_trainner_core_model/smart_trainner_core_model.dart';
import 'package:smart_trainner_feature_exercise_impl/smart_trainner_feature_exercise_impl.dart';

void main() {
  late FakeExerciseCatalogRepository repository;

  setUp(() {
    repository = FakeExerciseCatalogRepository();
  });

  tearDown(() {
    repository.dispose();
  });

  test('uiState loads exercises and latest logs', () async {
    final exercises = <Exercise>[
      exercise('chest_press', MuscleGroup.chest),
      exercise('back_pull', MuscleGroup.back),
    ];
    final latestLog = workoutLog(
      id: 1,
      exerciseId: const ExerciseId('back_pull'),
      performedAt: DateTime(2026, 5, 24, 9),
    );
    repository.setExercises(exercises);
    repository.setLatestLogs(<WorkoutLog>[latestLog]);
    final viewModel = ExerciseCatalogViewModel(
      observeExercises: ObserveExercisesUseCase(repository),
      observeLatestWorkoutLogs: ObserveLatestWorkoutLogsUseCase(repository),
    );
    addTearDown(viewModel.dispose);
    await Future<void>.delayed(Duration.zero);

    final state = viewModel.state;
    expect(state.exercises, exercises);
    expect(state.latestWorkoutLogs, <WorkoutLog>[latestLog]);
    expect(state.selectedExerciseId, isNull);
  });
}

class FakeExerciseCatalogRepository
    implements ExerciseRepository, WorkoutLogRepository {
  final _exerciseController = StreamController<List<Exercise>>.broadcast();
  final _latestLogController = StreamController<List<WorkoutLog>>.broadcast();
  var _exercises = <Exercise>[];
  var _latestLogs = <WorkoutLog>[];

  void setExercises(List<Exercise> value) {
    _exercises = value;
    _exerciseController.add(value);
  }

  void setLatestLogs(List<WorkoutLog> value) {
    _latestLogs = value;
    _latestLogController.add(value);
  }

  @override
  Stream<List<Exercise>> observeExercises() async* {
    yield _exercises;
    yield* _exerciseController.stream;
  }

  @override
  Stream<List<WorkoutLog>> observeLatestWorkoutLogs() async* {
    yield _latestLogs;
    yield* _latestLogController.stream;
  }

  @override
  Stream<List<WorkoutLog>> observeWorkoutLogs(DateTime weekStartDate) {
    throw UnsupportedError('Not used by exercise catalog tests');
  }

  @override
  Future<Exercise?> getExercise(ExerciseId id) {
    throw UnsupportedError('Not used by exercise catalog tests');
  }

  void dispose() {
    _exerciseController.close();
    _latestLogController.close();
  }
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
