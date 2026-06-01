import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_trainner_core_domain/smart_trainner_core_domain.dart';
import 'package:smart_trainner_core_model/smart_trainner_core_model.dart';
import 'package:smart_trainner_feature_workout_domain/smart_trainner_feature_workout_domain.dart'
    as workout_domain;
import 'package:smart_trainner_feature_workout_impl/smart_trainner_feature_workout_impl.dart';

void main() {
  final fixedNow = DateTime.utc(2026, 5, 24, 12);
  late FakeTrainingRepository repository;

  setUp(() {
    repository = FakeTrainingRepository();
  });

  tearDown(() {
    repository.dispose();
  });

  WorkoutRecordingViewModel viewModel() {
    return WorkoutRecordingViewModel(
      observeWorkoutLogs: ObserveWorkoutLogsUseCase(repository),
      observeLatestWorkoutLogs: ObserveLatestWorkoutLogsUseCase(repository),
      getLatestWorkoutLog: workout_domain.GetLatestWorkoutLogUseCase(
        repository,
      ),
      saveWorkoutLog: workout_domain.SaveWorkoutLogUseCase(repository),
      now: () => fixedNow,
    );
  }

  test(
    'updatePlannedExercise prefills set count reps and weight from latest log',
    () async {
      repository.setLogs(<WorkoutLog>[
        repository.completedLog(
          performedAt: DateTime.utc(2026, 5, 19, 7),
          setEntries: const <WorkoutSetLog>[
            WorkoutSetLog(
              order: 1,
              reps: 7,
              weightKg: 42.5,
              durationMinutes: null,
            ),
            WorkoutSetLog(
              order: 2,
              reps: 8,
              weightKg: 45,
              durationMinutes: null,
              restSeconds: 120,
            ),
            WorkoutSetLog(
              order: 3,
              reps: 6,
              weightKg: 47.5,
              durationMinutes: null,
              restSeconds: 150,
            ),
            WorkoutSetLog(
              order: 4,
              reps: 5,
              weightKg: 50,
              durationMinutes: null,
              restSeconds: 180,
            ),
          ],
        ),
      ]);
      final vm = viewModel();
      addTearDown(vm.dispose);

      await vm.updatePlannedExercise(repository.plannedExercise);

      final setEntries = vm.state.recordForm.setEntries;
      expect(setEntries.map((entry) => entry.reps), <String>[
        '7',
        '8',
        '6',
        '5',
      ]);
      expect(setEntries.map((entry) => entry.weightKg), <String>[
        '42.5',
        '45',
        '47.5',
        '50',
      ]);
      expect(setEntries.map((entry) => entry.restSeconds), <String>[
        '90',
        '120',
        '150',
        '180',
      ]);
    },
  );

  test(
    'saveRecord persists workout log and reports saved planned exercise',
    () async {
      final vm = viewModel();
      addTearDown(vm.dispose);
      PlannedExercise? savedPlanned;

      await vm.updatePlannedExercise(repository.plannedExercise);
      await vm.saveRecord((planned) => savedPlanned = planned);

      final input = repository.savedInputs.single;
      expect(savedPlanned, repository.plannedExercise);
      expect(input.plannedExerciseId, repository.plannedExercise.id);
      expect(input.exerciseId, repository.plannedExercise.exercise.id);
      expect(input.performedAt, fixedNow);
      expect(input.sets, 3);
      expect(input.reps, 8);
      expect(input.setEntries, hasLength(3));
    },
  );

  test('clearRecording resets dialog state', () async {
    final vm = viewModel();
    addTearDown(vm.dispose);

    await vm.updatePlannedExercise(repository.plannedExercise);
    vm.updateSetReps(index: 0, value: '12');
    vm.clearRecording();

    final state = vm.state;
    expect(state.recordingPlannedExercise, isNull);
    expect(state.recordForm.setEntries, isEmpty);
    expect(state.formError, isNull);
    expect(state.recordSaved, isFalse);
  });
}

class FakeTrainingRepository
    implements WorkoutLogRepository, workout_domain.WorkoutRecordingRepository {
  FakeTrainingRepository();

  final plannedExercise = PlannedExercise(
    id: const PlannedExerciseId('planned_chest_press'),
    exercise: const Exercise(
      id: ExerciseId('chest_press'),
      name: 'Chest press',
      muscleGroup: MuscleGroup.chest,
      equipment: EquipmentType.machine,
      difficulty: DifficultyLevel.intermediate,
      imageKey: 'chest_press',
      summary: '',
      instructions: <String>[],
      safetyCues: <String>[],
      defaultSets: 3,
      defaultRepRange: RepRange(8, 12),
      defaultDurationMinutes: null,
      restSeconds: 90,
    ),
    sets: 3,
    repRange: const RepRange(8, 12),
    durationMinutes: null,
    restSeconds: 90,
    note: '',
  );

  final savedInputs = <WorkoutLogInput>[];
  final _logController = StreamController<List<WorkoutLog>>.broadcast();
  var _logs = <WorkoutLog>[];

  void setLogs(List<WorkoutLog> value) {
    _logs = value;
    _logController.add(_logs);
  }

  WorkoutLog completedLog({
    required DateTime performedAt,
    required List<WorkoutSetLog> setEntries,
  }) {
    return WorkoutLog(
      id: const WorkoutLogId(1),
      sessionId: const UserSessionId('local-default'),
      plannedExerciseId: plannedExercise.id,
      exerciseId: plannedExercise.exercise.id,
      performedAt: performedAt,
      sets: setEntries.length,
      reps: setEntries.where((entry) => entry.reps != null).firstOrNull?.reps,
      weightKg: setEntries
          .where((entry) => entry.weightKg != null)
          .firstOrNull
          ?.weightKg,
      durationMinutes: null,
      memo: '',
      completed: true,
      setEntries: setEntries,
    );
  }

  @override
  Stream<List<WorkoutLog>> observeWorkoutLogs(DateTime weekStartDate) async* {
    yield _logs;
    yield* _logController.stream;
  }

  @override
  Stream<List<WorkoutLog>> observeLatestWorkoutLogs() async* {
    yield _logs;
    yield* _logController.stream;
  }

  @override
  Future<WorkoutLog?> getLatestWorkoutLog(ExerciseId exerciseId) async {
    final logs = _logs.where((log) => log.exerciseId == exerciseId).toList()
      ..sort((a, b) => b.performedAt.compareTo(a.performedAt));
    return logs.isEmpty ? null : logs.first;
  }

  @override
  Future<OperationResult<void>> saveWorkoutLog(WorkoutLogInput input) async {
    savedInputs.add(input);
    return OperationResult.success();
  }

  void dispose() {
    _logController.close();
  }
}

extension _IterableFirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => this.isEmpty ? null : first;
}
