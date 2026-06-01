class CustomRoutineEntity {
  const CustomRoutineEntity({
    required this.id,
    required this.sessionId,
    required this.name,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String sessionId;
  final String name;
  final String description;
  final String createdAt;
  final String updatedAt;
}

class CustomRoutineDayEntity {
  const CustomRoutineDayEntity({
    required this.id,
    required this.routineId,
    required this.dayIndex,
    required this.title,
    required this.focus,
    required this.primaryFocus,
    required this.secondaryFocuses,
    required this.minRecoveryHours,
  });

  final String id;
  final String routineId;
  final int dayIndex;
  final String title;
  final String focus;
  final String? primaryFocus;
  final String secondaryFocuses;
  final int minRecoveryHours;
}

class CustomRoutineExerciseEntity {
  const CustomRoutineExerciseEntity({
    required this.id,
    required this.dayId,
    required this.slotIndex,
    required this.exerciseId,
    required this.sets,
    required this.repRangeStart,
    required this.repRangeEnd,
    required this.durationMinutes,
    required this.restSeconds,
    required this.note,
  });

  final String id;
  final String dayId;
  final int slotIndex;
  final String exerciseId;
  final int sets;
  final int? repRangeStart;
  final int? repRangeEnd;
  final int? durationMinutes;
  final int restSeconds;
  final String note;
}

class CustomRoutineWithDays {
  const CustomRoutineWithDays({required this.routine, required this.days});

  final CustomRoutineEntity routine;
  final List<CustomRoutineDayWithExercises> days;
}

class CustomRoutineDayWithExercises {
  const CustomRoutineDayWithExercises({
    required this.day,
    required this.exercises,
  });

  final CustomRoutineDayEntity day;
  final List<CustomRoutineExerciseEntity> exercises;
}

class CustomRoutineDayWrite {
  const CustomRoutineDayWrite({required this.day, required this.exercises});

  final CustomRoutineDayEntity day;
  final List<CustomRoutineExerciseEntity> exercises;
}
