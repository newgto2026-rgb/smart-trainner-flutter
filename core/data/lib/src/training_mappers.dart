import 'package:smart_trainner_core_database/smart_trainner_core_database.dart';
import 'package:smart_trainner_core_model/smart_trainner_core_model.dart';

extension CustomExerciseInputMapper on CustomExerciseInput {
  CustomExerciseEntity toEntity({
    required ExerciseId id,
    required String ownerUserId,
    required String timestamp,
  }) {
    return CustomExerciseEntity(
      id: id.value,
      ownerUserId: ownerUserId,
      name: name,
      muscleGroup: muscleGroup.name,
      equipment: equipment.name,
      difficulty: difficulty.name,
      imageKey: id.value,
      imagePath: imagePath,
      summary: summary,
      instructions: instructions,
      safetyCues: safetyCues,
      defaultSets: defaultSets,
      defaultRepRangeFirst: defaultRepRange?.first,
      defaultRepRangeLast: defaultRepRange?.last,
      defaultDurationMinutes: defaultDurationMinutes,
      restSeconds: restSeconds,
      source: ExerciseSource.userCreated.name,
      originExerciseId: null,
      sourceOwnerUserId: null,
      sourceShareId: null,
      createdAt: timestamp,
      updatedAt: timestamp,
    );
  }
}

extension CustomExerciseEntityMapper on CustomExerciseEntity {
  Exercise toModel() {
    return Exercise(
      id: ExerciseId(id),
      name: name,
      muscleGroup: MuscleGroup.values.byNameOrFirst(muscleGroup),
      equipment: EquipmentType.values.byNameOrFirst(equipment),
      difficulty: DifficultyLevel.values.byNameOrFirst(difficulty),
      imageKey: imageKey,
      imagePath: imagePath,
      summary: summary,
      instructions: instructions,
      safetyCues: safetyCues,
      defaultSets: defaultSets,
      defaultRepRange:
          defaultRepRangeFirst == null || defaultRepRangeLast == null
          ? null
          : RepRange(defaultRepRangeFirst!, defaultRepRangeLast!),
      defaultDurationMinutes: defaultDurationMinutes,
      restSeconds: restSeconds,
      metadata: ExerciseSourceMetadata(
        source: ExerciseSource.values.byNameOrFirst(source),
        ownerUserId: ownerUserId,
        originExerciseId: originExerciseId == null
            ? null
            : ExerciseId(originExerciseId!),
        sourceOwnerUserId: sourceOwnerUserId,
        sourceShareId: sourceShareId,
      ),
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

extension _EnumByNameOrFirst<T extends Enum> on List<T> {
  T byNameOrFirst(String name) {
    for (final value in this) {
      if (value.name == name) {
        return value;
      }
    }
    return first;
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

extension DateKey on DateTime {
  String get dateKey {
    final normalized = normalizeDate(this);
    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');
    return '${normalized.year}-$month-$day';
  }
}
