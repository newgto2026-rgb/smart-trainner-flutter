import 'package:smart_trainner_core_data/src/seed_training_content.dart';
import 'package:smart_trainner_core_data/src/training_mappers.dart';
import 'package:smart_trainner_core_database/smart_trainner_core_database.dart';
import 'package:smart_trainner_core_datastore/smart_trainner_core_datastore.dart';
import 'package:smart_trainner_core_domain/smart_trainner_core_domain.dart';
import 'package:smart_trainner_core_model/smart_trainner_core_model.dart';
import 'package:rxdart/rxdart.dart';

class DefaultTrainingRepository implements TrainingRepository {
  DefaultTrainingRepository({
    required this.workoutLogDao,
    required this.preferences,
    required this.summaryCalculator,
    this.customRoutineDao,
  }) : _exerciseById = {
         for (final exercise in SeedTrainingContent.exercises)
           exercise.id: exercise,
       },
       _templates = SeedTrainingContent.templates;

  final WorkoutLogDao workoutLogDao;
  final TrainingPreferencesDataSource preferences;
  final WeeklySummaryCalculator summaryCalculator;
  final CustomRoutineDao? customRoutineDao;
  final Map<ExerciseId, Exercise> _exerciseById;
  final List<PlanTemplate> _templates;

  @override
  Stream<List<Exercise>> observeExercises() {
    return Stream.value(SeedTrainingContent.exercises);
  }

  @override
  Stream<List<PlanTemplate>> observePlanTemplates() {
    final customRoutineDao = this.customRoutineDao;
    if (customRoutineDao == null) {
      return Stream.value(_templates);
    }
    return _activeSessionIds().switchMap((sessionId) {
      return customRoutineDao.observeForSession(sessionId).map((routines) {
        return <PlanTemplate>[
          ..._templates,
          ...routines.map((routine) => routine.toPlanTemplate()),
        ];
      });
    });
  }

  @override
  Stream<WeeklyPlan> observeCurrentWeeklyPlan(DateTime weekStartDate) {
    return _activeSessionIds().switchMap((sessionId) {
      return preferences.selectedTemplateId(sessionId).map((templateId) {
        return _buildWeeklyPlan(
          template: _templates.firstWhere(
            (template) => template.id == templateId,
            orElse: () => _templates.first,
          ),
          weekStartDate: weekStartDate,
        );
      });
    });
  }

  @override
  Stream<List<WorkoutLog>> observeWorkoutLogs(DateTime weekStartDate) {
    return _activeSessionIds().switchMap((sessionId) {
      return workoutLogDao
          .observeBetween(
            sessionId: sessionId,
            startDate: weekStartDate.dateKey,
            endDate: weekStartDate.add(const Duration(days: 6)).dateKey,
          )
          .map(
            (entities) => entities.map((entity) => entity.toModel()).toList(),
          );
    });
  }

  @override
  Stream<List<WorkoutLog>> observeLatestWorkoutLogs() {
    return _activeSessionIds().switchMap((sessionId) {
      return workoutLogDao
          .observeAll(sessionId: sessionId)
          .map(
            (entities) => entities.map((entity) => entity.toModel()).toList(),
          );
    });
  }

  @override
  Stream<WeeklySummary> observeWeeklySummary(DateTime weekStartDate) {
    return Rx.combineLatest2(
      observeCurrentWeeklyPlan(weekStartDate),
      observeWorkoutLogs(weekStartDate),
      (plan, logs) => summaryCalculator.calculate(
        weekStartDate: weekStartDate,
        plan: plan,
        logs: logs,
      ),
    );
  }

  @override
  Future<Exercise?> getExercise(ExerciseId id) async {
    return _exerciseById[id];
  }

  @override
  Future<OperationResult<void>> selectPlanTemplate(String templateId) async {
    try {
      if (!_templates.any((template) => template.id == templateId)) {
        throw ArgumentError('Unknown plan template: $templateId');
      }
      await preferences.setSelectedTemplateId(_activeSessionId(), templateId);
      return OperationResult.success();
    } catch (error) {
      return OperationResult.failure(error);
    }
  }

  @override
  Future<OperationResult<void>> saveWorkoutLog(WorkoutLogInput input) async {
    try {
      final setEntries = input.setEntries.isNotEmpty
          ? input.setEntries
          : List.generate(
              input.sets,
              (index) => WorkoutSetLog(
                order: index + 1,
                reps: input.reps,
                weightKg: input.weightKg,
                durationMinutes: input.durationMinutes,
              ),
            );
      if (setEntries.isEmpty || setEntries.length > 12) {
        throw ArgumentError('Sets must be between 1 and 12.');
      }
      if (setEntries.map((entry) => entry.order).toSet().length !=
          setEntries.length) {
        throw ArgumentError('Set order values must be unique.');
      }
      for (final entry in setEntries) {
        if (entry.order < 1 || entry.order > 12) {
          throw ArgumentError('Set order must be between 1 and 12.');
        }
        if (entry.reps == null && entry.durationMinutes == null) {
          throw ArgumentError('Each set needs reps or duration.');
        }
        final reps = entry.reps;
        if (reps != null && (reps < 1 || reps > 50)) {
          throw ArgumentError('Reps must be between 1 and 50.');
        }
        final weightKg = entry.weightKg;
        if (weightKg != null && weightKg < 0) {
          throw ArgumentError('Weight cannot be negative.');
        }
        final durationMinutes = entry.durationMinutes;
        if (durationMinutes != null &&
            (durationMinutes < 1 || durationMinutes > 240)) {
          throw ArgumentError('Duration must be between 1 and 240 minutes.');
        }
      }

      await workoutLogDao.upsertWithSets(
        log: input
            .copyWith(sets: setEntries.length, setEntries: setEntries)
            .toEntity(_activeSessionId()),
        setLogs: setEntries.toEntities(),
      );
      return OperationResult.success();
    } catch (error) {
      return OperationResult.failure(error);
    }
  }

  String _activeSessionId() =>
      preferences.activeSessionIdValue ?? defaultUserSessionId;

  Stream<String> _activeSessionIds() {
    return preferences.activeSessionId
        .map((id) => id ?? defaultUserSessionId)
        .distinct();
  }

  WeeklyPlan _buildWeeklyPlan({
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
                _plannedExerciseId(
                  template: template,
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

String _plannedExerciseId({
  required PlanTemplate template,
  required DateTime date,
  required int dayNumber,
  required int slotIndex,
  required ExerciseId exerciseId,
}) {
  if (template.source == RoutineSource.custom) {
    return '${date.dateKey}_${template.id}_day${dayNumber}_slot${slotIndex + 1}_${exerciseId.value}';
  }
  return '${date.dateKey}_${exerciseId.value}';
}
