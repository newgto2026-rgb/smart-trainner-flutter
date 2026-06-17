import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:smart_trainner_core_domain/smart_trainner_core_domain.dart';
import 'package:smart_trainner_core_model/smart_trainner_core_model.dart';
import 'package:smart_trainner_feature_training_impl/src/training_ui_models.dart';

class TrainingController extends ChangeNotifier {
  TrainingController({
    required ObserveExercisesUseCase observeExercises,
    required ObservePlanTemplatesUseCase observePlanTemplates,
    required ObserveCurrentWeeklyPlanUseCase observeCurrentWeeklyPlan,
    required ObserveWorkoutLogsUseCase observeWorkoutLogs,
    required ObserveWeeklySummaryUseCase observeWeeklySummary,
    required CreateCustomExerciseUseCase createCustomExercise,
    required SelectPlanTemplateUseCase selectPlanTemplate,
    required SaveWorkoutLogUseCase saveWorkoutLog,
    DateTime? today,
  }) : _createCustomExercise = createCustomExercise,
       _selectPlanTemplate = selectPlanTemplate,
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

  final CreateCustomExerciseUseCase _createCustomExercise;
  final SelectPlanTemplateUseCase _selectPlanTemplate;
  final SaveWorkoutLogUseCase _saveWorkoutLog;
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
    await _selectPlanTemplate(templateId);
  }

  void selectExercise(ExerciseId exerciseId) {
    final exercise = _state.exercises.firstWhere(
      (exercise) => exercise.id == exerciseId,
    );
    _state = _state.copyWith(
      selectedExercise: exercise,
      selectedTab: TrainingTab.exercises,
      clearLastCreatedCustomExerciseId: true,
    );
    notifyListeners();
  }

  void dismissExerciseDetail() {
    _state = _state.copyWith(
      clearSelectedExercise: true,
      clearLastCreatedCustomExerciseId: true,
    );
    notifyListeners();
  }

  void showCustomExerciseForm() {
    _state = _state.copyWith(
      isCustomExerciseFormVisible: true,
      customExerciseForm: const CustomExerciseFormState(),
      clearCustomExerciseFormError: true,
      clearLastCreatedCustomExerciseId: true,
    );
    notifyListeners();
  }

  void dismissCustomExerciseForm() {
    _state = _state.copyWith(
      isCustomExerciseFormVisible: false,
      customExerciseForm: const CustomExerciseFormState(),
      clearCustomExerciseFormError: true,
    );
    notifyListeners();
  }

  void updateCustomExerciseName(String value) {
    _updateCustomExerciseForm((form) => form.copyWith(name: value.take(60)));
  }

  void updateCustomExerciseMuscleGroup(MuscleGroup value) {
    _updateCustomExerciseForm((form) => form.copyWith(muscleGroup: value));
  }

  void updateCustomExerciseEquipment(EquipmentType value) {
    _updateCustomExerciseForm((form) => form.copyWith(equipment: value));
  }

  void updateCustomExerciseDifficulty(DifficultyLevel value) {
    _updateCustomExerciseForm((form) => form.copyWith(difficulty: value));
  }

  void updateCustomExerciseTargetType(CustomExerciseTargetType value) {
    _updateCustomExerciseForm((form) => form.copyWith(targetType: value));
  }

  void updateCustomExerciseSummary(String value) {
    _updateCustomExerciseForm(
      (form) => form.copyWith(summary: value.take(160)),
    );
  }

  void updateCustomExerciseInstructions(String value) {
    _updateCustomExerciseForm(
      (form) => form.copyWith(instructions: value.take(360)),
    );
  }

  void updateCustomExerciseSafetyCues(String value) {
    _updateCustomExerciseForm(
      (form) => form.copyWith(safetyCues: value.take(240)),
    );
  }

  void updateCustomExerciseDefaultSets(String value) {
    _updateCustomExerciseForm(
      (form) => form.copyWith(defaultSets: value.onlyNumber()),
    );
  }

  void updateCustomExerciseRepRangeFirst(String value) {
    _updateCustomExerciseForm(
      (form) => form.copyWith(repRangeFirst: value.onlyNumber()),
    );
  }

  void updateCustomExerciseRepRangeLast(String value) {
    _updateCustomExerciseForm(
      (form) => form.copyWith(repRangeLast: value.onlyNumber()),
    );
  }

  void updateCustomExerciseDurationMinutes(String value) {
    _updateCustomExerciseForm(
      (form) => form.copyWith(durationMinutes: value.onlyNumber()),
    );
  }

  void updateCustomExerciseRestSeconds(String value) {
    _updateCustomExerciseForm(
      (form) => form.copyWith(restSeconds: value.onlyNumber()),
    );
  }

  void updateCustomExerciseImagePath(String value) {
    _updateCustomExerciseForm((form) => form.copyWith(imagePath: value));
  }

  Future<void> saveCustomExercise() async {
    final form = _state.customExerciseForm;
    final inputResult = form.toInput();
    final error = inputResult.error;
    if (error != null) {
      _state = _state.copyWith(customExerciseFormError: error);
      notifyListeners();
      return;
    }
    final result = await _createCustomExercise(inputResult.input!);
    final exercise = result.value;
    if (!result.isSuccess || exercise == null) {
      _state = _state.copyWith(
        customExerciseFormError: CustomExerciseFormError.saveFailed,
      );
      notifyListeners();
      return;
    }
    _state = _state.copyWith(
      isCustomExerciseFormVisible: false,
      customExerciseForm: const CustomExerciseFormState(),
      clearCustomExerciseFormError: true,
      selectedExercise: exercise,
      selectedTab: TrainingTab.exercises,
      lastCreatedCustomExerciseId: exercise.id,
    );
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
      recordSaved: result.isSuccess,
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

  void _updateCustomExerciseForm(
    CustomExerciseFormState Function(CustomExerciseFormState form) update,
  ) {
    _state = _state.copyWith(
      customExerciseForm: update(_state.customExerciseForm),
      clearCustomExerciseFormError: true,
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
      );
    }).toList();
  }
}

