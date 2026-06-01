class WorkoutLogEntity {
  const WorkoutLogEntity({
    this.id = 0,
    required this.sessionId,
    required this.plannedExerciseId,
    required this.exerciseId,
    required this.performedDate,
    required this.performedAt,
    required this.sets,
    required this.reps,
    required this.weightKg,
    required this.durationMinutes,
    required this.memo,
    required this.completed,
  });

  final int id;
  final String sessionId;
  final String plannedExerciseId;
  final String exerciseId;
  final String performedDate;
  final String performedAt;
  final int sets;
  final int? reps;
  final double? weightKg;
  final int? durationMinutes;
  final String memo;
  final bool completed;

  WorkoutLogEntity copyWith({
    int? id,
    String? sessionId,
    String? plannedExerciseId,
    String? exerciseId,
    String? performedDate,
    String? performedAt,
    int? sets,
    int? reps,
    double? weightKg,
    int? durationMinutes,
    String? memo,
    bool? completed,
  }) {
    return WorkoutLogEntity(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      plannedExerciseId: plannedExerciseId ?? this.plannedExerciseId,
      exerciseId: exerciseId ?? this.exerciseId,
      performedDate: performedDate ?? this.performedDate,
      performedAt: performedAt ?? this.performedAt,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      weightKg: weightKg ?? this.weightKg,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      memo: memo ?? this.memo,
      completed: completed ?? this.completed,
    );
  }
}

class WorkoutSetLogEntity {
  const WorkoutSetLogEntity({
    this.id = 0,
    required this.workoutLogId,
    required this.setIndex,
    required this.reps,
    required this.weightKg,
    required this.durationMinutes,
  });

  final int id;
  final int workoutLogId;
  final int setIndex;
  final int? reps;
  final double? weightKg;
  final int? durationMinutes;

  WorkoutSetLogEntity copyWith({
    int? id,
    int? workoutLogId,
    int? setIndex,
    int? reps,
    double? weightKg,
    int? durationMinutes,
  }) {
    return WorkoutSetLogEntity(
      id: id ?? this.id,
      workoutLogId: workoutLogId ?? this.workoutLogId,
      setIndex: setIndex ?? this.setIndex,
      reps: reps ?? this.reps,
      weightKg: weightKg ?? this.weightKg,
      durationMinutes: durationMinutes ?? this.durationMinutes,
    );
  }
}

class WorkoutLogWithSets {
  const WorkoutLogWithSets({required this.log, required this.setLogs});

  final WorkoutLogEntity log;
  final List<WorkoutSetLogEntity> setLogs;
}
