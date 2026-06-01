import 'package:flutter/widgets.dart';
import 'package:smart_trainner_core_domain/smart_trainner_core_domain.dart';
import 'package:smart_trainner_feature_routine_domain/smart_trainner_feature_routine_domain.dart';
import 'package:smart_trainner_feature_training_api/smart_trainner_feature_training_api.dart';
import 'package:smart_trainner_feature_training_impl/src/training_route.dart';

class TrainingFeatureEntryImpl implements TrainingFeatureEntry {
  const TrainingFeatureEntryImpl({
    required this.observeExercises,
    required this.observePlanTemplates,
    required this.observeCurrentWeeklyPlan,
    required this.observeWorkoutLogs,
    required this.observeWeeklySummary,
    required this.selectPlanTemplate,
    required this.saveWorkoutLog,
    required this.saveCustomRoutine,
  });

  final ObserveExercisesUseCase observeExercises;
  final ObservePlanTemplatesUseCase observePlanTemplates;
  final ObserveCurrentWeeklyPlanUseCase observeCurrentWeeklyPlan;
  final ObserveWorkoutLogsUseCase observeWorkoutLogs;
  final ObserveWeeklySummaryUseCase observeWeeklySummary;
  final SelectPlanTemplateUseCase selectPlanTemplate;
  final SaveWorkoutLogUseCase saveWorkoutLog;
  final SaveCustomRoutineUseCase saveCustomRoutine;

  @override
  Widget build(BuildContext context) {
    return TrainingRoute(
      observeExercises: observeExercises,
      observePlanTemplates: observePlanTemplates,
      observeCurrentWeeklyPlan: observeCurrentWeeklyPlan,
      observeWorkoutLogs: observeWorkoutLogs,
      observeWeeklySummary: observeWeeklySummary,
      selectPlanTemplate: selectPlanTemplate,
      saveWorkoutLog: saveWorkoutLog,
      saveCustomRoutine: saveCustomRoutine,
    );
  }
}
