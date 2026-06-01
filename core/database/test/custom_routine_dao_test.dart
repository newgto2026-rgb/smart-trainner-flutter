import 'package:smart_trainner_core_database/smart_trainner_core_database.dart';
import 'package:test/test.dart';

void main() {
  late InMemoryCustomRoutineDao dao;

  setUp(() {
    dao = InMemoryCustomRoutineDao();
  });

  tearDown(() {
    dao.dispose();
  });

  test('upsertFull stores routine days and exercises', () async {
    await dao.upsertFull(
      routine: routineEntity('custom-1', 'local-default'),
      days: <CustomRoutineDayWrite>[
        dayWrite('custom-1', 0, <String>['squat', 'squat']),
        dayWrite('custom-1', 1, <String>['press']),
      ],
    );

    final routines = await dao.observeForSession('local-default').first;

    expect(routines, hasLength(1));
    expect(routines.single.days, hasLength(2));
    expect(
      routines.single.days[0].exercises.map((entry) => entry.slotIndex),
      <int>[0, 1],
    );
    expect(
      routines.single.days[0].exercises.map((entry) => entry.exerciseId),
      <String>['squat', 'squat'],
    );
  });

  test('observeForSession keeps routines isolated by session', () async {
    await dao.upsertFull(
      routine: routineEntity('custom-1', 'local-default'),
      days: <CustomRoutineDayWrite>[
        dayWrite('custom-1', 0, <String>['squat']),
      ],
    );
    await dao.upsertFull(
      routine: routineEntity('custom-2', 'google-user-1'),
      days: <CustomRoutineDayWrite>[
        dayWrite('custom-2', 0, <String>['press']),
      ],
    );

    final localRoutines = await dao.observeForSession('local-default').first;

    expect(localRoutines.map((entry) => entry.routine.id), <String>[
      'custom-1',
    ]);
  });

  test('upsertFull replaces existing days', () async {
    await dao.upsertFull(
      routine: routineEntity('custom-1', 'local-default'),
      days: <CustomRoutineDayWrite>[
        dayWrite('custom-1', 0, <String>['squat']),
        dayWrite('custom-1', 1, <String>['press']),
      ],
    );

    await dao.upsertFull(
      routine: routineEntity('custom-1', 'local-default'),
      days: <CustomRoutineDayWrite>[
        dayWrite('custom-1', 0, <String>['row']),
      ],
    );

    final routines = await dao.observeForSession('local-default').first;

    expect(routines.single.days, hasLength(1));
    expect(routines.single.days.single.exercises.single.exerciseId, 'row');
  });
}

CustomRoutineEntity routineEntity(String id, String sessionId) {
  return CustomRoutineEntity(
    id: id,
    sessionId: sessionId,
    name: 'My routine',
    description: '',
    createdAt: '2026-05-29T00:00:00Z',
    updatedAt: '2026-05-29T00:00:00Z',
  );
}

CustomRoutineDayWrite dayWrite(
  String routineId,
  int dayIndex,
  List<String> exerciseIds,
) {
  final dayId = '$routineId-day-${dayIndex + 1}';
  return CustomRoutineDayWrite(
    day: CustomRoutineDayEntity(
      id: dayId,
      routineId: routineId,
      dayIndex: dayIndex,
      title: '${dayIndex + 1}일차',
      focus: 'focus',
      primaryFocus: 'FULL_BODY',
      secondaryFocuses: '',
      minRecoveryHours: 24,
    ),
    exercises: exerciseIds.indexed.map((entry) {
      final slotIndex = entry.$1;
      final exerciseId = entry.$2;
      return CustomRoutineExerciseEntity(
        id: '$dayId-slot-${slotIndex + 1}',
        dayId: dayId,
        slotIndex: slotIndex,
        exerciseId: exerciseId,
        sets: 3,
        repRangeStart: 8,
        repRangeEnd: 12,
        durationMinutes: null,
        restSeconds: 90,
        note: '',
      );
    }).toList(),
  );
}