extension _CustomExerciseFormMapper on CustomExerciseFormState {
  _CustomExerciseInputResult toInput() {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return const _CustomExerciseInputResult.error(
        CustomExerciseFormError.name,
      );
    }
    final muscleGroup = this.muscleGroup;
    if (muscleGroup == null) {
      return const _CustomExerciseInputResult.error(
        CustomExerciseFormError.muscleGroup,
      );
    }
    final equipment = this.equipment;
    if (equipment == null) {
      return const _CustomExerciseInputResult.error(
        CustomExerciseFormError.equipment,
      );
    }
    final difficulty = this.difficulty;
    if (difficulty == null) {
      return const _CustomExerciseInputResult.error(
        CustomExerciseFormError.difficulty,
      );
    }
    final trimmedSummary = summary.trim();
    if (trimmedSummary.isEmpty) {
      return const _CustomExerciseInputResult.error(
        CustomExerciseFormError.summary,
      );
    }
    final instructions = _cleanLines(this.instructions);
    if (instructions.isEmpty) {
      return const _CustomExerciseInputResult.error(
        CustomExerciseFormError.instructions,
      );
    }
    final safetyCues = _cleanLines(this.safetyCues);
    if (safetyCues.isEmpty) {
      return const _CustomExerciseInputResult.error(
        CustomExerciseFormError.safetyCues,
      );
    }
    final sets = int.tryParse(defaultSets);
    if (sets == null || sets < 1 || sets > maxRecordSets) {
      return const _CustomExerciseInputResult.error(
        CustomExerciseFormError.sets,
      );
    }
    final rest = int.tryParse(restSeconds);
    if (rest == null || rest < 15 || rest > 600) {
      return const _CustomExerciseInputResult.error(
        CustomExerciseFormError.rest,
      );
    }
    RepRange? repRange;
    int? duration;
    if (targetType == CustomExerciseTargetType.reps) {
      final first = int.tryParse(repRangeFirst);
      final last = int.tryParse(repRangeLast);
      if (first == null ||
          last == null ||
          first < 1 ||
          last > 50 ||
          first > last) {
        return const _CustomExerciseInputResult.error(
          CustomExerciseFormError.reps,
        );
      }
      repRange = RepRange(first, last);
    } else {
      duration = int.tryParse(durationMinutes);
      if (duration == null || duration < 1 || duration > 240) {
        return const _CustomExerciseInputResult.error(
          CustomExerciseFormError.duration,
        );
      }
    }
    final trimmedImagePath = imagePath.trim();
    return _CustomExerciseInputResult.input(
      CustomExerciseInput(
        name: trimmedName,
        muscleGroup: muscleGroup,
        equipment: equipment,
        difficulty: difficulty,
        summary: trimmedSummary,
        instructions: instructions,
        safetyCues: safetyCues,
        defaultSets: sets,
        defaultRepRange: repRange,
        defaultDurationMinutes: duration,
        restSeconds: rest,
        imagePath: trimmedImagePath.isEmpty ? null : trimmedImagePath,
      ),
    );
  }
}

class _CustomExerciseInputResult {
  const _CustomExerciseInputResult.input(this.input) : error = null;

  const _CustomExerciseInputResult.error(this.error) : input = null;

  final CustomExerciseInput? input;
  final CustomExerciseFormError? error;
}

List<String> _cleanLines(String value) {
  return value
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();
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

extension _IterableFirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
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
