import 'package:smart_trainner_core_domain/smart_trainner_core_domain.dart';
import 'package:smart_trainner_core_model/smart_trainner_core_model.dart';
import 'package:smart_trainner_feature_workout_domain/src/workout_recording_repositories.dart';

class GetLatestWorkoutByExerciseUseCase {
  const GetLatestWorkoutByExerciseUseCase(this.repository);

  final WorkoutRecordingRepository repository;

  Future<WorkoutLog?> call(ExerciseId exerciseId) {
    return repository.getLatestWorkoutLog(exerciseId);
  }
}

class GetLatestWorkoutLogUseCase extends GetLatestWorkoutByExerciseUseCase {
  const GetLatestWorkoutLogUseCase(super.repository);
}

class SaveWorkoutRecordUseCase {
  const SaveWorkoutRecordUseCase(this.repository);

  final WorkoutRecordingRepository repository;

  Future<OperationResult<void>> call(WorkoutLogInput input) {
    return repository.saveWorkoutLog(input);
  }
}

class SaveWorkoutLogUseCase extends SaveWorkoutRecordUseCase {
  const SaveWorkoutLogUseCase(super.repository);
}
