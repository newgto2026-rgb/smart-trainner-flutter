import 'package:smart_trainner_core_model/smart_trainner_core_model.dart';

enum TrainingTab { home, plan, exercises, analysis }

enum RecordFormError {
  selectExercise,
  sets,
  reps,
  weight,
  duration,
  rest,
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
    this.restSeconds = '',
  });

  final String reps;
  final String weightKg;
  final String durationMinutes;
  final String restSeconds;

  RecordSetFormState copyWith({
    String? reps,
    String? weightKg,
    String? durationMinutes,
    String? restSeconds,
  }) {
    return RecordSetFormState(
      reps: reps ?? this.reps,
      weightKg: weightKg ?? this.weightKg,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      restSeconds: restSeconds ?? this.restSeconds,
    );
  }
}

class CustomRoutineDayFormState {
  const CustomRoutineDayFormState({
    this.focus,
    this.exercises = const <ExerciseId>[],
  });

  final RoutineFocus? focus;
  final List<ExerciseId> exercises;

  CustomRoutineDayFormState copyWith({
    RoutineFocus? focus,
    bool clearFocus = false,
    List<ExerciseId>? exercises,
  }) {
    return CustomRoutineDayFormState(
      focus: clearFocus ? null : focus ?? this.focus,
      exercises: exercises ?? this.exercises,
    );
  }
}

class CustomRoutineBuilderState {
  const CustomRoutineBuilderState({
    this.visible = false,
    this.name = '',
    this.days = const <CustomRoutineDayFormState>[CustomRoutineDayFormState()],
    this.selectedDayIndex = 0,
    this.focusMenuVisible = false,
    this.expandedExerciseGroups = const <MuscleGroup>{},
    this.editingTemplateId,
  });

  final bool visible;
  final String name;
  final List<CustomRoutineDayFormState> days;
  final int selectedDayIndex;
  final bool focusMenuVisible;
  final Set<MuscleGroup> expandedExerciseGroups;
  final String? editingTemplateId;

  CustomRoutineDayFormState get selectedDay => days[selectedDayIndex];

  CustomRoutineBuilderState copyWith({
    bool? visible,
    String? name,
    List<CustomRoutineDayFormState>? days,
    int? selectedDayIndex,
    bool? focusMenuVisible,
    Set<MuscleGroup>? expandedExerciseGroups,
    String? editingTemplateId,
    bool clearEditingTemplateId = false,
  }) {
    final nextDays = days ?? this.days;
    final nextIndex = (selectedDayIndex ?? this.selectedDayIndex).clamp(
      0,
      nextDays.length - 1,
    );
    return CustomRoutineBuilderState(
      visible: visible ?? this.visible,
      name: name ?? this.name,
      days: nextDays,
      selectedDayIndex: nextIndex.toInt(),
      focusMenuVisible: focusMenuVisible ?? this.focusMenuVisible,
      expandedExerciseGroups:
          expandedExerciseGroups ?? this.expandedExerciseGroups,
      editingTemplateId: clearEditingTemplateId
          ? null
          : editingTemplateId ?? this.editingTemplateId,
    );
  }
}

class TrainingUiState {
  const TrainingUiState({
    this.selectedTab = TrainingTab.home,
    this.templates = const <PlanTemplate>[],
    this.selectedTemplateId = '',
    this.activeRoutineTemplateId = '',
    this.activeRoutineDayIndex = 0,
    this.plan,
    this.exercises = const <Exercise>[],
    this.logs = const <WorkoutLog>[],
    this.summary,
    this.customTemplates = const <PlanTemplate>[],
    this.selectedExercise,
    this.detailDialogExercise,
    this.imageViewerExercise,
    this.imageViewerStepIndex,
    this.selectedPlannedExercise,
    this.recordingPlannedExercise,
    this.recordForm = const RecordFormState(),
    this.formError,
    this.recordSaved = false,
    this.routineLibraryVisible = false,
    this.routineSettingsVisible = false,
    this.routineRecommendationsVisible = false,
    this.customRoutineBuilder = const CustomRoutineBuilderState(),
  });

  final TrainingTab selectedTab;
  final List<PlanTemplate> templates;
  final String selectedTemplateId;
  final String activeRoutineTemplateId;
  final int activeRoutineDayIndex;
  final WeeklyPlan? plan;
  final List<Exercise> exercises;
  final List<WorkoutLog> logs;
  final WeeklySummary? summary;
  final List<PlanTemplate> customTemplates;
  final Exercise? selectedExercise;
  final Exercise? detailDialogExercise;
  final Exercise? imageViewerExercise;
  final int? imageViewerStepIndex;
  final PlannedExercise? selectedPlannedExercise;
  final PlannedExercise? recordingPlannedExercise;
  final RecordFormState recordForm;
  final RecordFormError? formError;
  final bool recordSaved;
  final bool routineLibraryVisible;
  final bool routineSettingsVisible;
  final bool routineRecommendationsVisible;
  final CustomRoutineBuilderState customRoutineBuilder;

