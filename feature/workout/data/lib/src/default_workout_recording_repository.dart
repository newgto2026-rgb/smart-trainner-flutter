import 'package:smart_trainner_core_data/smart_trainner_core_data.dart';
import 'package:smart_trainner_core_database/smart_trainner_core_database.dart';
import 'package:smart_trainner_core_datastore/smart_trainner_core_datastore.dart';
import 'package:smart_trainner_core_domain/smart_trainner_core_domain.dart';
import 'package:smart_trainner_core_model/smart_trainner_core_model.dart';
import 'package:smart_trainner_feature_workout_domain/smart_trainner_feature_workout_domain.dart';

class DefaultWorkoutRecordingRepository implements WorkoutRecordingRepository {
  const DefaultWorkoutRecordingRepository({
    required this.workoutLogDao,
    required this.activeSessionResolver,
  });

  final WorkoutLogDao workoutLogDao;
  final ActiveSessionResolver activeSessionResolver;

  @override
  Future<WorkoutLog?> getLatestWorkoutLog(ExerciseId exerciseId) async {
    final result = await workoutLogDao.latestByExercise(
      sessionId: await activeSessionResolver.sessionId(),
      exerciseId: exerciseId.value,
    );
    return result?.toModel();
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
        final restSeconds = entry.restSeconds;
        if (restSeconds != null && (restSeconds < 0 || restSeconds > 600)) {
          throw ArgumentError('Rest must be between 0 and 600 seconds.');
        }
      }
      await workoutLogDao.upsertWithSets(
        log: input
            .copyWith(sets: setEntries.length, setEntries: setEntries)
            .toEntity(await activeSessionResolver.sessionId()),
        setLogs: setEntries.toEntities(),
      );
      return OperationResult.success();
    } catch (error) {
      return OperationResult.failure(error);
    }
  }
}
