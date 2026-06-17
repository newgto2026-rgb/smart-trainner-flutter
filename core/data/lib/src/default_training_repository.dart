import 'dart:async';

import 'package:smart_trainner_core_data/src/seed_training_content.dart';
import 'package:smart_trainner_core_data/src/training_mappers.dart';
import 'package:smart_trainner_core_database/smart_trainner_core_database.dart';
import 'package:smart_trainner_core_datastore/smart_trainner_core_datastore.dart';
import 'package:smart_trainner_core_domain/smart_trainner_core_domain.dart';
import 'package:smart_trainner_core_model/smart_trainner_core_model.dart';

class DefaultTrainingRepository implements TrainingRepository {
  DefaultTrainingRepository({
    required this.customExerciseDao,
    required this.workoutLogDao,
    required this.preferences,
    required this.summaryCalculator,
  }) : _exerciseById = {
         for (final exercise in SeedTrainingContent.exercises)
           exercise.id: exercise,
       },
       _templates = SeedTrainingContent.templates;

  final CustomExerciseDao customExerciseDao;
  final WorkoutLogDao workoutLogDao;
  final TrainingPreferencesDataSource preferences;
  final WeeklySummaryCalculator summaryCalculator;
  final Map<ExerciseId, Exercise> _exerciseById;
  final List<PlanTemplate> _templates;

  @override
  Stream<List<Exercise>> observeExercises() {
    return customExerciseDao.observeAll().map((customExercises) {
      return _exerciseCatalogFor(_activeOwnerUserId(), customExercises);
    });
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
    final seedExercise = _exerciseById[id];
    if (seedExercise != null) {
      return seedExercise;
    }
    final ownerUserId = _activeOwnerUserId();
    final entity = await customExerciseDao.getById(id.value);
    if (entity != null && entity.ownerUserId == ownerUserId) {
      return entity.toModel();
    }
    return null;
  }

  @override
  Future<OperationResult<Exercise>> createCustomExercise(
    CustomExerciseInput input,
  ) async {
    try {
      _validateCustomExercise(input);
      final ownerUserId = _activeOwnerUserId();
      final existing = await customExerciseDao
          .observeByOwner(ownerUserId)
          .first;
      final id = _nextCustomExerciseId(
        ownerUserId: ownerUserId,
        name: input.name,
        existingIds: existing.map((exercise) => exercise.id).toSet(),
      );
      final timestamp = DateTime.now().toUtc().toIso8601String();
      final entity = input.toEntity(
        id: id,
        ownerUserId: ownerUserId,
        timestamp: timestamp,
      );
      await customExerciseDao.upsert(entity);
      return OperationResult.success(entity.toModel());
    } catch (error) {
      return OperationResult.failure(error);
    }
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

  String _activeOwnerUserId() => _activeSessionId();

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

  List<Exercise> _exerciseCatalogFor(
    String ownerUserId,
    List<CustomExerciseEntity> customExercises,
  ) {
    return <Exercise>[
      ...SeedTrainingContent.exercises,
      ...customExercises
          .where((exercise) => exercise.ownerUserId == ownerUserId)
          .map((exercise) => exercise.toModel()),
    ];
  }
}

void _validateCustomExercise(CustomExerciseInput input) {
  if (input.name.trim().isEmpty) {
    throw ArgumentError('Custom exercise name is required.');
  }
  if (input.summary.trim().isEmpty) {
    throw ArgumentError('Custom exercise summary is required.');
  }
  if (input.instructions.isEmpty ||
      input.instructions.any((instruction) => instruction.trim().isEmpty)) {
    throw ArgumentError('Custom exercise instructions are required.');
  }
  if (input.safetyCues.isEmpty ||
      input.safetyCues.any((cue) => cue.trim().isEmpty)) {
    throw ArgumentError('Custom exercise safety cues are required.');
  }
  if (input.defaultSets < 1 || input.defaultSets > 12) {
    throw ArgumentError('Default sets must be between 1 and 12.');
  }
  final repRange = input.defaultRepRange;
  if (repRange == null && input.defaultDurationMinutes == null) {
    throw ArgumentError('Custom exercise needs reps or duration.');
  }
  if (repRange != null &&
      (repRange.first < 1 ||
          repRange.last > 50 ||
          repRange.first > repRange.last)) {
    throw ArgumentError('Rep range must be between 1 and 50.');
  }
  final duration = input.defaultDurationMinutes;
  if (duration != null && (duration < 1 || duration > 240)) {
    throw ArgumentError('Duration must be between 1 and 240 minutes.');
  }
  if (input.restSeconds < 15 || input.restSeconds > 600) {
    throw ArgumentError('Rest seconds must be between 15 and 600.');
  }
}

ExerciseId _nextCustomExerciseId({
  required String ownerUserId,
  required String name,
  required Set<String> existingIds,
}) {
  final ownerSlug = _slugify(ownerUserId);
  final nameSlug = _slugify(name);
  final base =
      'custom_${ownerSlug.isEmpty ? 'user' : ownerSlug}_'
      '${nameSlug.isEmpty ? 'exercise' : nameSlug}';
  var candidate = base;
  var suffix = 2;
  while (existingIds.contains(candidate)) {
    candidate = '${base}_$suffix';
    suffix++;
  }
  return ExerciseId(candidate);
}

String _slugify(String value) {
  final lower = value.toLowerCase();
  final buffer = StringBuffer();
  var previousDash = false;
  for (final codeUnit in lower.codeUnits) {
    final isDigit = codeUnit >= 48 && codeUnit <= 57;
    final isLowerAlpha = codeUnit >= 97 && codeUnit <= 122;
    if (isDigit || isLowerAlpha) {
      buffer.writeCharCode(codeUnit);
      previousDash = false;
    } else if (!previousDash && buffer.isNotEmpty) {
      buffer.write('_');
      previousDash = true;
    }
    if (buffer.length >= 32) {
      break;
    }
  }
  var result = buffer.toString();
  while (result.endsWith('_')) {
    result = result.substring(0, result.length - 1);
  }
  return result;
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
