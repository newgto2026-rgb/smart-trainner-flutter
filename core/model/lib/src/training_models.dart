class ExerciseId {
  const ExerciseId(this.value);

  final String value;

  @override
  bool operator ==(Object other) => other is ExerciseId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

class PlanId {
  const PlanId(this.value);

  final String value;

  @override
  bool operator ==(Object other) => other is PlanId && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

class PlannedExerciseId {
  const PlannedExerciseId(this.value);

  final String value;

  @override
  bool operator ==(Object other) =>
      other is PlannedExerciseId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

class WorkoutLogId {
  const WorkoutLogId(this.value);

  final int value;

  @override
  bool operator ==(Object other) =>
      other is WorkoutLogId && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

class UserSessionId {
  const UserSessionId(this.value);

  final String value;

  @override
  bool operator ==(Object other) =>
      other is UserSessionId && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

enum AuthProvider { local, google }

class UserSession {
  const UserSession({
    required this.id,
    required this.displayName,
    required this.email,
    required this.provider,
    required this.linkedAt,
  });

  final UserSessionId id;
  final String displayName;
  final String? email;
  final AuthProvider provider;
  final String? linkedAt;

  bool get isLinked => provider != AuthProvider.local;
}

enum MuscleGroup {
  lowerBody('하체'),
  back('등'),
  chest('가슴'),
  shoulders('어깨'),
  arms('팔'),
  biceps('이두'),
  triceps('삼두'),
  forearms('전완근'),
  core('코어'),
  cardio('유산소'),
  fullBody('전신');

  const MuscleGroup(this.displayName);

  final String displayName;
}

enum EquipmentType {
  bodyweight('맨몸'),
  dumbbell('덤벨'),
  kettlebell('케틀벨'),
  barbell('바벨'),
  machine('머신'),
  cable('케이블'),
  bench('벤치'),
  cardioMachine('유산소 머신');

  const EquipmentType(this.displayName);

  final String displayName;
}

enum DifficultyLevel {
  beginner('초보'),
  intermediate('초중급'),
  advanced('숙련');

  const DifficultyLevel(this.displayName);

  final String displayName;
}

enum PlanLevel {
  intro('입문'),
  beginner('초보'),
  intermediate('초중급');

  const PlanLevel(this.displayName);

  final String displayName;
}

enum RoutineStructure { fullBody, balancedSplit, bodyPartSplit }

enum RoutineSource { system, custom }

enum RoutineFocus {
  fullBody,
  upperBody,
  push,
  pull,
  chest,
  back,
  lowerBody,
  shoulders,
  arms,
  biceps,
  triceps,
  forearms,
  cardioConditioning,
  core,
}

enum TrainingExperience { beginner, intermediate }

enum RoutineFeeling { balancedFullBody, focusedBodyPart, appRecommended }

class RepRange {
  const RepRange(this.first, this.last);

  final int first;
  final int last;

  @override
  bool operator ==(Object other) =>
      other is RepRange && other.first == first && other.last == last;

  @override
  int get hashCode => Object.hash(first, last);
}

class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.muscleGroup,
    required this.equipment,
    required this.difficulty,
    required this.imageKey,
    required this.summary,
    required this.instructions,
    required this.safetyCues,
    required this.defaultSets,
    required this.defaultRepRange,
    required this.defaultDurationMinutes,
    required this.restSeconds,
  });

  final ExerciseId id;
  final String name;
  final MuscleGroup muscleGroup;
  final EquipmentType equipment;
  final DifficultyLevel difficulty;
  final String imageKey;
  final String summary;
  final List<String> instructions;
  final List<String> safetyCues;
  final int defaultSets;
  final RepRange? defaultRepRange;
  final int? defaultDurationMinutes;
  final int restSeconds;

  String get targetText {
    final repRange = defaultRepRange;
    if (repRange != null) {
      return '$defaultSets세트 x ${repRange.first}-${repRange.last}회';
    }
    return '$defaultSets세트 x ${defaultDurationMinutes ?? 10}분';
  }
}

class PlanTemplate {
  const PlanTemplate({
    required this.id,
    required this.name,
    required this.level,
    required this.daysPerWeek,
    required this.description,
    required this.days,
    this.structure = RoutineStructure.fullBody,
    this.recommendedExperience = TrainingExperience.beginner,
    int? cycleLength,
    this.sessionMinutes = 45,
    this.focusSummary = const <RoutineFocus>[RoutineFocus.fullBody],
    this.source = RoutineSource.system,
  }) : _cycleLength = cycleLength;

  final String id;
  final String name;
  final PlanLevel level;
  final int daysPerWeek;
  final String description;
  final List<PlanTemplateDay> days;
  final RoutineStructure structure;
  final TrainingExperience recommendedExperience;
  final int? _cycleLength;
  final int sessionMinutes;
  final List<RoutineFocus> focusSummary;
  final RoutineSource source;

  int get cycleLength => _cycleLength ?? days.length;
}

class PlanTemplateDay {
  const PlanTemplateDay({
    required this.dayOffset,
    required this.title,
    required this.focus,
    required this.exercises,
    int? dayNumber,
    this.primaryFocus = RoutineFocus.fullBody,
    this.secondaryFocuses = const <RoutineFocus>[],
    this.minRecoveryHours = 24,
  }) : _dayNumber = dayNumber;

  final int dayOffset;
  final String title;
  final String focus;
  final List<TemplateExercise> exercises;
  final int? _dayNumber;
  final RoutineFocus? primaryFocus;
  final List<RoutineFocus> secondaryFocuses;
  final int minRecoveryHours;

  int get dayNumber => _dayNumber ?? dayOffset + 1;
}

class TemplateExercise {
  const TemplateExercise({
    required this.exerciseId,
    required this.sets,
    required this.repRange,
    required this.durationMinutes,
    required this.restSeconds,
    required this.note,
  });

  final ExerciseId exerciseId;
  final int sets;
  final RepRange? repRange;
  final int? durationMinutes;
  final int restSeconds;
  final String note;
}

class CustomRoutineInput {
  const CustomRoutineInput({
    this.id,
    required this.name,
    this.description = '',
    required this.days,
  });

  final String? id;
  final String name;
  final String description;
  final List<CustomRoutineDayInput> days;
}

class CustomRoutineDayInput {
  const CustomRoutineDayInput({
    required this.title,
    required this.focus,
    required this.primaryFocus,
    this.secondaryFocuses = const <RoutineFocus>[],
    this.minRecoveryHours = 24,
    required this.exercises,
  });

  final String title;
  final String focus;
  final RoutineFocus? primaryFocus;
  final List<RoutineFocus> secondaryFocuses;
  final int minRecoveryHours;
  final List<CustomRoutineExerciseInput> exercises;
}

class CustomRoutineExerciseInput {
  const CustomRoutineExerciseInput({
    required this.exerciseId,
    required this.sets,
    required this.repRangeStart,
    required this.repRangeEnd,
    required this.durationMinutes,
    required this.restSeconds,
    this.note = '',
  });

  final ExerciseId exerciseId;
  final int sets;
  final int? repRangeStart;
  final int? repRangeEnd;
  final int? durationMinutes;
  final int restSeconds;
  final String note;
}

class WeeklyPlan {
  const WeeklyPlan({
    required this.id,
    required this.templateId,
    required this.name,
    required this.weekStartDate,
    required this.days,
  });

  final PlanId id;
  final String templateId;
  final String name;
  final DateTime weekStartDate;
  final List<WorkoutDayPlan> days;
}

class WorkoutDayPlan {
  const WorkoutDayPlan({
    required this.date,
    required this.title,
    required this.focus,
    required this.exercises,
    this.dayNumber = 1,
    this.primaryFocus = RoutineFocus.fullBody,
    this.secondaryFocuses = const <RoutineFocus>[],
    this.minRecoveryHours = 24,
  });

  final DateTime date;
  final String title;
  final String focus;
  final List<PlannedExercise> exercises;
  final int dayNumber;
  final RoutineFocus? primaryFocus;
  final List<RoutineFocus> secondaryFocuses;
  final int minRecoveryHours;
}

class RoutineRecommendationInput {
  const RoutineRecommendationInput({
    required this.daysPerWeek,
    required this.sessionMinutes,
    required this.experience,
    required this.feeling,
  });

  final int daysPerWeek;
  final int sessionMinutes;
  final TrainingExperience experience;
  final RoutineFeeling feeling;
}

class RoutineRecommendation {
  const RoutineRecommendation({
    required this.primaryTemplateId,
    required this.alternativeTemplateIds,
    required this.reasonCode,
  });

  final String primaryTemplateId;
  final List<String> alternativeTemplateIds;
  final String reasonCode;
}

class RoutineProgressPreference {
  const RoutineProgressPreference({
    required this.templateId,
    required this.dayIndex,
    required this.startedAt,
    required this.cycleStartedAt,
    required this.lastCompletedDayIndex,
    required this.lastCompletedAt,
  });

  final String templateId;
  final int dayIndex;
  final String? startedAt;
  final String? cycleStartedAt;
  final int? lastCompletedDayIndex;
  final String? lastCompletedAt;
}

class RoutineProgress {
  const RoutineProgress({
    required this.templateId,
    required this.dayIndex,
    required this.lastCompletedDayIndex,
    required this.lastCompletedAt,
    this.startedAt,
    DateTime? cycleStartedAt,
  }) : cycleStartedAt = cycleStartedAt ?? startedAt;

  final String templateId;
  final int dayIndex;
  final int? lastCompletedDayIndex;
  final DateTime? lastCompletedAt;
  final DateTime? startedAt;
  final DateTime? cycleStartedAt;
}

class RoutineReadiness {
  const RoutineReadiness({
    required this.ready,
    required this.remainingRecoveryHours,
    required this.warningCode,
  });

  final bool ready;
  final int remainingRecoveryHours;
  final String? warningCode;
}

class PlannedExercise {
  const PlannedExercise({
    required this.id,
    required this.exercise,
    required this.sets,
    required this.repRange,
    required this.durationMinutes,
    required this.restSeconds,
    required this.note,
  });

  final PlannedExerciseId id;
  final Exercise exercise;
  final int sets;
  final RepRange? repRange;
  final int? durationMinutes;
  final int restSeconds;
  final String note;

  String get targetText {
    final range = repRange;
    if (range != null) {
      return '$sets세트 x ${range.first}-${range.last}회';
    }
    return '$sets세트 x ${durationMinutes ?? 10}분';
  }
}

class WorkoutLog {
  const WorkoutLog({
    required this.id,
    required this.sessionId,
    required this.plannedExerciseId,
    required this.exerciseId,
    required this.performedAt,
    required this.sets,
    required this.reps,
    required this.weightKg,
    required this.durationMinutes,
    required this.memo,
    required this.completed,
    this.setEntries = const <WorkoutSetLog>[],
  });

  final WorkoutLogId id;
  final UserSessionId sessionId;
  final PlannedExerciseId plannedExerciseId;
  final ExerciseId exerciseId;
  final DateTime performedAt;
  final int sets;
  final int? reps;
  final double? weightKg;
  final int? durationMinutes;
  final String memo;
  final bool completed;
  final List<WorkoutSetLog> setEntries;

  double get volumeKg {
    if (setEntries.isNotEmpty) {
      return setEntries.fold<double>(0, (sum, entry) => sum + entry.volumeKg);
    }
    final reps = this.reps;
    final weightKg = this.weightKg;
    if (reps != null && weightKg != null) {
      return sets * reps * weightKg;
    }
    return 0;
  }
}

class WorkoutLogInput {
  const WorkoutLogInput({
    required this.plannedExerciseId,
    required this.exerciseId,
    required this.performedAt,
    required this.sets,
    required this.reps,
    required this.weightKg,
    required this.durationMinutes,
    required this.memo,
    required this.completed,
    this.setEntries = const <WorkoutSetLog>[],
  });

  final PlannedExerciseId plannedExerciseId;
  final ExerciseId exerciseId;
  final DateTime performedAt;
  final int sets;
  final int? reps;
  final double? weightKg;
  final int? durationMinutes;
  final String memo;
  final bool completed;
  final List<WorkoutSetLog> setEntries;

  WorkoutLogInput copyWith({int? sets, List<WorkoutSetLog>? setEntries}) {
    return WorkoutLogInput(
      plannedExerciseId: plannedExerciseId,
      exerciseId: exerciseId,
      performedAt: performedAt,
      sets: sets ?? this.sets,
      reps: reps,
      weightKg: weightKg,
      durationMinutes: durationMinutes,
      memo: memo,
      completed: completed,
      setEntries: setEntries ?? this.setEntries,
    );
  }
}

class WorkoutSetLog {
  const WorkoutSetLog({
    required this.order,
    required this.reps,
    required this.weightKg,
    required this.durationMinutes,
    this.restSeconds,
  });

  final int order;
  final int? reps;
  final double? weightKg;
  final int? durationMinutes;
  final int? restSeconds;

  double get volumeKg {
    final reps = this.reps;
    final weightKg = this.weightKg;
    if (reps != null && weightKg != null) {
      return reps * weightKg;
    }
    return 0;
  }
}

class WeeklySummary {
  const WeeklySummary({
    required this.weekStartDate,
    required this.plannedExerciseCount,
    required this.completedExerciseCount,
    required this.totalSets,
    required this.totalVolumeKg,
    required this.totalMinutes,
    required this.streakDays,
    required this.muscleBalance,
    required this.insight,
  });

  final DateTime weekStartDate;
  final int plannedExerciseCount;
  final int completedExerciseCount;
  final int totalSets;
  final double totalVolumeKg;
  final int totalMinutes;
  final int streakDays;
  final Map<MuscleGroup, int> muscleBalance;
  final String insight;

  int get completionRate {
    if (plannedExerciseCount == 0) {
      return 0;
    }
    return completedExerciseCount * 100 ~/ plannedExerciseCount;
  }
}

DateTime dateOnly(int year, int month, int day) => DateTime(year, month, day);

DateTime normalizeDate(DateTime date) =>
    DateTime(date.year, date.month, date.day);
