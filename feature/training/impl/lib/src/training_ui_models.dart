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
    );
  }
}
