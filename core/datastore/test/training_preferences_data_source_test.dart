import 'package:test/test.dart';
import 'package:smart_trainner_core_datastore/smart_trainner_core_datastore.dart';

void main() {
  final initialInstant = DateTime.utc(2026, 5, 24, 9);

  late TrainingPreferencesDataSource dataSource;

  setUp(() {
    dataSource = TrainingPreferencesDataSource(now: () => initialInstant);
  });

  tearDown(() {
    dataSource.dispose();
  });

  test(
    'setActiveRoutineTemplate writes routine and cycle start from clock',
    () async {
      await dataSource.setActiveRoutineTemplate('session', 'template');

      final progress = await dataSource.activeRoutineProgress('session').first;

      expect(progress.templateId, 'template');
      expect(progress.dayIndex, 0);
      expect(progress.startedAt, '2026-05-24T09:00:00Z');
      expect(progress.cycleStartedAt, '2026-05-24T09:00:00Z');
    },
  );

  test(
    'markRoutineDayCompleted with new cycle start updates cycle boundary',
    () async {
      await dataSource.setActiveRoutineTemplate('session', 'template');

      await dataSource.markRoutineDayCompleted(
        sessionId: 'session',
        completedDayIndex: 3,
        nextDayIndex: 0,
        completedAt: '2026-05-25T12:00:00Z',
        newCycleStartedAt: '2026-05-25T12:00:00Z',
      );

      final progress = await dataSource.activeRoutineProgress('session').first;

      expect(progress.dayIndex, 0);
      expect(progress.lastCompletedDayIndex, 3);
      expect(progress.lastCompletedAt, '2026-05-25T12:00:00Z');
      expect(progress.startedAt, '2026-05-24T09:00:00Z');
      expect(progress.cycleStartedAt, '2026-05-25T12:00:00Z');
    },
  );

  test(
    'markRoutineDayCompleted without new cycle start keeps cycle boundary',
    () async {
      await dataSource.setActiveRoutineTemplate('session', 'template');

      await dataSource.markRoutineDayCompleted(
        sessionId: 'session',
        completedDayIndex: 1,
        nextDayIndex: 2,
        completedAt: '2026-05-25T12:00:00Z',
        newCycleStartedAt: null,
      );

      final progress = await dataSource.activeRoutineProgress('session').first;

      expect(progress.dayIndex, 2);
      expect(progress.lastCompletedDayIndex, 1);
      expect(progress.startedAt, '2026-05-24T09:00:00Z');
      expect(progress.cycleStartedAt, '2026-05-24T09:00:00Z');
    },
  );
}
