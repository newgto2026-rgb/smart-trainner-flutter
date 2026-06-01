import 'package:smart_trainner_core_domain/smart_trainner_core_domain.dart';
import 'package:smart_trainner_core_model/smart_trainner_core_model.dart';
import 'package:smart_trainner_feature_analysis_domain/smart_trainner_feature_analysis_domain.dart';

class DefaultWeeklySummaryRepository implements AnalysisSummaryRepository {
  const DefaultWeeklySummaryRepository(this.trainingRepository);

  final TrainingRepository trainingRepository;

  @override
  Stream<WeeklySummary> observeWeeklySummary(DateTime weekStartDate) {
    return trainingRepository.observeWeeklySummary(weekStartDate);
  }
}
