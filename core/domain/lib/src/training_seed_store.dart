import 'package:smart_trainner_core_model/smart_trainner_core_model.dart';

abstract interface class TrainingSeedContentProvider {
  List<Exercise> get exercises;
  List<PlanTemplate> get templates;
}

class TrainingSeedStore {
  TrainingSeedStore({required TrainingSeedContentProvider content})
    : exercises = content.exercises,
      templates = content.templates,
      _exerciseById = {
        for (final exercise in content.exercises) exercise.id: exercise,
      };

  final List<Exercise> exercises;
  final List<PlanTemplate> templates;
  final Map<ExerciseId, Exercise> _exerciseById;

  Exercise? exercise(ExerciseId id) => _exerciseById[id];

  bool hasTemplate(String templateId) {
    return templates.any((template) => template.id == templateId);
  }

  PlanTemplate templateById(
    String templateId, {
    List<PlanTemplate> customTemplates = const <PlanTemplate>[],
  }) {
    return <PlanTemplate>[...templates, ...customTemplates].firstWhere(
      (template) => template.id == templateId,
      orElse: () => templates.first,
    );
  }

  WeeklyPlan buildWeeklyPlan({
    required PlanTemplate template,
    required DateTime weekStartDate,
  }) {
    final normalizedWeekStart = normalizeDate(weekStartDate);
    return WeeklyPlan(
      id: PlanId('${template.id}_${normalizedWeekStart.dateKey}'),
      templateId: template.id,
      name: template.name,
      weekStartDate: normalizedWeekStart,
      days: template.days.map((day) {
        final date = normalizedWeekStart.add(Duration(days: day.dayOffset));
        return WorkoutDayPlan(
          date: date,
          title: day.title,
          focus: day.focus,
          exercises: day.exercises.indexed.map((entry) {
            final slotIndex = entry.$1;
            final item = entry.$2;
            final exercise = _exerciseById[item.exerciseId]!;
            return PlannedExercise(
              id: PlannedExerciseId(
                template.plannedExerciseId(
                  date: date,
                  dayNumber: day.dayNumber,
                  slotIndex: slotIndex,
                  exerciseId: item.exerciseId,
                ),
              ),
              exercise: exercise,
              sets: item.sets,
              repRange: item.repRange,
              durationMinutes: item.durationMinutes,
              restSeconds: item.restSeconds,
              note: item.note,
            );
          }).toList(),
          dayNumber: day.dayNumber,
          primaryFocus: day.primaryFocus,
          secondaryFocuses: day.secondaryFocuses,
          minRecoveryHours: day.minRecoveryHours,
        );
      }).toList(),
    );
  }
}

extension on PlanTemplate {
  String plannedExerciseId({
    required DateTime date,
    required int dayNumber,
    required int slotIndex,
    required ExerciseId exerciseId,
  }) {
    if (source == RoutineSource.custom) {
      return '${date.dateKey}_${id}_day${dayNumber}_slot${slotIndex + 1}_${exerciseId.value}';
    }
    return '${date.dateKey}_${exerciseId.value}';
  }
}

extension _TrainingSeedDateKey on DateTime {
  String get dateKey {
    final normalized = normalizeDate(this);
    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');
    return '${normalized.year}-$month-$day';
  }
}
