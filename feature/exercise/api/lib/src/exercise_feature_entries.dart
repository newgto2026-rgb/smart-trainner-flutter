import 'package:smart_trainner_core_model/smart_trainner_core_model.dart';

abstract interface class ExerciseCatalogFeatureEntry {
  Object route({void Function(ExerciseId exerciseId)? onExerciseSelected});
}

abstract interface class ExerciseDetailFeatureEntry {
  Object route({
    required ExerciseId exerciseId,
    bool showStartRecordAction = true,
    void Function(ExerciseId exerciseId)? onStartRecord,
  });
}
