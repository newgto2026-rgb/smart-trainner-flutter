import 'package:smart_trainner_core_database/smart_trainner_core_database.dart';
import 'package:test/test.dart';

void main() {
  late InMemoryCustomExerciseDao dao;

  setUp(() {
    dao = InMemoryCustomExerciseDao();
  });

  tearDown(() {
    dao.dispose();
  });

  test('observeByOwner only emits exercises for the requested owner', () async {
    await dao.upsert(_entity(id: 'custom_a_hinge', ownerUserId: 'user-a'));
    await dao.upsert(_entity(id: 'custom_b_hinge', ownerUserId: 'user-b'));

    final result = await dao.observeByOwner('user-a').first;

    expect(result, hasLength(1));
    expect(result.single.id, 'custom_a_hinge');
    expect(result.single.ownerUserId, 'user-a');
  });

  test(
    'observeAll emits owner scoped rows for repository composition',
    () async {
      await dao.upsert(_entity(id: 'custom_a_hinge', ownerUserId: 'user-a'));
      await dao.upsert(_entity(id: 'custom_b_hinge', ownerUserId: 'user-b'));

      final result = await dao.observeAll().first;

      expect(result.map((exercise) => exercise.id), <String>[
        'custom_a_hinge',
        'custom_b_hinge',
      ]);
    },
  );

  test('getById returns one custom exercise without owner filtering', () async {
    await dao.upsert(_entity(id: 'custom_a_hinge', ownerUserId: 'user-a'));
    await dao.upsert(_entity(id: 'custom_b_hinge', ownerUserId: 'user-b'));

    final result = await dao.getById('custom_b_hinge');

    expect(result, isNotNull);
    expect(result?.ownerUserId, 'user-b');
  });
}

CustomExerciseEntity _entity({
  required String id,
  required String ownerUserId,
}) {
  return CustomExerciseEntity(
    id: id,
    ownerUserId: ownerUserId,
    name: 'Custom Hinge',
    muscleGroup: 'lowerBody',
    equipment: 'dumbbell',
    difficulty: 'beginner',
    imageKey: id,
    imagePath: null,
    summary: 'A custom posterior-chain movement.',
    instructions: const <String>['Hinge at the hips.'],
    safetyCues: const <String>['Keep the spine neutral.'],
    defaultSets: 3,
    defaultRepRangeFirst: 8,
    defaultRepRangeLast: 12,
    defaultDurationMinutes: null,
    restSeconds: 60,
    source: 'userCreated',
    originExerciseId: null,
    sourceOwnerUserId: null,
    sourceShareId: null,
    createdAt: '2026-06-17T09:00:00',
    updatedAt: '2026-06-17T09:00:00',
  );
}
