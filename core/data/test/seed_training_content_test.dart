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
        containsAll(_concreteExerciseGroups()),
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

  test('exercise catalog uses dedicated image keys', () {
    for (final exercise in SeedTrainingContent.exercises) {
      expect(exercise.imageKey, exercise.id.value);
    }
  });

  test('exercise catalog includes popular missing basics', () {
    final exerciseIds = SeedTrainingContent.exercises
        .map((exercise) => exercise.id.value)
        .toList();

    expect(
      exerciseIds,
      containsAll(<String>[
        'bodyweight_squat',
        'pullup',
        'dip',
        'bulgarian_split_squat',
        'barbell_romanian_deadlift',
      ]),
    );
  });

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

  test(
    'arm exercises use specific muscle groups while keeping arms category',
    () {
      final exercisesById = {
        for (final exercise in SeedTrainingContent.exercises)
          exercise.id.value: exercise,
      };

      expect(exercisesById['dumbbell_curl']!.muscleGroup, MuscleGroup.biceps);
      expect(exercisesById['cable_curl']!.muscleGroup, MuscleGroup.biceps);
      expect(exercisesById['hammer_curl']!.muscleGroup, MuscleGroup.biceps);
      expect(
        exercisesById['preacher_curl_machine']!.muscleGroup,
        MuscleGroup.biceps,
      );
      expect(
        exercisesById['triceps_pushdown']!.muscleGroup,
        MuscleGroup.triceps,
      );
      expect(
        exercisesById['overhead_triceps_extension']!.muscleGroup,
        MuscleGroup.triceps,
      );
      expect(
        exercisesById['rope_overhead_triceps']!.muscleGroup,
        MuscleGroup.triceps,
      );
      expect(exercisesById['reverse_curl']!.muscleGroup, MuscleGroup.forearms);

      final armsDay = SeedTrainingContent.templates
          .firstWhere(
            (template) => template.id == 'intermediate-body-part-5day',
          )
          .days
          .firstWhere((day) => day.primaryFocus == RoutineFocus.arms);

      expect(
        armsDay.secondaryFocuses,
        containsAll(<RoutineFocus>[RoutineFocus.biceps, RoutineFocus.triceps]),
      );
    },
  );

  test('plan templates reference existing exercises only', () {
    final exerciseIds = SeedTrainingContent.exercises
        .map((exercise) => exercise.id)
        .toSet();

    for (final template in SeedTrainingContent.templates) {
      expect(template.days.length, template.daysPerWeek);
      expect(template.cycleLength, template.days.length);
      for (final day in template.days) {
        expect(day.exercises, isNotEmpty);
        for (final planned in day.exercises) {
          expect(exerciseIds, contains(planned.exerciseId));
        }
      }
    }
  });

  test('routine preset ids and structures cover mvp', () {
    final templatesById = {
      for (final template in SeedTrainingContent.templates)
        template.id: template,
    };

    expect(
      templatesById.keys,
      containsAll(<String>[
        'beginner-full-body-2day',
        'beginner-full-body-3day',
        'intermediate-balanced-4day',
        'intermediate-body-part-4day-30',
        'intermediate-body-part-4day-60',
        'intermediate-body-part-4day',
      ]),
    );
    expect(
      templatesById['beginner-full-body-2day']!.structure,
      RoutineStructure.fullBody,
    );
    expect(
      templatesById['beginner-full-body-3day']!.structure,
      RoutineStructure.fullBody,
    );
    expect(
      templatesById['intermediate-balanced-4day']!.structure,
      RoutineStructure.balancedSplit,
    );
    expect(
      templatesById['intermediate-body-part-4day']!.structure,
      RoutineStructure.bodyPartSplit,
    );
  });

  test('body part split duration variants change daily exercise count', () {
    final thirty = SeedTrainingContent.templates.firstWhere(
      (template) => template.id == 'intermediate-body-part-4day-30',
    );
    final fortyFive = SeedTrainingContent.templates.firstWhere(
      (template) => template.id == 'intermediate-body-part-4day',
    );
    final sixty = SeedTrainingContent.templates.firstWhere(
      (template) => template.id == 'intermediate-body-part-4day-60',
    );

    expect(thirty.sessionMinutes, 30);
    expect(fortyFive.sessionMinutes, 45);
    expect(sixty.sessionMinutes, 60);
    expect(thirty.days.map((day) => day.exercises.length).toSet(), {4});
    expect(fortyFive.days.map((day) => day.exercises.length).toSet(), {6});
    expect(sixty.days.map((day) => day.exercises.length).toSet(), {7});
  });

  test('body part split presets have focused days and required coverage', () {
    final bodyPartTemplates = SeedTrainingContent.templates.where(
      (template) => template.structure == RoutineStructure.bodyPartSplit,
    );
    final fourDay = SeedTrainingContent.templates.firstWhere(
      (template) => template.id == 'intermediate-body-part-4day',
    );

    for (final template in bodyPartTemplates) {
      for (final day in template.days) {
        expect(day.primaryFocus, isNot(RoutineFocus.fullBody));
        expect(day.minRecoveryHours, greaterThanOrEqualTo(24));
        final bodyPartSecondaryFocuses = day.secondaryFocuses.where(
          (focus) => !_isMovementDirectionFocus(focus),
        );
        if (_isCombinedFocusDay(day)) {
          expect(bodyPartSecondaryFocuses, isNotEmpty);
        } else {
          expect(bodyPartSecondaryFocuses, isEmpty);
        }
      }
      for (final day in template.days.where(
        (day) => day.primaryFocus == RoutineFocus.chest,
      )) {
        expect(day.secondaryFocuses, contains(RoutineFocus.push));
      }
      for (final day in template.days.where(
        (day) => day.primaryFocus == RoutineFocus.back,
      )) {
        expect(day.secondaryFocuses, contains(RoutineFocus.pull));
      }
    }
    expect(
      fourDay.days.map((day) => day.primaryFocus),
      containsAll(<RoutineFocus>[
        RoutineFocus.back,
        RoutineFocus.chest,
        RoutineFocus.lowerBody,
        RoutineFocus.shoulders,
      ]),
    );
    expect(
      fourDay.focusSummary,
      containsAll(<RoutineFocus>[
        RoutineFocus.arms,
        RoutineFocus.biceps,
        RoutineFocus.triceps,
        RoutineFocus.push,
        RoutineFocus.pull,
      ]),
    );
  });

  test('body part split exercises match declared focuses and ratio', () {
    final exercisesById = {
      for (final exercise in SeedTrainingContent.exercises)
        exercise.id: exercise,
    };
    final bodyPartTemplates = SeedTrainingContent.templates.where(
      (template) => template.structure == RoutineStructure.bodyPartSplit,
    );

    for (final template in bodyPartTemplates) {
      for (final day in template.days) {
        final primaryFocus = day.primaryFocus!;
        final declaredFocuses = <RoutineFocus>{
          primaryFocus,
          ...day.secondaryFocuses,
        };
        final allowedGroups = declaredFocuses
            .expand(_allowedMuscleGroups)
            .toSet();
        final groups = day.exercises
            .map((planned) => exercisesById[planned.exerciseId]!.muscleGroup)
            .toList();
        final primaryGroups = _allowedMuscleGroups(primaryFocus);
        final primaryCount = groups
            .where((group) => primaryGroups.contains(group))
            .length;

        for (final group in groups) {
          expect(allowedGroups, contains(group));
        }
        if (_isCombinedFocusDay(day)) {
          for (final focus in day.secondaryFocuses) {
            expect(
              groups
                  .where((group) => _allowedMuscleGroups(focus).contains(group))
                  .length,
              greaterThanOrEqualTo(1),
            );
          }
          expect(primaryCount / groups.length, greaterThanOrEqualTo(0.50));
        } else {
          expect(primaryCount, groups.length);
        }
      }
    }
  });

  test('balanced split upper days use upper body focus', () {
    final balanced = SeedTrainingContent.templates.firstWhere(
      (template) => template.id == 'intermediate-balanced-4day',
    );
    final upperDays = balanced.days.where((day) => day.title.startsWith('상체'));

    expect(
      upperDays.map((day) => day.primaryFocus),
      orderedEquals(<RoutineFocus>[
        RoutineFocus.upperBody,
        RoutineFocus.upperBody,
      ]),
    );
  });

  test('beginner templates do not include high frequency body part split', () {
    final riskyBeginnerTemplates = SeedTrainingContent.templates.where(
      (template) =>
          template.recommendedExperience == TrainingExperience.beginner &&
          template.structure == RoutineStructure.bodyPartSplit &&
          template.daysPerWeek >= 5,
    );

    expect(riskyBeginnerTemplates, isEmpty);
  });
}

