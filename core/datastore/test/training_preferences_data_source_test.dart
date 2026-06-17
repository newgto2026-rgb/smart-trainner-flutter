import 'package:smart_trainner_core_datastore/smart_trainner_core_datastore.dart';
import 'package:smart_trainner_core_model/smart_trainner_core_model.dart';
import 'package:test/test.dart';

void main() {
  late TrainingPreferencesDataSource dataSource;

  setUp(() {
    dataSource = TrainingPreferencesDataSource();
  });

  tearDown(() {
    dataSource.dispose();
  });

  test('startSession updates the active owner id stream', () async {
    final emissions = <String?>[];
    final subscription = dataSource.activeSessionId.listen(emissions.add);
    await Future<void>.delayed(Duration.zero);

    await dataSource.startSession(_session('user-a'));
    await dataSource.startSession(_session('user-b'));
    await Future<void>.delayed(Duration.zero);
    await subscription.cancel();

    expect(emissions, <String?>[null, 'user-a', 'user-b']);
    expect(dataSource.activeSessionIdValue, 'user-b');
  });
}

UserSession _session(String id) {
  return UserSession(
    id: UserSessionId(id),
    displayName: id,
    email: null,
    provider: AuthProvider.local,
    linkedAt: null,
  );
}
