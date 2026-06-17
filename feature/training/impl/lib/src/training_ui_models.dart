import 'package:smart_trainner_core_model/smart_trainner_core_model.dart';

enum TrainingTab { home, plan, exercises, analysis }

enum RecordFormError {
  selectExercise,
  sets,
  reps,
  weight,
  duration,
  saveFailed,
}

enum CustomExerciseFormError {
  name,
  muscleGroup,
  equipment,
  difficulty,
  summary,
  instructions,
  safetyCues,
  sets,
  reps,
  duration,
  rest,
  saveFailed,
}

class CustomExerciseFormState {
  const CustomExerciseFormState({
    this.name = '',
    this.muscleGroup,
    this.equipment,
    this.difficulty,
    this.targetType = CustomExerciseTargetType.reps,
    this.summary = '',
    this.instructions = '',
    this.safetyCues = '',
    this.defaultSets = '3',
    this.repRangeFirst = '8',
    this.repRangeLast = '12',
    this.durationMinutes = '10',
    this.restSeconds = '60',
    this.imagePath = '',
  });

  final String name;
  final MuscleGroup? muscleGroup;
  final EquipmentType? equipment;
  final DifficultyLevel? difficulty;
  final CustomExerciseTargetType targetType;
  final String summary;
  final String instructions;
  final String safetyCues;
  final String defaultSets;
  final String repRangeFirst;
  final String repRangeLast;
  final String durationMinutes;
  final String restSeconds;
  final String imagePath;

