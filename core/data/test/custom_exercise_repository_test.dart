import 'package:smart_trainner_core_data/smart_trainner_core_data.dart';
import 'package:smart_trainner_core_database/smart_trainner_core_database.dart';
import 'package:smart_trainner_core_datastore/smart_trainner_core_datastore.dart';
import 'package:smart_trainner_core_domain/smart_trainner_core_domain.dart';
import 'package:smart_trainner_core_model/smart_trainner_core_model.dart';
import 'package:test/test.dart';

void main() {
  late TrainingPreferencesDataSource preferences;
  late InMemoryCustomExerciseDao customExerciseDao;
  late InMemoryWorkoutLogDao workoutLogDao;
  late DefaultTrainingRepository repository;

  setUp(() {
    preferences = TrainingPreferencesDataSource();
    customExerciseDao = InMemoryCustomExerciseDao();
    workoutLogDao = InMemoryWorkoutLogDao();
    repository = DefaultTrainingRepository(
      customExerciseDao: customExerciseDao,
      workoutLogDao: workoutLogDao,
      preferences: preferences,
      summaryCalculator: WeeklySummaryCalculator(),
    );
  });

  tearDown(() {
    customExerciseDao.dispose();
    workoutLogDao.dispose();
    preferences.dispose();
  });

  test('createCustomExercise stores owner metadata from active user', () async {
    await preferences.startSession(_session('user-a'));

    final result = await repository.createCustomExercise(
      _input('Custom Hinge'),
    );

    expect(result.isSuccess, isTrue);
    expect(result.value?.metadata.source, ExerciseSource.userCreated);
    expect(result.value?.metadata.ownerUserId, 'user-a');
    expect(result.value?.metadata.originExerciseId, isNull);
    expect(result.value?.imagePath, isNull);
  });

  test('observeExercises keeps custom exercises isolated by owner', () async {
    await preferences.startSession(_session('user-a'));
    final userAExercise = await repository.createCustomExercise(
      _input('Custom Hinge'),
    );

    await preferences.startSession(_session('user-b'));
    final userBExercise = await repository.createCustomExercise(
      _input('Custom Hinge'),
    );

    final userBExercises = await repository.observeExercises().first;
    expect(
      userBExercises.map((exercise) => exercise.id),
      contains(userBExercise.value?.id),
    );
    expect(
      userBExercises.map((exercise) => exercise.id),
      isNot(contains(userAExercise.value?.id)),
    );
    expect(
      userBExercises.map((exercise) => exercise.id.value),
      contains('leg_press'),
    );

    await preferences.startSession(_session('user-a'));
    final userAExercises = await repository.observeExercises().first;
    expect(
      userAExercises.map((exercise) => exercise.id),
      contains(userAExercise.value?.id),
    );
    expect(
      userAExercises.map((exercise) => exercise.id),
      isNot(contains(userBExercise.value?.id)),
    );
  });
}

UserSession _session(String id) {
  return UserSession(
    id: UserSessionId(id),
    displayName: id,
    email: null,
    provider: AuthProvider.local,
    linkedAt: null,
  );
}

CustomExerciseInput _input(String name) {
  return CustomExerciseInput(
    name: name,
    muscleGroup: MuscleGroup.lowerBody,
    equipment: EquipmentType.dumbbell,
    difficulty: DifficultyLevel.beginner,
    summary: 'A custom posterior-chain movement.',
    instructions: const <String>['Hinge at the hips.'],
    safetyCues: const <String>['Keep the spine neutral.'],
    defaultSets: 3,
    defaultRepRange: const RepRange(8, 12),
    defaultDurationMinutes: null,
    restSeconds: 60,
    imagePath: null,
  );
}
