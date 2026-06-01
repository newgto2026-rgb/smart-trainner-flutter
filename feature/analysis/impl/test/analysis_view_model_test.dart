import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_trainner_core_domain/smart_trainner_core_domain.dart';
import 'package:smart_trainner_core_model/smart_trainner_core_model.dart';
import 'package:smart_trainner_feature_analysis_domain/smart_trainner_feature_analysis_domain.dart'
    as analysis_domain;
import 'package:smart_trainner_feature_analysis_impl/smart_trainner_feature_analysis_impl.dart';

void main() {
  final fixedNow = DateTime.utc(2026, 5, 24, 12);
  late FakeAnalysisRepository repository;

  setUp(() {
    repository = FakeAnalysisRepository();
  });

  tearDown(() {
    repository.dispose();
  });

  AnalysisViewModel viewModel([DateTime Function()? now]) {
    return AnalysisViewModel(
      observeLatestWorkoutLogs: ObserveLatestWorkoutLogsUseCase(repository),
      observeWeeklySummary: analysis_domain.ObserveWeeklySummaryUseCase(
        repository,
      ),
      observeExercises: ObserveExercisesUseCase(repository),
      now: now ?? (() => fixedNow),
    );
  }

  test('uiState exposes latest three recent logs', () async {
    final oldest = workoutLog(
      id: 1,
      exerciseId: 'chest_press',
      performedAt: DateTime(2026, 5, 21, 9),
    );
    final secondLatest = workoutLog(
      id: 2,
      exerciseId: 'back_pull',
      performedAt: DateTime(2026, 5, 23, 9),
    );
    final latest = workoutLog(
      id: 3,
      exerciseId: 'leg_press',
      performedAt: DateTime(2026, 5, 24, 9),
    );
    final thirdLatest = workoutLog(
      id: 4,
      exerciseId: 'shoulder_raise',
      performedAt: DateTime(2026, 5, 22, 9),
    );
    repository.setLatestLogs(<WorkoutLog>[
      oldest,
      secondLatest,
      latest,
      thirdLatest,
    ]);
    final vm = viewModel();
    addTearDown(vm.dispose);
    await Future<void>.delayed(Duration.zero);

    expect(
      vm.state.recentLogs.map((entry) => entry.log.performedAt),
      <DateTime>[
        latest.performedAt,
        secondLatest.performedAt,
        thirdLatest.performedAt,
      ],
    );
    expect(vm.state.recentLogs.map((entry) => entry.exercise?.id), <ExerciseId>[
      latest.exerciseId,
      secondLatest.exerciseId,
      thirdLatest.exerciseId,
    ]);
  });

  test('uiState requests weekly summary for current week', () async {
    final vm = viewModel();
    addTearDown(vm.dispose);
    await Future<void>.delayed(Duration.zero);

    expect(repository.requestedWeekStartDates, <DateTime>[
      DateTime(2026, 5, 18),
    ]);
    expect(vm.state.summary?.weekStartDate, DateTime(2026, 5, 18));
  });

  test('uiState recomputes week start when collection restarts', () async {
    var now = DateTime.utc(2026, 5, 24, 12);
    final vm = viewModel(() => now);
    addTearDown(vm.dispose);
    await Future<void>.delayed(Duration.zero);

    expect(vm.state.summary?.weekStartDate, DateTime(2026, 5, 18));

    now = DateTime.utc(2026, 5, 25, 12);
    vm.refreshWeekStart();
    await Future<void>.delayed(Duration.zero);

    expect(vm.state.summary?.weekStartDate, DateTime(2026, 5, 25));
    expect(
      repository.requestedWeekStartDates,
      containsAll(<DateTime>[DateTime(2026, 5, 18), DateTime(2026, 5, 25)]),
    );
  });
}

class FakeAnalysisRepository
    implements
        ExerciseRepository,
        analysis_domain.WeeklySummaryRepository,
        WorkoutLogRepository {
  final _latestLogController = StreamController<List<WorkoutLog>>.broadcast();
  final _summaryController = StreamController<WeeklySummary>.broadcast();
  final requestedWeekStartDates = <DateTime>[];
  final _exercises = <Exercise>[
    exercise('back_pull', MuscleGroup.back),
    exercise('chest_press', MuscleGroup.chest),
    exercise('leg_press', MuscleGroup.lowerBody),
    exercise('shoulder_raise', MuscleGroup.shoulders),
  ];
  var _latestLogs = <WorkoutLog>[];
  var _summary = summary(DateTime(2026, 5, 18));

  void setLatestLogs(List<WorkoutLog> value) {
    _latestLogs = value;
    _latestLogController.add(value);
  }

  @override
  Stream<List<Exercise>> observeExercises() async* {
    yield _exercises;
  }

  @override
  Stream<List<WorkoutLog>> observeLatestWorkoutLogs() async* {
    yield _latestLogs;
    yield* _latestLogController.stream;
  }

  @override
  Stream<WeeklySummary> observeWeeklySummary(DateTime weekStartDate) async* {
    requestedWeekStartDates.add(weekStartDate);
    _summary = summary(weekStartDate);
    yield _summary;
    yield* _summaryController.stream;
  }

  @override
  Stream<List<WorkoutLog>> observeWorkoutLogs(DateTime weekStartDate) {
    throw UnsupportedError('Not used');
  }

  @override
  Future<Exercise?> getExercise(ExerciseId id) {
    throw UnsupportedError('Not used');
  }

  void dispose() {
    _latestLogController.close();
    _summaryController.close();
  }
}

WorkoutLog workoutLog({
  required int id,
  required String exerciseId,
  required DateTime performedAt,
}) {
  return WorkoutLog(
    id: WorkoutLogId(id),
    sessionId: const UserSessionId('local-default'),
    plannedExerciseId: PlannedExerciseId('planned_$exerciseId'),
    exerciseId: ExerciseId(exerciseId),
    performedAt: performedAt,
    sets: 3,
    reps: 10,
    weightKg: null,
    durationMinutes: null,
    memo: '',
    completed: true,
  );
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

WeeklySummary summary(DateTime weekStartDate) {
  return WeeklySummary(
    weekStartDate: weekStartDate,
    plannedExerciseCount: 4,
    completedExerciseCount: 0,
    totalSets: 0,
    totalVolumeKg: 0,
    totalMinutes: 0,
    streakDays: 0,
    muscleBalance: const <MuscleGroup, int>{},
    insight: '',
  );
}
