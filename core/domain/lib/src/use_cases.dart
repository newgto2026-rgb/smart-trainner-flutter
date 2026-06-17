import 'package:smart_trainner_core_domain/src/training_repository.dart';
import 'package:smart_trainner_core_model/smart_trainner_core_model.dart';

class ObserveExercisesUseCase {
  const ObserveExercisesUseCase(this.repository);

  final TrainingRepository repository;

  Stream<List<Exercise>> call() => repository.observeExercises();
}

class ObservePlanTemplatesUseCase {
  const ObservePlanTemplatesUseCase(this.repository);

  final TrainingRepository repository;

  Stream<List<PlanTemplate>> call() => repository.observePlanTemplates();
}

class ObserveCurrentWeeklyPlanUseCase {
  const ObserveCurrentWeeklyPlanUseCase(this.repository);

  final TrainingRepository repository;

  Stream<WeeklyPlan> call(DateTime weekStartDate) {
    return repository.observeCurrentWeeklyPlan(weekStartDate);
  }
}

class ObserveWorkoutLogsUseCase {
  const ObserveWorkoutLogsUseCase(this.repository);

  final TrainingRepository repository;

  Stream<List<WorkoutLog>> call(DateTime weekStartDate) {
    return repository.observeWorkoutLogs(weekStartDate);
  }
}

class ObserveWeeklySummaryUseCase {
  const ObserveWeeklySummaryUseCase(this.repository);

  final TrainingRepository repository;

  Stream<WeeklySummary> call(DateTime weekStartDate) {
    return repository.observeWeeklySummary(weekStartDate);
  }
}

class GetExerciseUseCase {
  const GetExerciseUseCase(this.repository);

  final TrainingRepository repository;

  Future<Exercise?> call(ExerciseId id) => repository.getExercise(id);
}

class CreateCustomExerciseUseCase {
  const CreateCustomExerciseUseCase(this.repository);

  final TrainingRepository repository;

  Future<OperationResult<Exercise>> call(CustomExerciseInput input) {
    return repository.createCustomExercise(input);
  }
}

class SaveWorkoutLogUseCase {
  const SaveWorkoutLogUseCase(this.repository);

  final TrainingRepository repository;

  Future<OperationResult<void>> call(WorkoutLogInput input) {
    return repository.saveWorkoutLog(input);
  }
}

class SelectPlanTemplateUseCase {
  const SelectPlanTemplateUseCase(this.repository);

  final TrainingRepository repository;

  Future<OperationResult<void>> call(String templateId) {
    return repository.selectPlanTemplate(templateId);
  }
}

class ObserveActiveSessionUseCase {
  const ObserveActiveSessionUseCase(this.repository);

  final SessionRepository repository;

  Stream<UserSession?> call() => repository.observeActiveSession();
}

class StartDefaultSessionUseCase {
  const StartDefaultSessionUseCase(this.repository);

  final SessionRepository repository;

  Future<OperationResult<UserSession>> call() {
    return repository.startDefaultSession();
  }
}

class SignOutUseCase {
  const SignOutUseCase(this.repository);

  final SessionRepository repository;

  Future<OperationResult<void>> call() => repository.signOut();
}
