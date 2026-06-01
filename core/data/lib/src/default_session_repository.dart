import 'package:smart_trainner_core_datastore/smart_trainner_core_datastore.dart';
import 'package:smart_trainner_core_domain/smart_trainner_core_domain.dart';
import 'package:smart_trainner_core_model/smart_trainner_core_model.dart';

class DefaultSessionRepository implements SessionRepository {
  const DefaultSessionRepository(this.preferences);

  final TrainingPreferencesDataSource preferences;

  @override
  Stream<UserSession?> observeActiveSession() {
    return preferences.observeActiveSession();
  }

  @override
  Future<OperationResult<UserSession>> startDefaultSession() async {
    try {
      return OperationResult.success(await preferences.startDefaultSession());
    } catch (error) {
      return OperationResult.failure(error);
    }
  }

  @override
  Future<OperationResult<void>> signOut() async {
    try {
      await preferences.clearActiveSession();
      return OperationResult.success();
    } catch (error) {
      return OperationResult.failure(error);
    }
  }
}
