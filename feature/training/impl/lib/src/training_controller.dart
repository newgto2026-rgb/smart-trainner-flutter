import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:smart_trainner_core_domain/smart_trainner_core_domain.dart';
import 'package:smart_trainner_core_model/smart_trainner_core_model.dart';
import 'package:smart_trainner_feature_routine_domain/smart_trainner_feature_routine_domain.dart';
import 'package:smart_trainner_feature_training_impl/src/training_ui_models.dart';

class TrainingController extends ChangeNotifier {
  TrainingController({
    required ObserveExercisesUseCase observeExercises,
    required ObservePlanTemplatesUseCase observePlanTemplates,
    required ObserveCurrentWeeklyPlanUseCase observeCurrentWeeklyPlan,
    required ObserveWorkoutLogsUseCase observeWorkoutLogs,
    required ObserveWeeklySummaryUseCase observeWeeklySummary,
    required SelectPlanTemplateUseCase selectPlanTemplate,
    required SaveWorkoutLogUseCase saveWorkoutLog,
    DateTime? today,
  }) : _selectPlanTemplate = selectPlanTemplate,
       _saveWorkoutLog = saveWorkoutLog,
       _weekStart = _mondayOf(today ?? DateTime.now()) {
    _subscriptions
      ..add(
        observePlanTemplates().listen((templates) {
          _state = _state.copyWith(templates: templates);
          _refreshSelectedPlannedExercise();
        }),
      )
      ..add(
        observeCurrentWeeklyPlan(_weekStart).listen((plan) {
          _state = _state.copyWith(
            plan: plan,
            selectedTemplateId: plan.templateId,
            activeRoutineTemplateId: _state.activeRoutineTemplateId.isEmpty
                ? plan.templateId
                : _state.activeRoutineTemplateId,
          );
          _refreshSelectedPlannedExercise();
        }),
      )
      ..add(
        observeWorkoutLogs(_weekStart).listen((logs) {
          _state = _state.copyWith(logs: logs);
          _refreshSelectedPlannedExercise();
        }),
      )
      ..add(
        observeWeeklySummary(_weekStart).listen((summary) {
          _state = _state.copyWith(summary: summary);
          notifyListeners();
        }),
      )
      ..add(
        observeExercises().listen((exercises) {
          _state = _state.copyWith(exercises: exercises);
          notifyListeners();
        }),
      );
  }

  final SelectPlanTemplateUseCase _selectPlanTemplate;
  final SaveWorkoutLogUseCase _saveWorkoutLog;
  final AdvanceRoutineDayUseCase _advanceRoutineDay =
      const AdvanceRoutineDayUseCase();
  final DateTime _weekStart;
  final List<StreamSubscription<dynamic>> _subscriptions =
      <StreamSubscription<dynamic>>[];
  TrainingUiState _state = const TrainingUiState();

  TrainingUiState get state => _state;

  void selectTab(TrainingTab tab) {
    _state = _state.copyWith(
      selectedTab: tab,
      clearFormError: true,
      recordSaved: false,
    );
    notifyListeners();
  }

  Future<void> selectTemplate(String templateId) async {
    await selectRoutineTemplate(templateId);
  }

  void selectExercise(ExerciseId exerciseId) {
    final exercise = _state.exercises.firstWhere(
      (exercise) => exercise.id == exerciseId,
    );
    _state = _state.copyWith(
      detailDialogExercise: exercise,
      selectedTab: TrainingTab.exercises,
    );
    notifyListeners();
  }

  void dismissExerciseDetail() {
    _state = _state.copyWith(clearSelectedExercise: true);
    notifyListeners();
  }

  void selectPlannedExercise(PlannedExercise exercise) {
    _state = _state.copyWith(
      selectedPlannedExercise: exercise,
      recordingPlannedExercise: exercise,
      clearSelectedExercise: true,
      recordForm: RecordFormState(setEntries: exercise.defaultSetForms()),
      clearFormError: true,
      recordSaved: false,
    );
    notifyListeners();
  }

  void startWorkoutForActiveRoutineDay() {
    final planned = _activeRoutineDayPlan()?.exercises.firstOrNull;
    if (planned != null) {
      selectPlannedExercise(planned);
    }
  }

