import 'package:smart_trainner_core_data/src/training_mappers.dart';
import 'package:smart_trainner_core_database/smart_trainner_core_database.dart';
import 'package:smart_trainner_core_model/smart_trainner_core_model.dart';
import 'package:test/test.dart';

void main() {
  test('custom routine without focus does not default to full body', () {
    final template = customRoutine(
      primaryFocus: '',
      focus: '',
    ).toPlanTemplate();

    expect(template.focusSummary, isEmpty);
    expect(template.days.single.primaryFocus, isNull);
    expect(template.days.single.focus, isEmpty);
  });

  test('custom routine explicit focus is mapped', () {
    final template = customRoutine(
      primaryFocus: 'BACK',
      focus: 'BACK',
    ).toPlanTemplate();

    expect(template.focusSummary, <RoutineFocus>[RoutineFocus.back]);
    expect(template.days.single.primaryFocus, RoutineFocus.back);
  });
}

CustomRoutineWithDays customRoutine({
  required String primaryFocus,
  required String focus,
}) {
  return CustomRoutineWithDays(
    routine: const CustomRoutineEntity(
      id: 'custom-1',
      sessionId: 'local-default',
      name: 'My routine',
      description: '',
      createdAt: '2026-05-30T00:00:00Z',
      updatedAt: '2026-05-30T00:00:00Z',
    ),
    days: <CustomRoutineDayWithExercises>[
      CustomRoutineDayWithExercises(
        day: CustomRoutineDayEntity(
          id: 'custom-1-day-1',
          routineId: 'custom-1',
          dayIndex: 0,
          title: '1일차',
          focus: focus,
          primaryFocus: primaryFocus,
          secondaryFocuses: '',
          minRecoveryHours: 24,
        ),
        exercises: const <CustomRoutineExerciseEntity>[
          CustomRoutineExerciseEntity(
            id: 'custom-1-day-1-slot-1',
            dayId: 'custom-1-day-1',
            slotIndex: 0,
            exerciseId: 'back_pull',
            sets: 3,
            repRangeStart: 8,
            repRangeEnd: 12,
            durationMinutes: null,
            restSeconds: 90,
            note: '',
          ),
        ],
      ),
    ],
  );
}
