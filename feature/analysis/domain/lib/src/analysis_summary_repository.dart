import 'package:smart_trainner_core_model/smart_trainner_core_model.dart';

abstract interface class WeeklySummaryRepository {
  Stream<WeeklySummary> observeWeeklySummary(DateTime weekStartDate);
}

abstract interface class AnalysisSummaryRepository
    implements WeeklySummaryRepository {}
