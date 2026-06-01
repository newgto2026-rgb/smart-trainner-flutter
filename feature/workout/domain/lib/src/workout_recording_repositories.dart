import 'package:smart_trainner_core_domain/smart_trainner_core_domain.dart';
import 'package:smart_trainner_core_model/smart_trainner_core_model.dart';

abstract interface class WorkoutRecordingRepository {
  Future<WorkoutLog?> getLatestWorkoutLog(ExerciseId exerciseId);

  Future<OperationResult<void>> saveWorkoutLog(WorkoutLogInput input);
}
