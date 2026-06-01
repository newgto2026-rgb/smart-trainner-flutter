import 'package:rxdart/rxdart.dart';
import 'package:smart_trainner_core_data/smart_trainner_core_data.dart';
import 'package:smart_trainner_core_database/smart_trainner_core_database.dart';
import 'package:smart_trainner_core_datastore/smart_trainner_core_datastore.dart';
import 'package:smart_trainner_core_domain/smart_trainner_core_domain.dart';
import 'package:smart_trainner_core_model/smart_trainner_core_model.dart';
import 'package:smart_trainner_feature_routine_domain/smart_trainner_feature_routine_domain.dart';

class DefaultRoutineProgressRepository
    implements RoutineProgressRepository, RoutineProgressCommandRepository {
  const DefaultRoutineProgressRepository({
    required this.customRoutineDao,
    required this.preferences,
    required this.activeSessionResolver,
    required this.seedStore,
  });

  final CustomRoutineDao customRoutineDao;
  final TrainingPreferencesDataSource preferences;
  final ActiveSessionResolver activeSessionResolver;
  final TrainingSeedStore seedStore;

  @override
  Stream<RoutineProgress> observeRoutineProgress() {
    return activeSessionResolver.observeSessionId().switchMap((sessionId) {
      return Rx.combineLatest2(
        preferences.activeRoutineProgress(sessionId),
        customRoutineDao.observeForSession(sessionId),
        (
          RoutineProgressPreference preference,
          List<CustomRoutineWithDays> customRoutines,
        ) {
          final template = seedStore.templateById(
            preference.templateId,
            customTemplates: customRoutines
                .map((routine) => routine.toPlanTemplate())
                .toList(),
          );
          final startedAt = _parseInstant(preference.startedAt);
          return RoutineProgress(
            templateId: template.id,
            dayIndex: preference.dayIndex
                .clamp(0, (template.cycleLength - 1).clamp(0, 1 << 31))
                .toInt(),
            lastCompletedDayIndex: preference.lastCompletedDayIndex,
            lastCompletedAt: _parseInstant(preference.lastCompletedAt),
            startedAt: startedAt,
            cycleStartedAt:
                _parseInstant(preference.cycleStartedAt) ?? startedAt,
          );
        },
      );
    });
  }

  @override
  Future<OperationResult<void>> startRoutine(String templateId) async {
    try {
      final sessionId = await activeSessionResolver.sessionId();
      if (!await _templateExists(sessionId, templateId)) {
        throw ArgumentError('Unknown plan template: $templateId');
      }
      await preferences.setSelectedTemplateId(sessionId, templateId);
      await preferences.setActiveRoutineTemplate(sessionId, templateId);
      return OperationResult.success();
    } catch (error) {
      return OperationResult.failure(error);
    }
  }

  @override
  Future<OperationResult<void>> markRoutineDayCompleted({
    required int completedDayIndex,
    required int nextDayIndex,
    required DateTime completedAt,
    required DateTime? newCycleStartedAt,
  }) async {
    try {
      await preferences.markRoutineDayCompleted(
        sessionId: await activeSessionResolver.sessionId(),
        completedDayIndex: completedDayIndex,
        nextDayIndex: nextDayIndex,
        completedAt: _instantString(completedAt),
        newCycleStartedAt: newCycleStartedAt == null
            ? null
            : _instantString(newCycleStartedAt),
      );
      return OperationResult.success();
    } catch (error) {
      return OperationResult.failure(error);
    }
  }

  Future<bool> _templateExists(String sessionId, String templateId) async {
    return seedStore.hasTemplate(templateId) ||
        await customRoutineDao.getById(
              sessionId: sessionId,
              routineId: templateId,
            ) !=
            null;
  }
}

DateTime? _parseInstant(String? value) {
  if (value == null) {
    return null;
  }
  return DateTime.tryParse(value);
}

String _instantString(DateTime value) {
  final iso = value.toUtc().toIso8601String();
  return iso.endsWith('.000Z') ? '${iso.substring(0, iso.length - 5)}Z' : iso;
}
