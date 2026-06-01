import 'package:smart_trainner_core_database/smart_trainner_core_database.dart';
import 'package:test/test.dart';

void main() {
  late InMemoryWorkoutLogDao dao;

  setUp(() {
    dao = InMemoryWorkoutLogDao();
  });

  tearDown(() {
    dao.dispose();
  });

  test('upsertWithSets stores variable set rows', () async {
    await dao.upsertWithSets(
      log: const WorkoutLogEntity(
        sessionId: 'local-default',
        plannedExerciseId: '2026-05-20_leg_press',
        exerciseId: 'leg_press',
        performedDate: '2026-05-20',
        performedAt: '2026-05-20T09:00:00',
        sets: 4,
        reps: 10,
        weightKg: 20,
        durationMinutes: null,
        memo: '',
        completed: true,
      ),
      setLogs: const <WorkoutSetLogEntity>[
        WorkoutSetLogEntity(
          workoutLogId: 0,
          setIndex: 1,
          reps: 10,
          weightKg: 20,
          durationMinutes: null,
          restSeconds: 60,
        ),
        WorkoutSetLogEntity(
          workoutLogId: 0,
          setIndex: 2,
          reps: 10,
          weightKg: 25,
          durationMinutes: null,
          restSeconds: 90,
        ),
        WorkoutSetLogEntity(
          workoutLogId: 0,
          setIndex: 3,
          reps: 8,
          weightKg: 30,
          durationMinutes: null,
          restSeconds: 120,
        ),
        WorkoutSetLogEntity(
          workoutLogId: 0,
          setIndex: 4,
          reps: 8,
          weightKg: 32.5,
          durationMinutes: null,
          restSeconds: 150,
        ),
      ],
    );

    final result = await dao
        .observeBetween(
          sessionId: 'local-default',
          startDate: '2026-05-20',
          endDate: '2026-05-20',
        )
        .first;

    expect(result, hasLength(1));
    expect(result.single.setLogs.map((log) => log.setIndex), <int>[1, 2, 3, 4]);
    expect(result.single.setLogs.map((log) => log.weightKg), <double>[
      20,
      25,
      30,
      32.5,
    ]);
    expect(result.single.setLogs.map((log) => log.restSeconds), <int>[
      60,
      90,
      120,
      150,
    ]);
  });

  test('observeBetween filters by session', () async {
    const log = WorkoutLogEntity(
      sessionId: 'local-default',
      plannedExerciseId: '2026-05-20_leg_press',
      exerciseId: 'leg_press',
      performedDate: '2026-05-20',
      performedAt: '2026-05-20T09:00:00',
      sets: 1,
      reps: 10,
      weightKg: 20,
      durationMinutes: null,
      memo: '',
      completed: true,
    );
    await dao.upsertWithSets(log: log, setLogs: const <WorkoutSetLogEntity>[]);
    await dao.upsertWithSets(
      log: log.copyWith(sessionId: 'google-user-1'),
      setLogs: const <WorkoutSetLogEntity>[],
    );

    final localLogs = await dao
        .observeBetween(
          sessionId: 'local-default',
          startDate: '2026-05-20',
          endDate: '2026-05-20',
        )
        .first;

    expect(localLogs, hasLength(1));
    expect(localLogs.single.log.sessionId, 'local-default');
  });

  test('latestByExercise returns most recent matching log with sets', () async {
    const oldLog = WorkoutLogEntity(
      sessionId: 'local-default',
      plannedExerciseId: '2026-05-20_leg_press',
      exerciseId: 'leg_press',
      performedDate: '2026-05-20',
      performedAt: '2026-05-20T09:00:00',
      sets: 1,
      reps: 10,
      weightKg: 20,
      durationMinutes: null,
      memo: '',
      completed: true,
    );
    final latestLog = oldLog.copyWith(
      plannedExerciseId: '2026-05-27_leg_press',
      performedDate: '2026-05-27',
      performedAt: '2026-05-27T09:00:00',
      reps: 8,
      weightKg: 30,
    );

    await dao.upsertWithSets(
      log: oldLog,
      setLogs: const <WorkoutSetLogEntity>[
        WorkoutSetLogEntity(
          workoutLogId: 0,
          setIndex: 1,
          reps: 10,
          weightKg: 20,
          durationMinutes: null,
        ),
      ],
    );
    await dao.upsertWithSets(
      log: latestLog,
      setLogs: const <WorkoutSetLogEntity>[
        WorkoutSetLogEntity(
          workoutLogId: 0,
          setIndex: 1,
          reps: 8,
          weightKg: 30,
          durationMinutes: null,
          restSeconds: 120,
        ),
      ],
    );

    final result = await dao.latestByExercise(
      sessionId: 'local-default',
      exerciseId: 'leg_press',
    );

    expect(result?.log.plannedExerciseId, '2026-05-27_leg_press');
    expect(result?.setLogs.single.reps, 8);
    expect(result?.setLogs.single.weightKg, 30);
    expect(result?.setLogs.single.restSeconds, 120);
  });
}
