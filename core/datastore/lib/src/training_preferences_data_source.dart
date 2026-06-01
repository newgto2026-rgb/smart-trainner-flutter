import 'dart:async';

import 'package:smart_trainner_core_model/smart_trainner_core_model.dart';

const defaultUserSessionId = 'local-default';

class TrainingPreferencesDataSource {
  TrainingPreferencesDataSource({DateTime Function()? now})
    : _now = now ?? (() => DateTime.now().toUtc());

  final DateTime Function() _now;
  final _activeSessionController = StreamController<UserSession?>.broadcast();
  final _selectedTemplateControllers = <String, StreamController<String>>{};
  final _routineProgressControllers =
      <String, StreamController<RoutineProgressPreference>>{};
  final _selectedTemplateIds = <String, String>{};
  final _activeRoutineTemplateIds = <String, String>{};
  final _activeRoutineDayIndexes = <String, int>{};
  final _activeRoutineStartedAt = <String, String>{};
  final _activeRoutineCycleStartedAt = <String, String>{};
  final _lastCompletedRoutineDayIndexes = <String, int>{};
  final _lastCompletedAt = <String, String>{};
  UserSession? _activeSession;

  Stream<String?> get activeSessionId {
    return observeActiveSession().map((session) => session?.id.value);
  }

  Stream<UserSession?> observeActiveSession() async* {
    yield _activeSession;
    yield* _activeSessionController.stream;
  }

  Stream<String> selectedTemplateId(String sessionId) async* {
    yield _selectedTemplateIds[sessionId] ?? _defaultTemplateId;
    yield* _selectedTemplateControllers
        .putIfAbsent(sessionId, () => StreamController<String>.broadcast())
        .stream;
  }

  String selectedTemplateIdValue(String sessionId) {
    return _selectedTemplateIds[sessionId] ?? _defaultTemplateId;
  }

  Stream<RoutineProgressPreference> activeRoutineProgress(
    String sessionId,
  ) async* {
    yield _routineProgressValue(sessionId);
    yield* _routineProgressControllers
        .putIfAbsent(
          sessionId,
          () => StreamController<RoutineProgressPreference>.broadcast(),
        )
        .stream;
  }

  String? get activeSessionIdValue => _activeSession?.id.value;

  Future<void> setSelectedTemplateId(
    String sessionId,
    String templateId,
  ) async {
    _selectedTemplateIds[sessionId] = templateId;
    _selectedTemplateControllers[sessionId]?.add(templateId);
  }

  Future<void> setActiveRoutineTemplate(
    String sessionId,
    String templateId,
  ) async {
    final now = _instantString(_now());
    _activeRoutineTemplateIds[sessionId] = templateId;
    _activeRoutineDayIndexes[sessionId] = 0;
    _activeRoutineStartedAt[sessionId] = now;
    _activeRoutineCycleStartedAt[sessionId] = now;
    _lastCompletedRoutineDayIndexes.remove(sessionId);
    _lastCompletedAt.remove(sessionId);
    _emitRoutineProgress(sessionId);
  }

  Future<void> setActiveRoutineDayIndex(String sessionId, int dayIndex) async {
    _activeRoutineDayIndexes[sessionId] = dayIndex;
    _emitRoutineProgress(sessionId);
  }

  Future<void> markRoutineDayCompleted({
    required String sessionId,
    required int completedDayIndex,
    required int nextDayIndex,
    required String completedAt,
    required String? newCycleStartedAt,
  }) async {
    _lastCompletedRoutineDayIndexes[sessionId] = completedDayIndex;
    _lastCompletedAt[sessionId] = completedAt;
    _activeRoutineDayIndexes[sessionId] = nextDayIndex;
    if (newCycleStartedAt != null) {
      _activeRoutineCycleStartedAt[sessionId] = newCycleStartedAt;
    }
    _emitRoutineProgress(sessionId);
  }

  Future<UserSession> startDefaultSession() async {
    _activeSession = const UserSession(
      id: UserSessionId(defaultUserSessionId),
      displayName: _defaultDisplayName,
      email: null,
      provider: AuthProvider.local,
      linkedAt: null,
    );
    _activeSessionController.add(_activeSession);
    return _activeSession!;
  }

  Future<void> clearActiveSession() async {
    _activeSession = null;
    _activeSessionController.add(null);
  }

  void dispose() {
    _activeSessionController.close();
    for (final controller in _selectedTemplateControllers.values) {
      controller.close();
    }
    for (final controller in _routineProgressControllers.values) {
      controller.close();
    }
  }

  RoutineProgressPreference _routineProgressValue(String sessionId) {
    return RoutineProgressPreference(
      templateId:
          _activeRoutineTemplateIds[sessionId] ??
          _selectedTemplateIds[sessionId] ??
          _defaultTemplateId,
      dayIndex: _activeRoutineDayIndexes[sessionId] ?? 0,
      startedAt: _activeRoutineStartedAt[sessionId],
      cycleStartedAt: _activeRoutineCycleStartedAt[sessionId],
      lastCompletedDayIndex: _lastCompletedRoutineDayIndexes[sessionId],
      lastCompletedAt: _lastCompletedAt[sessionId],
    );
  }

  void _emitRoutineProgress(String sessionId) {
    _routineProgressControllers[sessionId]?.add(
      _routineProgressValue(sessionId),
    );
  }

  static const _defaultTemplateId = 'beginner-full-body-3day';
  static const _defaultDisplayName = 'Local Athlete';
}

String _instantString(DateTime value) {
  final utc = value.toUtc();
  final iso = utc.toIso8601String();
  return iso.endsWith('.000Z') ? '${iso.substring(0, iso.length - 5)}Z' : iso;
}
