import 'package:smart_trainner_core_data/smart_trainner_core_data.dart';
import 'package:smart_trainner_core_model/smart_trainner_core_model.dart';
import 'package:test/test.dart';

void main() {
  test(
    'exercise catalog is large enough for mvp and has safe instruction data',
    () {
      final exercises = SeedTrainingContent.exercises;

      expect(exercises.length, greaterThanOrEqualTo(72));
      expect(
        exercises.map((exercise) => exercise.id.value).toSet().length,
        exercises.length,
      );
      expect(
        exercises.map((exercise) => exercise.muscleGroup).toSet(),
        containsAll(MuscleGroup.values),
      );

      for (final exercise in exercises) {
        expect(exercise.name.trim(), isNotEmpty);
        expect(exercise.summary.trim(), isNotEmpty);
        expect(exercise.instructions.length, greaterThanOrEqualTo(2));
        expect(exercise.instructions.length, lessThanOrEqualTo(5));
        expect(exercise.safetyCues.length, greaterThanOrEqualTo(2));
        expect(exercise.defaultSets, greaterThanOrEqualTo(1));
        expect(exercise.restSeconds, greaterThanOrEqualTo(30));
      }
      expect(
        exercises.map((exercise) => exercise.instructions.length).toSet(),
        containsAll(<int>[2, 3, 4, 5]),
      );
    },
  );

  test('kettlebell catalog covers safe beginner and intermediate patterns', () {
    final kettlebellExercises = SeedTrainingContent.exercises.where(
      (exercise) => exercise.equipment == EquipmentType.kettlebell,
    );
    final ids = kettlebellExercises
        .map((exercise) => exercise.id.value)
        .toList();

    expect(
      ids,
      containsAll(<String>[
        'kettlebell_deadlift',
        'kettlebell_goblet_squat',
        'kettlebell_floor_press',
        'one_arm_kettlebell_row',
        'kettlebell_suitcase_carry',
        'kettlebell_farmer_carry',
        'two_hand_kettlebell_swing',
      ]),
    );
    expect(kettlebellExercises.length, 18);
    expect(
      kettlebellExercises
          .map((exercise) => exercise.instructions.length)
          .toSet(),
      containsAll(<int>[3, 4]),
    );
    expect(ids, isNot(contains('kettlebell_snatch')));
    expect(ids, isNot(contains('turkish_get_up')));
  });

  test('unilateral kettlebell exercises name opposite side completion', () {
    final exercisesById = {
      for (final exercise in SeedTrainingContent.exercises)
        exercise.id.value: exercise,
    };

    for (final exerciseId in <String>[
      'kettlebell_floor_press',
      'kettlebell_shoulder_press',
      'half_kneeling_kettlebell_press',
      'kettlebell_suitcase_carry',
      'kettlebell_rack_carry',
    ]) {
      final exercise = exercisesById[exerciseId]!;
      expect(exercise.instructions.join(' '), contains('반대쪽'));
    }
  });

  test('kettlebell deadlift variants use dedicated image keys', () {
    final exercisesById = {
      for (final exercise in SeedTrainingContent.exercises)
        exercise.id.value: exercise,
    };

    for (final exerciseId in <String>[
      'kettlebell_deadlift',
      'kettlebell_romanian_deadlift',
      'kettlebell_sumo_deadlift',
    ]) {
      final exercise = exercisesById[exerciseId]!;
      expect(exercise.imageKey, exerciseId);
    }
  });

  test('corrected core exercises use dedicated image keys', () {
    final exercisesById = {
      for (final exercise in SeedTrainingContent.exercises)
        exercise.id.value: exercise,
    };

    for (final exerciseId in <String>[
      'dead_bug',
      'pallof_press',
      'cable_crunch',
    ]) {
      final exercise = exercisesById[exerciseId]!;
      expect(exercise.imageKey, exerciseId);
    }
  });

  test('plan templates reference existing exercises only', () {
    final exerciseIds = SeedTrainingContent.exercises
        .map((exercise) => exercise.id)
        .toSet();

    for (final template in SeedTrainingContent.templates) {
      expect(template.days.length, template.daysPerWeek);
      for (final day in template.days) {
        expect(day.exercises, isNotEmpty);
        for (final planned in day.exercises) {
          expect(exerciseIds, contains(planned.exerciseId));
        }
      }
    }
  });
}