  void dismissRecordDialog() {
    _state = _state.copyWith(
      clearRecordingPlannedExercise: true,
      clearFormError: true,
      recordSaved: false,
    );
    notifyListeners();
  }

  void updateSetReps(int index, String value) {
    _updateSetEntry(index, (entry) => entry.copyWith(reps: value.onlyNumber()));
  }

  void updateSetWeight(int index, String value) {
    _updateSetEntry(
      index,
      (entry) => entry.copyWith(weightKg: value.onlyDecimal()),
    );
  }

  void updateSetDuration(int index, String value) {
    _updateSetEntry(
      index,
      (entry) => entry.copyWith(durationMinutes: value.onlyNumber()),
    );
  }

  void updateSetRest(int index, String value) {
    _updateSetEntry(
      index,
      (entry) => entry.copyWith(restSeconds: value.onlyNumber()),
    );
  }

  void addSetEntry() {
    final planned = _state.recordingPlannedExercise;
    if (planned == null) {
      return;
    }
    final entries = _state.recordForm.setEntries;
    if (entries.length >= maxRecordSets) {
      return;
    }
    _state = _state.copyWith(
      recordForm: _state.recordForm.copyWith(
        setEntries: <RecordSetFormState>[
          ...entries,
          entries.isNotEmpty ? entries.last : planned.defaultSetForm(),
        ],
      ),
      clearFormError: true,
    );
    notifyListeners();
  }

  void removeSetEntry(int index) {
    final entries = _state.recordForm.setEntries;
    if (entries.length <= 1 || index < 0 || index >= entries.length) {
      return;
    }
    _state = _state.copyWith(
      recordForm: _state.recordForm.copyWith(
        setEntries: <RecordSetFormState>[
          for (var i = 0; i < entries.length; i++)
            if (i != index) entries[i],
        ],
      ),
      clearFormError: true,
    );
    notifyListeners();
  }

  void updateMemo(String value) {
    _state = _state.copyWith(
      recordForm: _state.recordForm.copyWith(memo: value.take(120)),
    );
    notifyListeners();
  }

  Future<void> saveRecord() async {
    final planned =
        _state.recordingPlannedExercise ?? _state.selectedPlannedExercise;
    if (planned == null) {
      _state = _state.copyWith(formError: RecordFormError.selectExercise);
      notifyListeners();
      return;
    }
    final validationError = validateSetEntries(
      planned,
      _state.recordForm.setEntries,
    );
    if (validationError != null) {
      _state = _state.copyWith(formError: validationError);
      notifyListeners();
      return;
    }
    final setEntries = _state.recordForm.setEntries.toWorkoutSetLogs(planned);
    final firstReps = setEntries
        .where((entry) => entry.reps != null)
        .firstOrNull
        ?.reps;
    final firstWeight = setEntries
        .where((entry) => entry.weightKg != null)
        .firstOrNull
        ?.weightKg;
    final totalDuration = setEntries.fold<int>(
      0,
      (sum, entry) => sum + (entry.durationMinutes ?? 0),
    );
    final result = await _saveWorkoutLog(
      WorkoutLogInput(
        plannedExerciseId: planned.id,
        exerciseId: planned.exercise.id,
        performedAt: DateTime.now(),
        sets: setEntries.length,
        reps: firstReps,
        weightKg: firstWeight,
        durationMinutes: totalDuration > 0 ? totalDuration : null,
        memo: _state.recordForm.memo,
        completed: true,
        setEntries: setEntries,
      ),
    );
    _state = _state.copyWith(
      formError: result.isSuccess ? null : RecordFormError.saveFailed,
      clearFormError: result.isSuccess,
      clearRecordingPlannedExercise: result.isSuccess,
      recordSaved: false,
    );
    if (result.isSuccess) {
      _refreshSelectedPlannedExercise();
      return;
    }
    notifyListeners();
  }

  void showExerciseMethodForRecording() {
    final planned = _state.recordingPlannedExercise;
    if (planned == null) {
      return;
    }
    _state = _state.copyWith(detailDialogExercise: planned.exercise);
    notifyListeners();
  }

