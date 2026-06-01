import 'package:smart_trainner_core_database/smart_trainner_core_database.dart';
import 'package:smart_trainner_core_model/smart_trainner_core_model.dart';

extension CustomRoutineInputEntityMapper on CustomRoutineInput {
  CustomRoutineEntity toEntity({
    required String routineId,
    required String sessionId,
    required String createdAt,
    required String updatedAt,
  }) {
    return CustomRoutineEntity(
      id: routineId,
      sessionId: sessionId,
      name: name.trim(),
      description: description.trim(),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  List<CustomRoutineDayWrite> toDayWrites(String routineId) {
    return days.indexed.map((entry) {
      final dayIndex = entry.$1;
      final day = entry.$2;
      final dayId = customRoutineDayId(routineId, dayIndex);
      return CustomRoutineDayWrite(
        day: day.toEntity(id: dayId, routineId: routineId, dayIndex: dayIndex),
        exercises: day.exercises.indexed.map((exerciseEntry) {
          final slotIndex = exerciseEntry.$1;
          return exerciseEntry.$2.toEntity(
            id: customRoutineExerciseId(dayId, slotIndex),
            dayId: dayId,
            slotIndex: slotIndex,
          );
        }).toList(),
      );
    }).toList();
  }
}

extension CustomRoutineDayInputEntityMapper on CustomRoutineDayInput {
  CustomRoutineDayEntity toEntity({
    required String id,
    required String routineId,
    required int dayIndex,
  }) {
    return CustomRoutineDayEntity(
      id: id,
      routineId: routineId,
      dayIndex: dayIndex,
      title: title.trim(),
      focus: focus.trim().isEmpty ? (primaryFocus?.dbName ?? '') : focus.trim(),
      primaryFocus: primaryFocus?.dbName ?? '',
      secondaryFocuses: secondaryFocuses.map((focus) => focus.dbName).join(','),
      minRecoveryHours: minRecoveryHours,
    );
  }
}

extension CustomRoutineExerciseInputEntityMapper on CustomRoutineExerciseInput {
  CustomRoutineExerciseEntity toEntity({
    required String id,
    required String dayId,
    required int slotIndex,
  }) {
    return CustomRoutineExerciseEntity(
      id: id,
      dayId: dayId,
      slotIndex: slotIndex,
      exerciseId: exerciseId.value,
      sets: sets,
      repRangeStart: repRangeStart,
      repRangeEnd: repRangeEnd,
      durationMinutes: durationMinutes,
      restSeconds: restSeconds,
      note: note,
    );
  }
}

extension CustomRoutineWithDaysTemplateMapper on CustomRoutineWithDays {
  PlanTemplate toPlanTemplate() {
    final orderedDays = days.toList()
      ..sort((a, b) => a.day.dayIndex.compareTo(b.day.dayIndex));
    final focusSummary = <RoutineFocus>{
      for (final day in orderedDays) ...<RoutineFocus>[
        if (day.day.primaryFocus.toCustomRoutineFocus() case final focus?)
          focus,
        ...day.day.secondaryFocuses.toRoutineFocuses(),
      ],
    }.toList();
    return PlanTemplate(
      id: routine.id,
      name: routine.name,
      level: PlanLevel.intermediate,
      daysPerWeek: orderedDays.length,
      description: routine.description,
      days: orderedDays.map((day) => day.toPlanTemplateDay()).toList(),
      structure: RoutineStructure.balancedSplit,
      recommendedExperience: TrainingExperience.intermediate,
      cycleLength: orderedDays.length,
      sessionMinutes: orderedDays.isEmpty
          ? 45
          : orderedDays
                .map((day) => day.exercises.estimateSessionMinutes())
                .reduce((max, value) => value > max ? value : max),
      focusSummary: focusSummary,
      source: RoutineSource.custom,
    );
  }
}

extension on CustomRoutineDayWithExercises {
  PlanTemplateDay toPlanTemplateDay() {
    final orderedExercises = exercises.toList()
      ..sort((a, b) => a.slotIndex.compareTo(b.slotIndex));
    return PlanTemplateDay(
      dayOffset: day.dayIndex,
      title: day.title,
      focus: day.customRoutineFocusText(),
      exercises: orderedExercises.map((exercise) {
        final repRangeStart = exercise.repRangeStart;
        final repRangeEnd = exercise.repRangeEnd;
        return TemplateExercise(
          exerciseId: ExerciseId(exercise.exerciseId),
          sets: exercise.sets,
          repRange: repRangeStart != null && repRangeEnd != null
              ? RepRange(repRangeStart, repRangeEnd)
              : null,
          durationMinutes: exercise.durationMinutes,
          restSeconds: exercise.restSeconds,
          note: exercise.note,
        );
      }).toList(),
      dayNumber: day.dayIndex + 1,
      primaryFocus: day.primaryFocus.toCustomRoutineFocus(),
      secondaryFocuses: day.secondaryFocuses.toRoutineFocuses(),
      minRecoveryHours: day.minRecoveryHours,
    );
  }
}

extension on List<CustomRoutineExerciseEntity> {
  int estimateSessionMinutes() {
    final workingMinutes = fold<int>(
      0,
      (sum, exercise) => sum + (exercise.durationMinutes ?? exercise.sets * 3),
    );
    final restMinutes =
        fold<int>(
          0,
          (sum, exercise) => sum + exercise.restSeconds * exercise.sets,
        ) ~/
        60;
    final minutes = workingMinutes + restMinutes;
    return minutes < 15 ? 15 : minutes;
  }
}

extension on CustomRoutineDayEntity {
  String customRoutineFocusText() {
    final rawPrimaryFocus = primaryFocus ?? '';
    if (rawPrimaryFocus.toCustomRoutineFocus() == null &&
        focus == rawPrimaryFocus) {
      return '';
    }
    return focus;
  }
}

extension on RoutineFocus {
  String get dbName {
    final buffer = StringBuffer();
    for (final codeUnit in name.codeUnits) {
      final char = String.fromCharCode(codeUnit);
      if (char.toUpperCase() == char && buffer.isNotEmpty) {
        buffer.write('_');
      }
      buffer.write(char.toUpperCase());
    }
    return buffer.toString();
  }
}

extension on String? {
  RoutineFocus? toCustomRoutineFocus() {
    final value = this;
    if (value == null || value.isEmpty) {
      return null;
    }
    final normalized = value.toLowerCase().replaceAll('_', '');
    for (final focus in RoutineFocus.values) {
      if (focus.name.toLowerCase() == normalized) {
        return focus == RoutineFocus.fullBody ? null : focus;
      }
    }
    return null;
  }
}

extension on String {
  List<RoutineFocus> toRoutineFocuses() {
    return split(',')
        .map((raw) => raw.trim().toCustomRoutineFocus())
        .whereType<RoutineFocus>()
        .toList();
  }
}

String customRoutineDayId(String routineId, int dayIndex) {
  return '$routineId-day-${dayIndex + 1}';
}

String customRoutineExerciseId(String dayId, int slotIndex) {
  return '$dayId-slot-${slotIndex + 1}';
}
