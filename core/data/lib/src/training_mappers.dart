import 'package:smart_trainner_core_database/smart_trainner_core_database.dart';
import 'package:smart_trainner_core_model/smart_trainner_core_model.dart';

extension CustomRoutineWithDaysMapper on CustomRoutineWithDays {
  PlanTemplate toPlanTemplate() {
    final orderedDays = days.toList()
      ..sort((a, b) => a.day.dayIndex.compareTo(b.day.dayIndex));
    final focusSummary = <RoutineFocus>{
      for (final day in orderedDays) ...<RoutineFocus>[
        if (_toRoutineFocus(day.day.primaryFocus) case final focus?) focus,
        ..._toRoutineFocuses(day.day.secondaryFocuses),
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

extension CustomRoutineDayWithExercisesMapper on CustomRoutineDayWithExercises {
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
      primaryFocus: _toRoutineFocus(day.primaryFocus),
      secondaryFocuses: _toRoutineFocuses(day.secondaryFocuses),
      minRecoveryHours: day.minRecoveryHours,
    );
  }
}

extension WorkoutLogInputMapper on WorkoutLogInput {
  WorkoutLogEntity toEntity(String sessionId) {
    return WorkoutLogEntity(
      sessionId: sessionId,
      plannedExerciseId: plannedExerciseId.value,
      exerciseId: exerciseId.value,
      performedDate: performedAt.dateKey,
      performedAt: performedAt.toIso8601String(),
      sets: sets,
      reps: reps,
      weightKg: weightKg,
      durationMinutes: durationMinutes,
      memo: memo,
      completed: completed,
    );
  }
}

extension WorkoutSetLogListMapper on List<WorkoutSetLog> {
  List<WorkoutSetLogEntity> toEntities({int workoutLogId = 0}) {
    return map(
      (entry) => WorkoutSetLogEntity(
        workoutLogId: workoutLogId,
        setIndex: entry.order,
        reps: entry.reps,
        weightKg: entry.weightKg,
        durationMinutes: entry.durationMinutes,
        restSeconds: entry.restSeconds,
      ),
    ).toList();
  }
}

extension WorkoutLogWithSetsMapper on WorkoutLogWithSets {
  WorkoutLog toModel() {
    final legacySetEntries = List.generate(
      log.sets.clamp(0, 1 << 31),
      (index) => WorkoutSetLog(
        order: index + 1,
        reps: log.reps,
        weightKg: log.weightKg,
        durationMinutes: log.durationMinutes,
        restSeconds: null,
      ),
    );
    final setEntries =
        setLogs
            .map(
              (setLog) => WorkoutSetLog(
                order: setLog.setIndex,
                reps: setLog.reps,
                weightKg: setLog.weightKg,
                durationMinutes: setLog.durationMinutes,
                restSeconds: setLog.restSeconds,
              ),
            )
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));

    return WorkoutLog(
      id: WorkoutLogId(log.id),
      sessionId: UserSessionId(log.sessionId),
      plannedExerciseId: PlannedExerciseId(log.plannedExerciseId),
      exerciseId: ExerciseId(log.exerciseId),
      performedAt: DateTime.parse(log.performedAt),
      sets: log.sets,
      reps: log.reps,
      weightKg: log.weightKg,
      durationMinutes: log.durationMinutes,
      memo: log.memo,
      completed: log.completed,
      setEntries: setEntries.isEmpty ? legacySetEntries : setEntries,
    );
  }
}

extension CustomRoutineExerciseEstimator on List<CustomRoutineExerciseEntity> {
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

extension DateKey on DateTime {
  String get dateKey {
    final normalized = normalizeDate(this);
    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');
    return '${normalized.year}-$month-$day';
  }
}

extension on CustomRoutineDayEntity {
  String customRoutineFocusText() {
    final rawPrimaryFocus = primaryFocus ?? '';
    if (_toRoutineFocus(rawPrimaryFocus) == null && focus == rawPrimaryFocus) {
      return '';
    }
    return focus;
  }
}

List<RoutineFocus> _toRoutineFocuses(String value) {
  return value
      .split(',')
      .map((raw) => raw.trim())
      .where((raw) => raw.isNotEmpty)
      .map(_toRoutineFocus)
      .whereType<RoutineFocus>()
      .toList();
}

RoutineFocus? _toRoutineFocus(String? value) {
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
