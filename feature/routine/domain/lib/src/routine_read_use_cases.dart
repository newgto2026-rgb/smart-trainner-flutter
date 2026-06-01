import 'package:smart_trainner_core_domain/smart_trainner_core_domain.dart';
import 'package:smart_trainner_core_model/smart_trainner_core_model.dart';
import 'package:smart_trainner_feature_routine_domain/src/routine_read_repositories.dart';

class ObserveRoutineCurrentWeeklyPlanUseCase {
  const ObserveRoutineCurrentWeeklyPlanUseCase(this.repository);

  final TrainingRepository repository;

  Stream<WeeklyPlan> call(DateTime weekStartDate) {
    return repository.observeCurrentWeeklyPlan(weekStartDate);
  }
}

class ObserveRoutinePlanTemplatesUseCase {
  const ObserveRoutinePlanTemplatesUseCase(this.repository);

  final RoutinePlanCatalogRepository repository;

  Stream<List<PlanTemplate>> call() => repository.observePlanTemplates();
}

class ObserveRoutineProgressUseCase {
  const ObserveRoutineProgressUseCase(this.repository);

  final RoutineProgressRepository repository;

  Stream<RoutineProgress> call() => repository.observeRoutineProgress();
}
