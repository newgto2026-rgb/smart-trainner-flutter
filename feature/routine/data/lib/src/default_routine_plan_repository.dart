import 'package:rxdart/rxdart.dart';
import 'package:smart_trainner_core_data/smart_trainner_core_data.dart';
import 'package:smart_trainner_core_database/smart_trainner_core_database.dart';
import 'package:smart_trainner_core_datastore/smart_trainner_core_datastore.dart';
import 'package:smart_trainner_core_domain/smart_trainner_core_domain.dart';
import 'package:smart_trainner_core_model/smart_trainner_core_model.dart';
import 'package:smart_trainner_feature_routine_data/src/custom_routine_mappers.dart';
import 'package:smart_trainner_feature_routine_domain/smart_trainner_feature_routine_domain.dart';

class DefaultRoutinePlanRepository
    implements RoutinePlanCatalogRepository, RoutinePlanCommandRepository {
  const DefaultRoutinePlanRepository({
    required this.customRoutineDao,
    required this.preferences,
    required this.activeSessionResolver,
    required this.seedStore,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final CustomRoutineDao customRoutineDao;
  final TrainingPreferencesDataSource preferences;
  final ActiveSessionResolver activeSessionResolver;
  final TrainingSeedStore seedStore;
  final DateTime Function() _now;

  @override
  Stream<List<PlanTemplate>> observePlanTemplates() {
    return activeSessionResolver.observeSessionId().switchMap((sessionId) {
      return customRoutineDao.observeForSession(sessionId).map((routines) {
        return <PlanTemplate>[
          ...seedStore.templates,
          ...routines.map((routine) => routine.toPlanTemplate()),
        ];
      });
    });
  }

  @override
  Future<OperationResult<void>> selectPlanTemplate(String templateId) async {
    try {
      final sessionId = await activeSessionResolver.sessionId();
      if (!await _templateExists(sessionId, templateId)) {
        throw ArgumentError('Unknown plan template: $templateId');
      }
      await preferences.setSelectedTemplateId(sessionId, templateId);
      return OperationResult.success();
    } catch (error) {
      return OperationResult.failure(error);
    }
  }

  @override
  Future<OperationResult<PlanTemplate>> saveCustomRoutine(
    CustomRoutineInput input,
  ) async {
    try {
      final sessionId = await activeSessionResolver.sessionId();
      final existing = input.id == null
          ? null
          : await customRoutineDao.getById(
              sessionId: sessionId,
              routineId: input.id!,
            );
      final routineId = input.id?.trim().isNotEmpty == true
          ? input.id!.trim()
          : 'custom-${_now().microsecondsSinceEpoch}';
      final now = _instantString(_now());
      await customRoutineDao.upsertFull(
        routine: input.toEntity(
          routineId: routineId,
          sessionId: sessionId,
          createdAt: existing?.routine.createdAt ?? now,
          updatedAt: now,
        ),
        days: input.toDayWrites(routineId),
      );
      final saved = await customRoutineDao.getById(
        sessionId: sessionId,
        routineId: routineId,
      );
      return OperationResult.success(saved!.toPlanTemplate());
    } catch (error) {
      return OperationResult.failure(error);
    }
  }

  @override
  Future<OperationResult<void>> deleteCustomRoutine(String templateId) async {
    try {
      final sessionId = await activeSessionResolver.sessionId();
      final deleted = await customRoutineDao.deleteRoutine(
        sessionId: sessionId,
        routineId: templateId,
      );
      if (deleted <= 0) {
        throw ArgumentError('Unknown custom routine: $templateId');
      }
      final selectedTemplateId = await preferences
          .selectedTemplateId(sessionId)
          .first;
      final activeTemplateId =
          (await preferences.activeRoutineProgress(sessionId).first).templateId;
      if (selectedTemplateId == templateId || activeTemplateId == templateId) {
        final fallbackTemplateId = seedStore.templates.first.id;
        await preferences.setSelectedTemplateId(sessionId, fallbackTemplateId);
        await preferences.setActiveRoutineTemplate(
          sessionId,
          fallbackTemplateId,
        );
      }
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

String _instantString(DateTime value) {
  final iso = value.toUtc().toIso8601String();
  return iso.endsWith('.000Z') ? '${iso.substring(0, iso.length - 5)}Z' : iso;
}
