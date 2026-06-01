import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:smart_trainner_core_domain/smart_trainner_core_domain.dart'
    show ObserveLatestWorkoutLogsUseCase, ObserveWorkoutLogsUseCase;
import 'package:smart_trainner_core_model/smart_trainner_core_model.dart';
import 'package:smart_trainner_feature_workout_domain/smart_trainner_feature_workout_domain.dart'
    show GetLatestWorkoutLogUseCase, SaveWorkoutLogUseCase;

const maxRecordSets = 12;

enum RecordFormError {
  selectExercise,
  sets,
  reps,
  weight,
  duration,
  rest,
  saveFailed,
  completeDayFailed,
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

  @override
  bool operator ==(Object other) {
    return other is RecordFormState &&
        listEquals(other.setEntries, setEntries) &&
        other.memo == memo;
  }

  @override
  int get hashCode => Object.hash(Object.hashAll(setEntries), memo);
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

  @override
  bool operator ==(Object other) {
    return other is RecordSetFormState &&
        other.reps == reps &&
        other.weightKg == weightKg &&
        other.durationMinutes == durationMinutes &&
        other.restSeconds == restSeconds;
  }

  @override
  int get hashCode => Object.hash(reps, weightKg, durationMinutes, restSeconds);
}

class WorkoutRecordingUiState {
  const WorkoutRecordingUiState({
    this.recordingPlannedExercise,
    this.weeklyLogs = const <WorkoutLog>[],
    this.latestWorkoutLogs = const <WorkoutLog>[],
    this.recordForm = const RecordFormState(),
    this.formError,
    this.recordSaved = false,
  });

  final PlannedExercise? recordingPlannedExercise;
  final List<WorkoutLog> weeklyLogs;
  final List<WorkoutLog> latestWorkoutLogs;
  final RecordFormState recordForm;
  final RecordFormError? formError;
  final bool recordSaved;

  WorkoutRecordingUiState copyWith({
    PlannedExercise? recordingPlannedExercise,
    bool clearRecordingPlannedExercise = false,
    List<WorkoutLog>? weeklyLogs,
    List<WorkoutLog>? latestWorkoutLogs,
    RecordFormState? recordForm,
    RecordFormError? formError,
    bool clearFormError = false,
    bool? recordSaved,
  }) {
    return WorkoutRecordingUiState(
      recordingPlannedExercise: clearRecordingPlannedExercise
          ? null
          : recordingPlannedExercise ?? this.recordingPlannedExercise,
      weeklyLogs: weeklyLogs ?? this.weeklyLogs,
      latestWorkoutLogs: latestWorkoutLogs ?? this.latestWorkoutLogs,
      recordForm: recordForm ?? this.recordForm,
      formError: clearFormError ? null : formError ?? this.formError,
      recordSaved: recordSaved ?? this.recordSaved,
    );
  }
}

class WorkoutRecordingViewModel extends ChangeNotifier {
  WorkoutRecordingViewModel({
    required ObserveWorkoutLogsUseCase observeWorkoutLogs,
    required ObserveLatestWorkoutLogsUseCase observeLatestWorkoutLogs,
    required GetLatestWorkoutLogUseCase getLatestWorkoutLog,
    required SaveWorkoutLogUseCase saveWorkoutLog,
    required DateTime Function() now,
  }) : _getLatestWorkoutLog = getLatestWorkoutLog,
       _saveWorkoutLog = saveWorkoutLog,
       _now = now {
    final weekStart = _mondayOf(now());
    _subscriptions
      ..add(
        observeWorkoutLogs(weekStart).listen((logs) {
          _state = _state.copyWith(weeklyLogs: logs);
          notifyListeners();
        }),
      )
      ..add(
        observeLatestWorkoutLogs().listen((logs) {
          _state = _state.copyWith(latestWorkoutLogs: logs);
          notifyListeners();
        }),
      );
  }

  final GetLatestWorkoutLogUseCase _getLatestWorkoutLog;
  final SaveWorkoutLogUseCase _saveWorkoutLog;
  final DateTime Function() _now;
  final List<StreamSubscription<dynamic>> _subscriptions =
      <StreamSubscription<dynamic>>[];
  var _recordPrefillToken = 0;
  WorkoutRecordingUiState _state = const WorkoutRecordingUiState();

  WorkoutRecordingUiState get state => _state;

  Future<void> updatePlannedExercise(PlannedExercise? plannedExercise) async {
    final current = _state.recordingPlannedExercise;
    if (plannedExercise == null) {
      if (current != null) {
        clearRecording();
      }
      return;
    }
    if (current?.id == plannedExercise.id) {
      return;
    }
    _state = _state.copyWith(
      recordingPlannedExercise: plannedExercise,
      clearFormError: true,
      recordSaved: false,
    );
    notifyListeners();
    await _prefillRecordForm(plannedExercise);
  }

  void updateSetReps({required int index, required String value}) {
    _updateSetEntry(index, (entry) => entry.copyWith(reps: value.onlyNumber()));
  }

  void updateSetWeight({required int index, required String value}) {
    _updateSetEntry(
      index,
      (entry) => entry.copyWith(weightKg: value.onlyDecimal()),
    );
  }

  void updateSetDuration({required int index, required String value}) {
    _updateSetEntry(
      index,
      (entry) => entry.copyWith(durationMinutes: value.onlyNumber()),
    );
  }

  void updateSetRest({required int index, required String value}) {
    _updateSetEntry(
      index,
      (entry) => entry.copyWith(restSeconds: value.onlyNumber()),
    );
  }