  void dismissExerciseMethodDialog() {
    _state = _state.copyWith(clearDetailDialogExercise: true);
    notifyListeners();
  }

  void showImageViewer(Exercise exercise, int stepIndex) {
    _state = _state.copyWith(
      imageViewerExercise: exercise,
      imageViewerStepIndex: stepIndex,
    );
    notifyListeners();
  }

  void dismissImageViewer() {
    _state = _state.copyWith(clearImageViewer: true);
    notifyListeners();
  }

  void openRoutineLibrary() {
    _state = _state.copyWith(
      routineLibraryVisible: true,
      routineSettingsVisible: false,
      routineRecommendationsVisible: false,
    );
    notifyListeners();
  }

  void dismissRoutineLibrary() {
    _state = _state.copyWith(
      routineLibraryVisible: false,
      routineSettingsVisible: false,
      routineRecommendationsVisible: false,
    );
    notifyListeners();
  }

  void openRoutineSettings() {
    _state = _state.copyWith(
      routineLibraryVisible: false,
      routineSettingsVisible: true,
      routineRecommendationsVisible: false,
    );
    notifyListeners();
  }

  void showRoutineRecommendations() {
    _state = _state.copyWith(
      routineLibraryVisible: false,
      routineSettingsVisible: false,
      routineRecommendationsVisible: true,
    );
    notifyListeners();
  }

  Future<void> startRecommendedRoutine() async {
    final template = _state.recommendedRoutineTemplate;
    if (template == null) {
      return;
    }
    await selectRoutineTemplate(template.id);
    _state = _state.copyWith(
      selectedTab: TrainingTab.home,
      routineLibraryVisible: false,
      routineSettingsVisible: false,
      routineRecommendationsVisible: false,
    );
    _refreshSelectedPlannedExercise();
  }

  Future<void> selectRoutineTemplate(String templateId) async {
    final template = _state.allTemplates.firstWhereOrNull(
      (template) => template.id == templateId,
    );
    if (template == null) {
      return;
    }
    if (template.source == RoutineSource.system) {
      await _selectPlanTemplate(templateId);
    }
    _state = _state.copyWith(
      activeRoutineTemplateId: templateId,
      activeRoutineDayIndex: 0,
      selectedTemplateId: template.source == RoutineSource.system
          ? templateId
          : _state.selectedTemplateId,
      routineLibraryVisible: false,
      routineSettingsVisible: false,
      routineRecommendationsVisible: false,
    );
    _refreshSelectedPlannedExercise();
  }

  void completeRoutineDay() {
    final template = _state.activeRoutineTemplate;
    if (template == null || template.cycleLength <= 0) {
      return;
    }
    final completedIndex = _state.activeRoutineDayIndex
        .clamp(0, template.cycleLength - 1)
        .toInt();
    final nextIndex = _advanceRoutineDay(
      completedDayIndex: completedIndex,
      cycleLength: template.cycleLength,
    );
    _state = _state.copyWith(activeRoutineDayIndex: nextIndex);
    _refreshSelectedPlannedExercise();
  }

  void openNewCustomRoutineBuilder() {
    _state = _state.copyWith(
      customRoutineBuilder: const CustomRoutineBuilderState(
        visible: true,
        name: '',
        days: <CustomRoutineDayFormState>[CustomRoutineDayFormState()],
        selectedDayIndex: 0,
      ),
      routineLibraryVisible: false,
      routineSettingsVisible: false,
      routineRecommendationsVisible: false,
    );
    notifyListeners();
  }

  void dismissCustomRoutineBuilder() {
    _state = _state.copyWith(
      customRoutineBuilder: const CustomRoutineBuilderState(),
    );
    notifyListeners();
  }

  void editCustomRoutine(String templateId) {
    final template = _state.customTemplates.firstWhereOrNull(
      (template) => template.id == templateId,
    );
    if (template == null) {
      return;
    }
    _state = _state.copyWith(
      customRoutineBuilder: _builderStateFromTemplate(template),
      routineLibraryVisible: false,
      routineSettingsVisible: false,
      routineRecommendationsVisible: false,
    );
    notifyListeners();
  }

