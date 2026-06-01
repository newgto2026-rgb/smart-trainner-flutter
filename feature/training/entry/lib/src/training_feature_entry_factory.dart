import 'package:smart_trainner_core_data/smart_trainner_core_data.dart';
import 'package:smart_trainner_core_database/smart_trainner_core_database.dart';
import 'package:smart_trainner_core_datastore/smart_trainner_core_datastore.dart';
import 'package:smart_trainner_core_domain/smart_trainner_core_domain.dart';
import 'package:smart_trainner_feature_training_api/smart_trainner_feature_training_api.dart';
import 'package:smart_trainner_feature_training_impl/smart_trainner_feature_training_impl.dart';

TrainingFeatureEntry createTrainingFeatureEntry() {
  final preferences = TrainingPreferencesDataSource();
  final workoutLogDao = InMemoryWorkoutLogDao();
  final repository = DefaultTrainingRepository(
    workoutLogDao: workoutLogDao,
    preferences: preferences,
    summaryCalculator: WeeklySummaryCalculator(),
  );

  return TrainingFeatureEntryImpl(
    observeExercises: ObserveExercisesUseCase(repository),
    observePlanTemplates: ObservePlanTemplatesUseCase(repository),
    observeCurrentWeeklyPlan: ObserveCurrentWeeklyPlanUseCase(repository),
    observeWorkoutLogs: ObserveWorkoutLogsUseCase(repository),
    observeWeeklySummary: ObserveWeeklySummaryUseCase(repository),
    selectPlanTemplate: SelectPlanTemplateUseCase(repository),
    saveWorkoutLog: SaveWorkoutLogUseCase(repository),
  );
}
