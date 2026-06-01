import 'dart:async';

import 'package:smart_trainner_core_data/src/seed_training_content.dart';
import 'package:smart_trainner_core_data/src/training_mappers.dart';
import 'package:smart_trainner_core_database/smart_trainner_core_database.dart';
import 'package:smart_trainner_core_datastore/smart_trainner_core_datastore.dart';
import 'package:smart_trainner_core_domain/smart_trainner_core_domain.dart';
import 'package:smart_trainner_core_model/smart_trainner_core_model.dart';

class DefaultTrainingRepository implements TrainingRepository {
  DefaultTrainingRepository({
    required this.workoutLogDao,
    required this.preferences,
    required this.summaryCalculator,
  }) : _exerciseById = {
         for (final exercise in SeedTrainingContent.exercises)
           exercise.id: exercise,
       },
       _templates = SeedTrainingContent.templates;

  final WorkoutLogDao workoutLogDao;
  final TrainingPreferencesDataSource preferences;
  final WeeklySummaryCalculator summaryCalculator;
  final Map<ExerciseId, Exercise> _exerciseById;
  final List<PlanTemplate> _templates;

  @override
  Stream<List<Exercise>> observeExercises() {
    return Stream.value(SeedTrainingContent.exercises);
  }

  @override
  Stream<List<PlanTemplate>> observePlanTemplates() {
    return Stream.value(_templates);
  }

  @override
  Stream<WeeklyPlan> observeCurrentWeeklyPlan(DateTime weekStartDate) {
    final sessionId = preferences.activeSessionIdValue ?? defaultUserSessionId;
    return preferences.selectedTemplateId(sessionId).map((templateId) {
      return _buildWeeklyPlan(
        template: _templates.firstWhere(
          (template) => template.id == templateId,
          orElse: () => _templates.first,
        ),
        weekStartDate: weekStartDate,
      );
    });
  }

  @override
  Stream<List<WorkoutLog>> observeWorkoutLogs(DateTime weekStartDate) {
    final sessionId = preferences.activeSessionIdValue ?? defaultUserSessionId;
    return workoutLogDao
        .observeBetween(
          sessionId: sessionId,
          startDate: weekStartDate.dateKey,
          endDate: weekStartDate.add(const Duration(days: 6)).dateKey,
        )
        .map((entities) => entities.map((entity) => entity.toModel()).toList());
  }

  @override
  Stream<WeeklySummary> observeWeeklySummary(DateTime weekStartDate) {
    return combineLatest2(
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
          exercises: day.exercises.map((item) {
            final exercise = _exerciseById[item.exerciseId]!;
            return PlannedExercise(
              id: PlannedExerciseId('${date.dateKey}_${item.exerciseId.value}'),
              exercise: exercise,
              sets: item.sets,
              repRange: item.repRange,
              durationMinutes: item.durationMinutes,
              restSeconds: item.restSeconds,
              note: item.note,
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}

Stream<R> combineLatest2<A, B, R>(
  Stream<A> first,
  Stream<B> second,
  R Function(A first, B second) combine,
) {
  late StreamController<R> controller;
  StreamSubscription<A>? firstSubscription;
  StreamSubscription<B>? secondSubscription;
  A? latestFirst;
  B? latestSecond;
  var hasFirst = false;
  var hasSecond = false;

  void emitIfReady() {
    if (hasFirst && hasSecond) {
      controller.add(combine(latestFirst as A, latestSecond as B));
    }
  }

  controller = StreamController<R>(
    onListen: () {
      firstSubscription = first.listen((value) {
        latestFirst = value;
        hasFirst = true;
        emitIfReady();
      });
      secondSubscription = second.listen((value) {
        latestSecond = value;
        hasSecond = true;
        emitIfReady();
      });
    },
    onCancel: () async {
      await firstSubscription?.cancel();
      await secondSubscription?.cancel();
    },
  );
  return controller.stream;
}
