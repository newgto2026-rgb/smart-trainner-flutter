import 'package:smart_trainner_core_domain/smart_trainner_core_domain.dart';
import 'package:smart_trainner_core_model/smart_trainner_core_model.dart';

class ObserveExerciseCatalogUseCase {
  const ObserveExerciseCatalogUseCase(this.repository);

  final ExerciseRepository repository;

  Stream<List<Exercise>> call() => repository.observeExercises();
}

class GetExerciseDetailUseCase {
  const GetExerciseDetailUseCase(this.repository);

  final ExerciseRepository repository;

  Future<Exercise?> call(ExerciseId id) => repository.getExercise(id);
}

class GetExerciseUseCase extends GetExerciseDetailUseCase {
  const GetExerciseUseCase(super.repository);
}