  void copyTemplateToCustom(String templateId) {
    final template = _state.templates.firstWhereOrNull(
      (template) => template.id == templateId,
    );
    if (template == null) {
      return;
    }
    _state = _state.copyWith(
      customRoutineBuilder: _builderStateFromTemplate(
        template,
      ).copyWith(name: '${template.name} Copy', clearEditingTemplateId: true),
      routineLibraryVisible: false,
      routineSettingsVisible: false,
      routineRecommendationsVisible: false,
    );
    notifyListeners();
  }

  void updateCustomRoutineName(String value) {
    final builder = _state.customRoutineBuilder;
    _state = _state.copyWith(
      customRoutineBuilder: builder.copyWith(name: value.take(60)),
    );
    notifyListeners();
  }

  void addCustomDay() {
    final builder = _state.customRoutineBuilder;
    if (!builder.visible || builder.days.length >= 7) {
      return;
    }
    final days = <CustomRoutineDayFormState>[
      ...builder.days,
      const CustomRoutineDayFormState(),
    ];
    _state = _state.copyWith(
      customRoutineBuilder: builder.copyWith(
        days: days,
        selectedDayIndex: days.length - 1,
        focusMenuVisible: false,
        expandedExerciseGroups: <MuscleGroup>{},
      ),
    );
    notifyListeners();
  }

  void selectCustomDay(int index) {
    final builder = _state.customRoutineBuilder;
    if (!builder.visible || index < 0 || index >= builder.days.length) {
      return;
    }
    _state = _state.copyWith(
      customRoutineBuilder: builder.copyWith(
        selectedDayIndex: index,
        focusMenuVisible: false,
        expandedExerciseGroups: <MuscleGroup>{},
      ),
    );
    notifyListeners();
  }

  void toggleCustomFocusMenu() {
    final builder = _state.customRoutineBuilder;
    _state = _state.copyWith(
      customRoutineBuilder: builder.copyWith(
        focusMenuVisible: !builder.focusMenuVisible,
      ),
    );
    notifyListeners();
  }

  void selectCustomFocus(RoutineFocus? focus) {
    final builder = _state.customRoutineBuilder;
    final days = builder.days.indexed.map((entry) {
      final index = entry.$1;
      final day = entry.$2;
      if (index != builder.selectedDayIndex) {
        return day;
      }
      return day.copyWith(
        focus: focus,
        clearFocus: focus == null,
        exercises: const <ExerciseId>[],
      );
    }).toList();
    _state = _state.copyWith(
      customRoutineBuilder: builder.copyWith(
        days: days,
        focusMenuVisible: false,
        expandedExerciseGroups: <MuscleGroup>{},
      ),
    );
    notifyListeners();
  }

  void toggleCustomExerciseGroup(MuscleGroup group) {
    final builder = _state.customRoutineBuilder;
    final expanded = Set<MuscleGroup>.of(builder.expandedExerciseGroups);
    if (!expanded.add(group)) {
      expanded.remove(group);
    }
    _state = _state.copyWith(
      customRoutineBuilder: builder.copyWith(expandedExerciseGroups: expanded),
    );
    notifyListeners();
  }

  void removeCustomDay(int index) {
    final builder = _state.customRoutineBuilder;
    if (!builder.visible || builder.days.length <= 1) {
      return;
    }
    if (index < 0 || index >= builder.days.length) {
      return;
    }
    final days = <CustomRoutineDayFormState>[
      for (var i = 0; i < builder.days.length; i++)
        if (i != index) builder.days[i],
    ];
    _state = _state.copyWith(
      customRoutineBuilder: builder.copyWith(
        days: days,
        selectedDayIndex: index.clamp(0, days.length - 1).toInt(),
        focusMenuVisible: false,
        expandedExerciseGroups: <MuscleGroup>{},
      ),
    );
    notifyListeners();
  }

  void addCustomExercise(ExerciseId exerciseId) {
    final builder = _state.customRoutineBuilder;
    final days = builder.days.indexed.map((entry) {
      final index = entry.$1;
      final day = entry.$2;
      if (index != builder.selectedDayIndex ||
          day.exercises.contains(exerciseId)) {
        return day;
      }
      return day.copyWith(
        exercises: <ExerciseId>[...day.exercises, exerciseId],
      );
    }).toList();
    _state = _state.copyWith(
      customRoutineBuilder: builder.copyWith(days: days),
    );
    notifyListeners();
  }