  Set<PlannedExerciseId> get completedPlannedExerciseIds {
    return logs
        .where((log) => log.completed)
        .map((log) => log.plannedExerciseId)
        .toSet();
  }

  ExerciseId? get selectedExerciseId => selectedExercise?.id;

  List<PlanTemplate> get allTemplates => <PlanTemplate>[
    ...templates,
    ...customTemplates,
  ];

  PlanTemplate? get activeRoutineTemplate {
    final id = activeRoutineTemplateId.isEmpty
        ? selectedTemplateId
        : activeRoutineTemplateId;
    for (final template in allTemplates) {
      if (template.id == id) {
        return template;
      }
    }
    return allTemplates.isEmpty ? null : allTemplates.first;
  }

  PlanTemplate? get recommendedRoutineTemplate {
    for (final template in templates) {
      if (template.id == 'intermediate-body-part-4day-60') {
        return template;
      }
    }
    return templates.isEmpty ? null : templates.last;
  }

  TrainingUiState copyWith({
    TrainingTab? selectedTab,
    List<PlanTemplate>? templates,
    String? selectedTemplateId,
    String? activeRoutineTemplateId,
    int? activeRoutineDayIndex,
    WeeklyPlan? plan,
    List<Exercise>? exercises,
    List<WorkoutLog>? logs,
    WeeklySummary? summary,
    List<PlanTemplate>? customTemplates,
    Exercise? selectedExercise,
    bool clearSelectedExercise = false,
    Exercise? detailDialogExercise,
    bool clearDetailDialogExercise = false,
    Exercise? imageViewerExercise,
    int? imageViewerStepIndex,
    bool clearImageViewer = false,
    PlannedExercise? selectedPlannedExercise,
    PlannedExercise? recordingPlannedExercise,
    bool clearRecordingPlannedExercise = false,
    RecordFormState? recordForm,
    RecordFormError? formError,
    bool clearFormError = false,
    bool? recordSaved,
    bool? routineLibraryVisible,
    bool? routineSettingsVisible,
    bool? routineRecommendationsVisible,
    CustomRoutineBuilderState? customRoutineBuilder,
  }) {
    return TrainingUiState(
      selectedTab: selectedTab ?? this.selectedTab,
      templates: templates ?? this.templates,
      selectedTemplateId: selectedTemplateId ?? this.selectedTemplateId,
      activeRoutineTemplateId:
          activeRoutineTemplateId ?? this.activeRoutineTemplateId,
      activeRoutineDayIndex:
          activeRoutineDayIndex ?? this.activeRoutineDayIndex,
      plan: plan ?? this.plan,
      exercises: exercises ?? this.exercises,
      logs: logs ?? this.logs,
      summary: summary ?? this.summary,
      customTemplates: customTemplates ?? this.customTemplates,
      selectedExercise: clearSelectedExercise
          ? null
          : selectedExercise ?? this.selectedExercise,
      detailDialogExercise: clearDetailDialogExercise
          ? null
          : detailDialogExercise ?? this.detailDialogExercise,
      imageViewerExercise: clearImageViewer
          ? null
          : imageViewerExercise ?? this.imageViewerExercise,
      imageViewerStepIndex: clearImageViewer
          ? null
          : imageViewerStepIndex ?? this.imageViewerStepIndex,
      selectedPlannedExercise:
          selectedPlannedExercise ?? this.selectedPlannedExercise,
      recordingPlannedExercise: clearRecordingPlannedExercise
          ? null
          : recordingPlannedExercise ?? this.recordingPlannedExercise,
      recordForm: recordForm ?? this.recordForm,
      formError: clearFormError ? null : formError ?? this.formError,
      recordSaved: recordSaved ?? this.recordSaved,
      routineLibraryVisible:
          routineLibraryVisible ?? this.routineLibraryVisible,
      routineSettingsVisible:
          routineSettingsVisible ?? this.routineSettingsVisible,
      routineRecommendationsVisible:
          routineRecommendationsVisible ?? this.routineRecommendationsVisible,
      customRoutineBuilder: customRoutineBuilder ?? this.customRoutineBuilder,
    );
  }
}