  CustomExerciseFormState copyWith({
    String? name,
    MuscleGroup? muscleGroup,
    EquipmentType? equipment,
    DifficultyLevel? difficulty,
    CustomExerciseTargetType? targetType,
    String? summary,
    String? instructions,
    String? safetyCues,
    String? defaultSets,
    String? repRangeFirst,
    String? repRangeLast,
    String? durationMinutes,
    String? restSeconds,
    String? imagePath,
  }) {
    return CustomExerciseFormState(
      name: name ?? this.name,
      muscleGroup: muscleGroup ?? this.muscleGroup,
      equipment: equipment ?? this.equipment,
      difficulty: difficulty ?? this.difficulty,
      targetType: targetType ?? this.targetType,
      summary: summary ?? this.summary,
      instructions: instructions ?? this.instructions,
      safetyCues: safetyCues ?? this.safetyCues,
      defaultSets: defaultSets ?? this.defaultSets,
      repRangeFirst: repRangeFirst ?? this.repRangeFirst,
      repRangeLast: repRangeLast ?? this.repRangeLast,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      restSeconds: restSeconds ?? this.restSeconds,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}

class RecordFormState {
  const RecordFormState({
    this.setEntries = const <RecordSetFormState>[],
    this.memo = '',
  });

  final List<RecordSetFormState> setEntries;
  final String memo;

  RecordFormState copyWith({
    List<RecordSetFormState>? setEntries,
    String? memo,
  }) {
    return RecordFormState(
      setEntries: setEntries ?? this.setEntries,
      memo: memo ?? this.memo,
    );
  }
}

class RecordSetFormState {
  const RecordSetFormState({
    this.reps = '',
    this.weightKg = '',
    this.durationMinutes = '',
  });

  final String reps;
  final String weightKg;
  final String durationMinutes;

  RecordSetFormState copyWith({
    String? reps,
    String? weightKg,
    String? durationMinutes,
  }) {
    return RecordSetFormState(
      reps: reps ?? this.reps,
      weightKg: weightKg ?? this.weightKg,
      durationMinutes: durationMinutes ?? this.durationMinutes,
    );
  }
}

class TrainingUiState {
  const TrainingUiState({
    this.selectedTab = TrainingTab.home,
    this.templates = const <PlanTemplate>[],
    this.selectedTemplateId = '',
    this.plan,
    this.exercises = const <Exercise>[],
    this.logs = const <WorkoutLog>[],
    this.summary,
    this.selectedExercise,
    this.selectedPlannedExercise,
    this.recordingPlannedExercise,
    this.recordForm = const RecordFormState(),
    this.formError,
    this.recordSaved = false,
    this.isCustomExerciseFormVisible = false,
    this.customExerciseForm = const CustomExerciseFormState(),
    this.customExerciseFormError,
    this.lastCreatedCustomExerciseId,
  });

  final TrainingTab selectedTab;
  final List<PlanTemplate> templates;
  final String selectedTemplateId;
  final WeeklyPlan? plan;
  final List<Exercise> exercises;
  final List<WorkoutLog> logs;
  final WeeklySummary? summary;
  final Exercise? selectedExercise;
  final PlannedExercise? selectedPlannedExercise;
  final PlannedExercise? recordingPlannedExercise;
  final RecordFormState recordForm;
  final RecordFormError? formError;
  final bool recordSaved;
  final bool isCustomExerciseFormVisible;
  final CustomExerciseFormState customExerciseForm;
  final CustomExerciseFormError? customExerciseFormError;
  final ExerciseId? lastCreatedCustomExerciseId;

  Set<PlannedExerciseId> get completedPlannedExerciseIds {
    return logs
        .where((log) => log.completed)
        .map((log) => log.plannedExerciseId)
        .toSet();
  }

  ExerciseId? get selectedExerciseId => selectedExercise?.id;

  TrainingUiState copyWith({
    TrainingTab? selectedTab,
    List<PlanTemplate>? templates,
    String? selectedTemplateId,
    WeeklyPlan? plan,
    List<Exercise>? exercises,
    List<WorkoutLog>? logs,
    WeeklySummary? summary,
    Exercise? selectedExercise,
    bool clearSelectedExercise = false,
    PlannedExercise? selectedPlannedExercise,
    PlannedExercise? recordingPlannedExercise,
    bool clearRecordingPlannedExercise = false,
    RecordFormState? recordForm,
    RecordFormError? formError,
    bool clearFormError = false,
    bool? recordSaved,
    bool? isCustomExerciseFormVisible,
    CustomExerciseFormState? customExerciseForm,
    CustomExerciseFormError? customExerciseFormError,
    bool clearCustomExerciseFormError = false,
    ExerciseId? lastCreatedCustomExerciseId,
    bool clearLastCreatedCustomExerciseId = false,
  }) {
    return TrainingUiState(
      selectedTab: selectedTab ?? this.selectedTab,
      templates: templates ?? this.templates,
      selectedTemplateId: selectedTemplateId ?? this.selectedTemplateId,
      plan: plan ?? this.plan,
      exercises: exercises ?? this.exercises,
      logs: logs ?? this.logs,
      summary: summary ?? this.summary,
      selectedExercise: clearSelectedExercise
          ? null
          : selectedExercise ?? this.selectedExercise,
      selectedPlannedExercise:
          selectedPlannedExercise ?? this.selectedPlannedExercise,
      recordingPlannedExercise: clearRecordingPlannedExercise
          ? null
          : recordingPlannedExercise ?? this.recordingPlannedExercise,
      recordForm: recordForm ?? this.recordForm,
      formError: clearFormError ? null : formError ?? this.formError,
      recordSaved: recordSaved ?? this.recordSaved,
      isCustomExerciseFormVisible:
          isCustomExerciseFormVisible ?? this.isCustomExerciseFormVisible,
      customExerciseForm: customExerciseForm ?? this.customExerciseForm,
      customExerciseFormError: clearCustomExerciseFormError
          ? null
          : customExerciseFormError ?? this.customExerciseFormError,
      lastCreatedCustomExerciseId: clearLastCreatedCustomExerciseId
          ? null
          : lastCreatedCustomExerciseId ?? this.lastCreatedCustomExerciseId,
    );
  }
}