  void moveCustomExerciseUp(int index) {
    _moveCustomExercise(index, index - 1);
  }

  void moveCustomExerciseDown(int index) {
    _moveCustomExercise(index, index + 1);
  }

  void removeCustomExercise(int index) {
    final builder = _state.customRoutineBuilder;
    final selectedDay = builder.selectedDay;
    if (index < 0 || index >= selectedDay.exercises.length) {
      return;
    }
    final exercises = <ExerciseId>[...selectedDay.exercises]..removeAt(index);
    final days = builder.days.indexed.map((entry) {
      return entry.$1 == builder.selectedDayIndex
          ? entry.$2.copyWith(exercises: exercises)
          : entry.$2;
    }).toList();
    _state = _state.copyWith(
      customRoutineBuilder: builder.copyWith(days: days),
    );
    notifyListeners();
  }

  void saveCustomRoutine() {
    final builder = _state.customRoutineBuilder;
    final template = _customTemplateFromBuilder(builder);
    if (template == null) {
      return;
    }
    final customTemplates = <PlanTemplate>[
      for (final existing in _state.customTemplates)
        if (existing.id != template.id) existing,
      template,
    ];
    _state = _state.copyWith(
      customTemplates: customTemplates,
      customRoutineBuilder: const CustomRoutineBuilderState(),
      activeRoutineTemplateId: _state.activeRoutineTemplateId == template.id
          ? template.id
          : _state.activeRoutineTemplateId,
    );
    notifyListeners();
  }

  void _updateSetEntry(
    int index,
    RecordSetFormState Function(RecordSetFormState entry) update,
  ) {
    final entries = _state.recordForm.setEntries;
    if (index < 0 || index >= entries.length) {
      return;
    }
    _state = _state.copyWith(
      recordForm: _state.recordForm.copyWith(
        setEntries: <RecordSetFormState>[
          for (var i = 0; i < entries.length; i++)
            i == index ? update(entries[i]) : entries[i],
        ],
      ),
    );
    notifyListeners();
  }

  void _refreshSelectedPlannedExercise() {
    final plan = _state.plan;
    if (plan == null) {
      notifyListeners();
      return;
    }
    final recording = plan.findPlannedExercise(
      _state.recordingPlannedExercise?.id,
    );
    final selected =
        recording ?? plan.firstIncomplete(_state.completedPlannedExerciseIds);
    _state = _state.copyWith(
      selectedPlannedExercise: selected,
      recordingPlannedExercise: recording,
    );
    notifyListeners();
  }

  WorkoutDayPlan? _activeRoutineDayPlan() {
    final template = _state.activeRoutineTemplate;
    if (template == null || template.days.isEmpty) {
      return null;
    }
    final index = _state.activeRoutineDayIndex
        .clamp(0, template.days.length - 1)
        .toInt();
    final plan = _state.plan;
    if (plan?.templateId == template.id && index < (plan?.days.length ?? 0)) {
      return plan!.days[index];
    }
    final day = template.days[index];
    final date = _weekStart.add(Duration(days: day.dayOffset));
    final exercisesById = <ExerciseId, Exercise>{
      for (final exercise in _state.exercises) exercise.id: exercise,
    };
    return WorkoutDayPlan(
      date: date,
      title: day.title,
      focus: day.focus,
      dayNumber: day.dayNumber,
      primaryFocus: day.primaryFocus,
      secondaryFocuses: day.secondaryFocuses,
      minRecoveryHours: day.minRecoveryHours,
      exercises: day.exercises
          .map((item) {
            final exercise = exercisesById[item.exerciseId];
            if (exercise == null) {
              return null;
            }
            return PlannedExercise(
              id: PlannedExerciseId(
                '${template.id}_${day.dayNumber}_${item.exerciseId.value}',
              ),
              exercise: exercise,
              sets: item.sets,
              repRange: item.repRange,
              durationMinutes: item.durationMinutes,
              restSeconds: item.restSeconds,
              note: item.note,
            );
          })
          .whereType<PlannedExercise>()
          .toList(),
    );
  }

