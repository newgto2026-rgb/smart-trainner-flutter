import 'package:smart_trainner_core_domain/smart_trainner_core_domain.dart';
import 'package:smart_trainner_core_model/smart_trainner_core_model.dart';

abstract interface class RoutinePlanCommandRepository {
  Future<OperationResult<void>> selectPlanTemplate(String templateId);

  Future<OperationResult<PlanTemplate>> saveCustomRoutine(
    CustomRoutineInput input,
  );

  Future<OperationResult<void>> deleteCustomRoutine(String templateId);
}

abstract interface class RoutineProgressCommandRepository {
  Future<OperationResult<void>> startRoutine(String templateId);

  Future<OperationResult<void>> markRoutineDayCompleted({
    required int completedDayIndex,
    required int nextDayIndex,
    required DateTime completedAt,
    required DateTime? newCycleStartedAt,
  });
}