  void addSetEntry() {
    final planned = _state.recordingPlannedExercise;
    if (planned == null ||
        _state.recordForm.setEntries.length >= maxRecordSets) {
      return;
    }
    final entries = _state.recordForm.setEntries;
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

  Future<void> saveRecord(
    void Function(PlannedExercise planned) onSaved,
  ) async {
    final planned = _state.recordingPlannedExercise;
    if (planned == null) {
      _state = _state.copyWith(formError: RecordFormError.selectExercise);
      notifyListeners();
      return;
    }
    final form = _state.recordForm;
    final validationError = validateSetEntries(planned, form.setEntries);
    if (validationError != null) {
      _state = _state.copyWith(formError: validationError);
      notifyListeners();
      return;
    }
    final setEntries = form.setEntries.toWorkoutSetLogs(planned);
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
        performedAt: _now(),
        sets: setEntries.length,
        reps: firstReps,
        weightKg: firstWeight,
        durationMinutes: totalDuration > 0 ? totalDuration : null,
        memo: form.memo,
        completed: true,
        setEntries: setEntries,
      ),
    );
    if (result.isSuccess) {
      _state = _state.copyWith(clearFormError: true, recordSaved: false);
      onSaved(planned);
    } else {
      _state = _state.copyWith(
        formError: RecordFormError.saveFailed,
        recordSaved: false,
      );
    }
    notifyListeners();
  }

  void clearRecording() {
    _recordPrefillToken += 1;
    _state = _state.copyWith(
      clearRecordingPlannedExercise: true,
      recordForm: const RecordFormState(),
      clearFormError: true,
      recordSaved: false,
    );
    notifyListeners();
  }

  Future<void> _prefillRecordForm(PlannedExercise planned) async {
    final previousLog =
        _state.latestWorkoutLogs.latestRecordForExercise(planned.exercise.id) ??
        _state.weeklyLogs.latestRecordForExercise(planned.exercise.id);
    final initialForm = RecordFormState(
      setEntries: planned.defaultSetForms(previousLog),
    );
    final token = _recordPrefillToken + 1;
    _recordPrefillToken = token;
    _state = _state.copyWith(recordForm: initialForm);
    notifyListeners();

    final latestLog = await _getLatestWorkoutLog(planned.exercise.id);
    if (latestLog == null) {
      return;
    }
    final latestForm = RecordFormState(
      setEntries: planned.defaultSetForms(latestLog),
    );
    if (_recordPrefillToken == token &&
        _state.recordingPlannedExercise?.id == planned.id &&
        _state.recordForm == initialForm) {
      _state = _state.copyWith(recordForm: latestForm);
      notifyListeners();
    }
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

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }
}

extension PlannedExerciseRecordDefaults on PlannedExercise {
  List<RecordSetFormState> defaultSetForms([WorkoutLog? previousLog]) {
    final previousSets = previousLog?.reusableSetEntries() ?? <WorkoutSetLog>[];
    final setCount = previousSets.isNotEmpty ? previousSets.length : sets;
    return List<RecordSetFormState>.generate(
      setCount.clamp(1, maxRecordSets).toInt(),
      (index) => defaultSetForm(
        index < previousSets.length ? previousSets[index] : null,
      ),
    );
  }

  RecordSetFormState defaultSetForm([WorkoutSetLog? previousSet]) {
    final plannedRepRange = repRange;
    final plannedDurationMinutes = durationMinutes;
    return RecordSetFormState(
      reps: plannedRepRange != null
          ? (previousSet?.reps ?? plannedRepRange.first).toString()
          : '',
      weightKg: plannedRepRange != null
          ? previousSet?.weightKg?.toSetRecordInput() ?? ''
          : '',
      durationMinutes: plannedDurationMinutes != null || plannedRepRange == null
          ? (previousSet?.durationMinutes ?? plannedDurationMinutes)
                    ?.toString() ??
                ''
          : '',
      restSeconds: (previousSet?.restSeconds ?? restSeconds).toString(),
    );
  }
}

extension WorkoutLogListLatest on List<WorkoutLog> {
  WorkoutLog? latestRecordForExercise(ExerciseId exerciseId) {
    final records = where((log) => log.exerciseId == exerciseId).toList()
      ..sort((a, b) => b.performedAt.compareTo(a.performedAt));
    return records.isEmpty ? null : records.first;
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
    return indexed.map((entry) {
      final index = entry.$1;
      final form = entry.$2;
      return WorkoutSetLog(
        order: index + 1,
        reps: planned.repRange != null ? int.tryParse(form.reps) : null,
        weightKg: planned.repRange != null
            ? double.tryParse(form.weightKg)
            : null,
        durationMinutes:
            planned.durationMinutes != null || planned.repRange == null
            ? int.tryParse(form.durationMinutes)
            : null,
        restSeconds: int.tryParse(form.restSeconds),
      );
    }).toList();
  }
}

extension on WorkoutLog {
  List<WorkoutSetLog> reusableSetEntries() {
    if (setEntries.isNotEmpty) {
      return setEntries;
    }
    return List<WorkoutSetLog>.generate(
      sets.clamp(1, maxRecordSets).toInt(),
      (index) => WorkoutSetLog(
        order: index + 1,
        reps: reps,
        weightKg: weightKg,
        durationMinutes: durationMinutes,
        restSeconds: null,
      ),
    );
  }
}

extension on double {
  String toSetRecordInput() {
    return remainder(1) == 0 ? toInt().toString() : toString();
  }
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

  String take(int count) {
    if (length <= count) {
      return this;
    }
    return substring(0, count);
  }
}

extension _IterableFirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

DateTime _mondayOf(DateTime date) {
  final normalized = normalizeDate(date);
  return normalized.subtract(
    Duration(days: normalized.weekday - DateTime.monday),
  );
}