  void _moveCustomExercise(int fromIndex, int toIndex) {
    final builder = _state.customRoutineBuilder;
    final selectedDay = builder.selectedDay;
    if (fromIndex < 0 ||
        fromIndex >= selectedDay.exercises.length ||
        toIndex < 0 ||
        toIndex >= selectedDay.exercises.length) {
      return;
    }
    final exercises = <ExerciseId>[...selectedDay.exercises];
    final item = exercises.removeAt(fromIndex);
    exercises.insert(toIndex, item);
    final days = builder.days.indexed.map((entry) {
      return entry.$1 == builder.selectedDayIndex
          ? entry.$2.copyWith(exercises: exercises)
          : entry.$2;
    }).toList();
    _state = _state.copyWith(
      customRoutineBuilder: builder.copyWith(days: days),
    );
    notifyListeners();
  }

  CustomRoutineBuilderState _builderStateFromTemplate(PlanTemplate template) {
    return CustomRoutineBuilderState(
      visible: true,
      name: template.name,
      days: template.days.map((day) {
        return CustomRoutineDayFormState(
          focus: day.primaryFocus,
          exercises: day.exercises
              .map((exercise) => exercise.exerciseId)
              .toList(),
        );
      }).toList(),
      selectedDayIndex: 0,
      editingTemplateId: template.id,
    );
  }

  PlanTemplate? _customTemplateFromBuilder(CustomRoutineBuilderState builder) {
    if (!builder.visible) {
      return null;
    }
    final validDays = builder.days
        .where((day) => day.exercises.isNotEmpty)
        .toList(growable: false);
    if (builder.name.trim().isEmpty || validDays.isEmpty) {
      return null;
    }
    return PlanTemplate(
      id: builder.editingTemplateId ?? 'custom-test',
      name: builder.name.trim(),
      level: PlanLevel.intermediate,
      daysPerWeek: validDays.length,
      description: '사용자가 직접 구성한 루틴',
      days: validDays.indexed.map((entry) {
        final index = entry.$1;
        final day = entry.$2;
        final focus = day.focus;
        return PlanTemplateDay(
          dayOffset: index,
          dayNumber: index + 1,
          title: 'Day ${index + 1}',
          focus: routineFocusLabel(focus),
          primaryFocus: focus,
          secondaryFocuses: const <RoutineFocus>[],
          minRecoveryHours: 24,
          exercises: day.exercises.map((exerciseId) {
            final exercise = _state.exercises.firstWhereOrNull(
              (exercise) => exercise.id == exerciseId,
            );
            return TemplateExercise(
              exerciseId: exerciseId,
              sets: exercise?.defaultSets ?? 3,
              repRange: exercise?.defaultRepRange ?? const RepRange(8, 12),
              durationMinutes: exercise?.defaultDurationMinutes,
              restSeconds: exercise?.restSeconds ?? 60,
              note: '',
            );
          }).toList(),
        );
      }).toList(),
      structure: RoutineStructure.bodyPartSplit,
      recommendedExperience: TrainingExperience.intermediate,
      cycleLength: validDays.length,
      sessionMinutes: 0,
      focusSummary: validDays.map((day) => day.focus).nonNulls.toList(),
      source: RoutineSource.custom,
    );
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }
}

extension WeeklyPlanSelection on WeeklyPlan {
  PlannedExercise? findPlannedExercise(PlannedExerciseId? id) {
    if (id == null) {
      return null;
    }
    return days
        .expand((day) => day.exercises)
        .where((exercise) => exercise.id == id)
        .firstOrNull;
  }

  PlannedExercise? firstIncomplete(Set<PlannedExerciseId> completedIds) {
    return days
            .expand((day) => day.exercises)
            .where((exercise) => !completedIds.contains(exercise.id))
            .firstOrNull ??
        (days.isEmpty || days.first.exercises.isEmpty
            ? null
            : days.first.exercises.first);
  }
}

const maxRecordSets = 12;

extension PlannedExerciseDefaults on PlannedExercise {
  List<RecordSetFormState> defaultSetForms() {
    return List<RecordSetFormState>.generate(
      sets.clamp(1, maxRecordSets).toInt(),
      (_) => defaultSetForm(),
    );
  }

