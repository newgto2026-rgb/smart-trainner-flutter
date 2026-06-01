import 'package:flutter_test/flutter_test.dart';
import 'package:smart_trainner_feature_training_impl/smart_trainner_feature_training_impl.dart';

void main() {
  test('every seed exercise id has variable step visuals', () {
    final expectedExerciseIds = <String>{
      'bodyweight_squat',
      'leg_press',
      'goblet_squat',
      'box_squat',
      'dumbbell_split_squat',
      'bulgarian_split_squat',
      'walking_lunge',
      'leg_extension',
      'leg_curl',
      'romanian_deadlift',
      'hip_thrust',
      'calf_raise',
      'lat_pulldown',
      'seated_cable_row',
      'chest_supported_row',
      'one_arm_dumbbell_row',
      'assisted_pullup',
      'pullup',
      'face_pull',
      'machine_chest_press',
      'dumbbell_bench_press',
      'incline_dumbbell_press',
      'pushup',
      'cable_fly',
      'machine_shoulder_press',
      'dumbbell_shoulder_press',
      'dumbbell_lateral_raise',
      'rear_delt_machine',
      'triceps_pushdown',
      'overhead_triceps_extension',
      'dumbbell_curl',
      'cable_curl',
      'plank',
      'bird_dog',
      'pallof_press',
      'cable_woodchop',
      'treadmill_walk',
      'indoor_bike',
      'hack_squat',
      'smith_machine_squat',
      'barbell_back_squat',
      'barbell_bench_press',
      'conventional_deadlift',
      'barbell_romanian_deadlift',
      'barbell_overhead_press',
      'dumbbell_step_up',
      'glute_bridge',
      'cable_glute_kickback',
      'hip_abduction_machine',
      'hip_adduction_machine',
      'back_extension',
      'straight_arm_pulldown',
      'machine_row',
      't_bar_row',
      'barbell_bent_over_row',
      'cable_pullover',
      'inverted_row',
      'dumbbell_shrug',
      'pec_deck_fly',
      'incline_machine_press',
      'dumbbell_floor_press',
      'assisted_dip',
      'dip',
      'cable_chest_press',
      'close_grip_pushup',
      'arnold_press',
      'front_raise',
      'cable_lateral_raise',
      'landmine_press',
      'prone_y_raise',
      'hammer_curl',
      'preacher_curl_machine',
      'rope_overhead_triceps',
      'reverse_curl',
      'side_plank',
      'reverse_crunch',
      'cable_crunch',
      'hanging_knee_raise',
      'mountain_climber',
      'farmer_carry',
      'elliptical',
      'stair_climber',
      'rowing_machine',
      'battle_rope',
      'sled_push',
      'dumbbell_deadlift',
      'medicine_ball_slam',
      'dead_bug',
      'kettlebell_deadlift',
      'kettlebell_romanian_deadlift',
      'kettlebell_sumo_deadlift',
      'kettlebell_goblet_squat',
      'kettlebell_box_squat',
      'kettlebell_reverse_lunge',
      'kettlebell_split_squat',
      'kettlebell_step_up',
      'kettlebell_bent_over_row',
      'one_arm_kettlebell_row',
      'kettlebell_floor_press',
      'kettlebell_shoulder_press',
      'half_kneeling_kettlebell_press',
      'kettlebell_halo',
      'kettlebell_suitcase_carry',
      'kettlebell_farmer_carry',
      'kettlebell_rack_carry',
      'two_hand_kettlebell_swing',
    };

    expect(exerciseStepVisualExerciseIds, unorderedEquals(expectedExerciseIds));
    for (final exerciseId in expectedExerciseIds) {
      final visuals = exerciseStepVisuals(exerciseId);

      expect(visuals.length, greaterThanOrEqualTo(2));
      expect(visuals.length, lessThanOrEqualTo(5));
      if (exerciseId != 'dead_bug') {
        expect(
          visuals.map((visual) => visual.assetName).toSet(),
          hasLength(visuals.length),
        );
      }
      for (final visual in visuals) {
        expect(visual.koLabel.trim(), isNotEmpty);
        expect(visual.enLabel.trim(), isNotEmpty);
        expect(visual.koInstruction.trim(), isNotEmpty);
        expect(visual.enInstruction.trim(), isNotEmpty);
      }
    }
  });

  test('trainer audit examples keep their expected step counts', () {
    expect(exerciseStepVisuals('dumbbell_curl'), hasLength(2));
    expect(exerciseStepVisuals('bodyweight_squat'), hasLength(4));
    expect(exerciseStepVisuals('leg_press'), hasLength(3));
    expect(exerciseStepVisuals('goblet_squat'), hasLength(4));
    expect(exerciseStepVisuals('romanian_deadlift'), hasLength(5));
    expect(exerciseStepVisuals('dead_bug'), hasLength(4));
    expect(exerciseStepVisuals('barbell_back_squat'), hasLength(5));
    expect(exerciseStepVisuals('barbell_bench_press'), hasLength(4));
    expect(exerciseStepVisuals('conventional_deadlift'), hasLength(5));
    expect(exerciseStepVisuals('barbell_romanian_deadlift'), hasLength(4));
    expect(exerciseStepVisuals('bulgarian_split_squat'), hasLength(4));
    expect(exerciseStepVisuals('pullup'), hasLength(4));
    expect(exerciseStepVisuals('dip'), hasLength(4));
    expect(exerciseStepVisuals('dumbbell_deadlift'), hasLength(4));
    expect(exerciseStepVisuals('dumbbell_floor_press'), hasLength(4));
    expect(exerciseStepVisuals('elliptical'), hasLength(3));
    expect(exerciseStepVisuals('front_raise'), hasLength(4));
    expect(exerciseStepVisuals('hack_squat'), hasLength(4));
    expect(exerciseStepVisuals('incline_machine_press'), hasLength(3));
    expect(exerciseStepVisuals('landmine_press'), hasLength(4));
    expect(exerciseStepVisuals('overhead_triceps_extension'), hasLength(4));
    expect(exerciseStepVisuals('prone_y_raise'), hasLength(3));
    expect(exerciseStepVisuals('rope_overhead_triceps'), hasLength(3));
    expect(exerciseStepVisuals('sled_push'), hasLength(4));
    expect(exerciseStepVisuals('smith_machine_squat'), hasLength(4));
    expect(exerciseStepVisuals('barbell_overhead_press'), hasLength(4));
    expect(exerciseStepVisuals('barbell_bent_over_row'), hasLength(4));
    expect(exerciseStepVisuals('box_squat'), hasLength(4));
    expect(exerciseStepVisuals('close_grip_pushup'), hasLength(4));
    expect(exerciseStepVisuals('lat_pulldown'), hasLength(4));
    expect(exerciseStepVisuals('mountain_climber'), hasLength(4));
    expect(exerciseStepVisuals('rowing_machine'), hasLength(4));
    expect(exerciseStepVisuals('stair_climber'), hasLength(3));
    expect(exerciseStepVisuals('kettlebell_halo'), hasLength(3));
    expect(exerciseStepVisuals('kettlebell_deadlift'), hasLength(4));
    expect(exerciseStepVisuals('two_hand_kettlebell_swing'), hasLength(4));
    expect(exerciseStepVisuals('medicine_ball_slam'), hasLength(4));
  });

  test('dead bug uses start reach return opposite reach flow', () {
    final visuals = exerciseStepVisuals('dead_bug');

    expect(
      visuals.map((visual) => visual.assetName),
      orderedEquals(<String>[
        'exercise_dead_bug_clean_v15_step_1',
        'exercise_dead_bug_clean_v15_step_2',
        'exercise_dead_bug_clean_v15_step_1',
        'exercise_dead_bug_clean_v15_step_3',
      ]),
    );
    expect(
      visuals.map((visual) => visual.koLabel),
      orderedEquals(<String>[
        '시작 자세',
        '한쪽 팔·반대 다리 뻗기',
        '시작 자세로 복귀',
        '반대쪽 팔·다리 뻗기',
      ]),
    );
    expect(
      exerciseThumbnailAssetName('dead_bug'),
      'exercise_thumbnail_dead_bug_clean_v15',
    );
  });

  test('visually rejected assets stay quarantined', () {
    final quarantinedExerciseIds = <String>{};

    for (final exerciseId in quarantinedExerciseIds) {
      expect(exerciseArtNeedsQaReplacement(exerciseId), isTrue);
      expect(exerciseThumbnailAssetName(exerciseId), isNull);
    }
  });
}
