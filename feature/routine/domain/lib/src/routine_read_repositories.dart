import 'package:smart_trainner_core_model/smart_trainner_core_model.dart';

abstract interface class RoutinePlanCatalogRepository {
  Stream<List<PlanTemplate>> observePlanTemplates();
}

abstract interface class RoutineProgressRepository {
  Stream<RoutineProgress> observeRoutineProgress();
}
