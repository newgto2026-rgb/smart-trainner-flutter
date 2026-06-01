import 'package:smart_trainner_core_model/smart_trainner_core_model.dart';
import 'package:smart_trainner_feature_analysis_domain/src/analysis_summary_repository.dart';

class ObserveWeeklySummaryUseCase {
  const ObserveWeeklySummaryUseCase(this.repository);

  final WeeklySummaryRepository repository;

  Stream<WeeklySummary> call(DateTime weekStartDate) {
    return repository.observeWeeklySummary(weekStartDate);
  }
}

class ObserveAnalysisWeeklySummaryUseCase extends ObserveWeeklySummaryUseCase {
  const ObserveAnalysisWeeklySummaryUseCase(super.repository);
}
