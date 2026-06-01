import 'package:smart_trainner_core_datastore/src/training_preferences_data_source.dart';

class ActiveSessionResolver {
  const ActiveSessionResolver(this.preferences);

  final TrainingPreferencesDataSource preferences;

  Stream<String> observeSessionId() {
    return preferences.activeSessionId.map((id) => id ?? defaultUserSessionId);
  }

  Future<String> sessionId() async {
    return await preferences.activeSessionId.first ?? defaultUserSessionId;
  }

  String sessionIdValue() {
    return preferences.activeSessionIdValue ?? defaultUserSessionId;
  }
}
