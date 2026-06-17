import 'package:smart_trainner_core_model/smart_trainner_core_model.dart';

class OperationResult<T> {
  const OperationResult._({required this.value, required this.error});

  factory OperationResult.success([T? value]) {
    return OperationResult._(value: value, error: null);
  }

  factory OperationResult.failure(Object error) {
    return OperationResult._(value: null, error: error);
  }

  final T? value;
  final Object? error;

  bool get isSuccess => error == null;
}

abstract interface class TrainingRepository {
  Stream<List<Exercise>> observeExercises();
  Stream<List<PlanTemplate>> observePlanTemplates();
  Stream<WeeklyPlan> observeCurrentWeeklyPlan(DateTime weekStartDate);
  Stream<List<WorkoutLog>> observeWorkoutLogs(DateTime weekStartDate);
  Stream<WeeklySummary> observeWeeklySummary(DateTime weekStartDate);
  Future<Exercise?> getExercise(ExerciseId id);
  Future<OperationResult<Exercise>> createCustomExercise(
    CustomExerciseInput input,
  );
  Future<OperationResult<void>> selectPlanTemplate(String templateId);
  Future<OperationResult<void>> saveWorkoutLog(WorkoutLogInput input);
}

abstract interface class SessionRepository {
  Stream<UserSession?> observeActiveSession();
  Future<OperationResult<UserSession>> startDefaultSession();
  Future<OperationResult<void>> signOut();
}