  RecordSetFormState defaultSetForm() {
    return RecordSetFormState(
      reps: repRange?.first.toString() ?? '',
      durationMinutes: durationMinutes?.toString() ?? '',
      restSeconds: restSeconds.toString(),
    );
  }
}

RecordFormError? validateSetEntries(
  PlannedExercise planned,
  List<RecordSetFormState> entries,
) {
  if (entries.isEmpty || entries.length > maxRecordSets) {
    return RecordFormError.sets;
  }
  for (final entry in entries) {
    final reps = int.tryParse(entry.reps);
    final weight = double.tryParse(entry.weightKg);
    final duration = int.tryParse(entry.durationMinutes);
    final rest = int.tryParse(entry.restSeconds);
    if (entry.reps.isNotEmpty && (reps == null || reps < 1 || reps > 50)) {
      return RecordFormError.reps;
    }
    if (entry.weightKg.isNotEmpty && (weight == null || weight < 0)) {
      return RecordFormError.weight;
    }
    if (entry.durationMinutes.isNotEmpty &&
        (duration == null || duration < 1 || duration > 240)) {
      return RecordFormError.duration;
    }
    if (entry.restSeconds.isNotEmpty &&
        (rest == null || rest < 0 || rest > 600)) {
      return RecordFormError.rest;
    }
    if (planned.repRange != null && reps == null) {
      return RecordFormError.reps;
    }
    if (planned.repRange == null && duration == null) {
      return RecordFormError.duration;
    }
  }
  return null;
}

extension RecordSetFormsMapper on List<RecordSetFormState> {
  List<WorkoutSetLog> toWorkoutSetLogs(PlannedExercise planned) {
    return indexed.map((indexed) {
      final index = indexed.$1;
      final entry = indexed.$2;
      return WorkoutSetLog(
        order: index + 1,
        reps: planned.repRange != null ? int.tryParse(entry.reps) : null,
        weightKg: planned.repRange != null
            ? double.tryParse(entry.weightKg)
            : null,
        durationMinutes:
            planned.durationMinutes != null || planned.repRange == null
            ? int.tryParse(entry.durationMinutes)
            : null,
        restSeconds: int.tryParse(entry.restSeconds),
      );
    }).toList();
  }
}

String routineFocusLabel(RoutineFocus? focus) {
  return switch (focus) {
    RoutineFocus.chest => '가슴',
    RoutineFocus.back => '등',
    RoutineFocus.lowerBody => '하체',
    RoutineFocus.shoulders => '어깨',
    RoutineFocus.arms => '팔',
    RoutineFocus.biceps => '이두',
    RoutineFocus.triceps => '삼두',
    RoutineFocus.forearms => '전완근',
    RoutineFocus.cardioConditioning => '유산소',
    RoutineFocus.core => '코어',
    RoutineFocus.upperBody => '상체',
    RoutineFocus.push => '푸시',
    RoutineFocus.pull => '풀',
    RoutineFocus.fullBody => '전신',
    null => '미지정',
  };
}

extension NumericInputFilters on String {
  String onlyNumber() {
    return split(
      '',
    ).where((character) => int.tryParse(character) != null).join().take(3);
  }

  String onlyDecimal() {
    var dotSeen = false;
    final filtered = StringBuffer();
    for (final character in split('')) {
      if (int.tryParse(character) != null) {
        filtered.write(character);
      } else if (character == '.' && !dotSeen) {
        dotSeen = true;
        filtered.write(character);
      }
      if (filtered.length >= 6) {
        break;
      }
    }
    return filtered.toString();
  }
}

extension IterableFirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;

  T? firstWhereOrNull(bool Function(T value) test) {
    for (final value in this) {
      if (test(value)) {
        return value;
      }
    }
    return null;
  }
}

extension _StringTake on String {
  String take(int count) {
    if (length <= count) {
      return this;
    }
    return substring(0, count);
  }
}

DateTime _mondayOf(DateTime date) {
  final normalized = normalizeDate(date);
  return normalized.subtract(
    Duration(days: normalized.weekday - DateTime.monday),
  );
}
