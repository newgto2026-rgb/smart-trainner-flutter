import 'package:smart_trainner_core_model/smart_trainner_core_model.dart';
import 'package:test/test.dart';

void main() {
  test('seed exercise metadata is the default', () {
    final exercise = _exercise();

    expect(exercise.metadata.source, ExerciseSource.seed);
    expect(exercise.metadata.ownerUserId, isNull);
    expect(exercise.metadata.isSeed, isTrue);
    expect(exercise.metadata.isOwnedLibraryItem, isFalse);
  });

  test('user created metadata keeps owner separate from origin fields', () {
    const metadata = ExerciseSourceMetadata.userCreated(ownerUserId: 'user-a');

    expect(metadata.source, ExerciseSource.userCreated);
    expect(metadata.ownerUserId, 'user-a');
    expect(metadata.originExerciseId, isNull);
    expect(metadata.sourceOwnerUserId, isNull);
    expect(metadata.sourceShareId, isNull);
    expect(metadata.isOwnedLibraryItem, isTrue);
  });
}

Exercise _exercise() {
  return Exercise(
    id: const ExerciseId('leg_press'),
    name: '레그 프레스',
    muscleGroup: MuscleGroup.lowerBody,
    equipment: EquipmentType.machine,
    difficulty: DifficultyLevel.beginner,
    imageKey: 'leg_press',
    summary: '하체 기본 운동입니다.',
    instructions: const <String>['발을 밀어냅니다.'],
    safetyCues: const <String>['무릎을 잠그지 않습니다.'],
    defaultSets: 3,
    defaultRepRange: const RepRange(8, 12),
    defaultDurationMinutes: null,
    restSeconds: 60,
  );
}