bool _isCombinedFocusDay(PlanTemplateDay day) => day.title.contains('+');

Set<MuscleGroup> _allowedMuscleGroups(RoutineFocus focus) {
  switch (focus) {
    case RoutineFocus.fullBody:
      return MuscleGroup.values.toSet();
    case RoutineFocus.upperBody:
      return {
        MuscleGroup.chest,
        MuscleGroup.back,
        MuscleGroup.shoulders,
        MuscleGroup.arms,
        MuscleGroup.biceps,
        MuscleGroup.triceps,
        MuscleGroup.forearms,
      };
    case RoutineFocus.push:
      return {MuscleGroup.chest, MuscleGroup.shoulders, MuscleGroup.triceps};
    case RoutineFocus.pull:
      return {MuscleGroup.back, MuscleGroup.biceps, MuscleGroup.forearms};
    case RoutineFocus.chest:
      return {MuscleGroup.chest};
    case RoutineFocus.back:
      return {MuscleGroup.back};
    case RoutineFocus.lowerBody:
      return {MuscleGroup.lowerBody};
    case RoutineFocus.shoulders:
      return {MuscleGroup.shoulders};
    case RoutineFocus.arms:
      return {
        MuscleGroup.arms,
        MuscleGroup.biceps,
        MuscleGroup.triceps,
        MuscleGroup.forearms,
      };
    case RoutineFocus.biceps:
      return {MuscleGroup.biceps};
    case RoutineFocus.triceps:
      return {MuscleGroup.triceps};
    case RoutineFocus.forearms:
      return {MuscleGroup.forearms};
    case RoutineFocus.cardioConditioning:
      return {MuscleGroup.cardio};
    case RoutineFocus.core:
      return {MuscleGroup.core};
  }
}

Set<MuscleGroup> _concreteExerciseGroups() {
  return MuscleGroup.values.where((group) => group != MuscleGroup.arms).toSet();
}

bool _isMovementDirectionFocus(RoutineFocus focus) {
  return focus == RoutineFocus.push || focus == RoutineFocus.pull;
}
