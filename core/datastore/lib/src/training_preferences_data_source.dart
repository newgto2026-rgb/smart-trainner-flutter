import 'dart:async';

import 'package:smart_trainner_core_model/smart_trainner_core_model.dart';

const defaultUserSessionId = 'local-default';

class TrainingPreferencesDataSource {
  final _activeSessionController = StreamController<UserSession?>.broadcast();
  final _selectedTemplateControllers = <String, StreamController<String>>{};
  final _selectedTemplateIds = <String, String>{};
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

  String? get activeSessionIdValue => _activeSession?.id.value;

  Future<void> setSelectedTemplateId(
    String sessionId,
    String templateId,
  ) async {
    _selectedTemplateIds[sessionId] = templateId;
    _selectedTemplateControllers[sessionId]?.add(templateId);
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
  }

  static const _defaultTemplateId = 'beginner-3day';
  static const _defaultDisplayName = 'Local Athlete';
}
