import 'package:smart_trainner_core_domain/smart_trainner_core_domain.dart';
import 'package:smart_trainner_core_model/smart_trainner_core_model.dart';
import 'package:smart_trainner_feature_routine_domain/src/routine_command_repositories.dart';

enum CustomRoutineValidationError {
  name,
  days,
  emptyDay,
  unknownExercise,
  sets,
  reps,
  duration,
  rest,
}

class ValidateCustomRoutineUseCase {
  const ValidateCustomRoutineUseCase();

  CustomRoutineValidationError? call({
    required CustomRoutineInput input,
    required Set<ExerciseId> availableExerciseIds,
  }) {
    final name = input.name.trim();
    if (name.isEmpty || name.length > _maxRoutineNameLength) {
      return CustomRoutineValidationError.name;
    }
    if (input.days.isEmpty || input.days.length > _maxRoutineDays) {
      return CustomRoutineValidationError.days;
    }
    for (final day in input.days) {
      if (day.exercises.isEmpty) {
        return CustomRoutineValidationError.emptyDay;
      }
      if (day.minRecoveryHours < 0 || day.minRecoveryHours > 168) {
        return CustomRoutineValidationError.rest;
      }
      for (final exercise in day.exercises) {
        if (!availableExerciseIds.contains(exercise.exerciseId)) {
          return CustomRoutineValidationError.unknownExercise;
        }
        if (exercise.sets < 1 || exercise.sets > 12) {
          return CustomRoutineValidationError.sets;
        }
        if (exercise.restSeconds < 0 || exercise.restSeconds > 600) {
          return CustomRoutineValidationError.rest;
        }
        final hasReps =
            exercise.repRangeStart != null || exercise.repRangeEnd != null;
        final hasDuration = exercise.durationMinutes != null;
        if (!hasReps && !hasDuration) {
          return CustomRoutineValidationError.reps;
        }
        if (hasReps) {
          final start = exercise.repRangeStart;
          final end = exercise.repRangeEnd;
          if (start == null ||
              end == null ||
              start < 1 ||
              start > 50 ||
              end < 1 ||
              end > 50 ||
              start > end) {
            return CustomRoutineValidationError.reps;
          }
        }
        final duration = exercise.durationMinutes;
        if (duration != null && (duration < 1 || duration > 240)) {
          return CustomRoutineValidationError.duration;
        }
      }
    }
    return null;
  }

  static const _maxRoutineDays = 7;
  static const _maxRoutineNameLength = 60;
}

class SelectRoutinePlanTemplateUseCase {
  const SelectRoutinePlanTemplateUseCase(this.repository);

  final RoutinePlanCommandRepository repository;

  Future<OperationResult<void>> call(String templateId) {
    return repository.selectPlanTemplate(templateId);
  }
}

class SaveCustomRoutineUseCase {
  const SaveCustomRoutineUseCase(this.repository, this.validateCustomRoutine);

  final RoutinePlanCommandRepository repository;
  final ValidateCustomRoutineUseCase validateCustomRoutine;

  Future<OperationResult<PlanTemplate>> call({
    required CustomRoutineInput input,
    required Set<ExerciseId> availableExerciseIds,
  }) {
    final error = validateCustomRoutine(
      input: input,
      availableExerciseIds: availableExerciseIds,
    );
    if (error != null) {
      return Future.value(OperationResult.failure(ArgumentError(error.name)));
    }
    return repository.saveCustomRoutine(input);
  }
}

class DeleteCustomRoutineUseCase {
  const DeleteCustomRoutineUseCase(this.repository);

  final RoutinePlanCommandRepository repository;

  Future<OperationResult<void>> call(String templateId) {
    return repository.deleteCustomRoutine(templateId);
  }
}

class StartRoutineUseCase {
  const StartRoutineUseCase(this.repository);

  final RoutineProgressCommandRepository repository;

  Future<OperationResult<void>> call(String templateId) {
    return repository.startRoutine(templateId);
  }
}

class AdvanceRoutineDayUseCase {
  const AdvanceRoutineDayUseCase();

  int call({required int completedDayIndex, required int cycleLength}) {
    if (cycleLength <= 0) {
      throw ArgumentError('Cycle length must be positive.');
    }
    if (completedDayIndex < 0 || completedDayIndex >= cycleLength) {
      throw ArgumentError('Completed day index is outside the routine cycle.');
    }
    return (completedDayIndex + 1) % cycleLength;
  }
}

class CompleteRoutineDayUseCase {
  const CompleteRoutineDayUseCase(this.repository, this.advanceRoutineDay);

  final RoutineProgressCommandRepository repository;
  final AdvanceRoutineDayUseCase advanceRoutineDay;

  Future<OperationResult<void>> call({
    required PlanTemplate template,
    required int completedDayIndex,
    required DateTime completedAt,
  }) {
    final nextDayIndex = advanceRoutineDay(
      completedDayIndex: completedDayIndex,
      cycleLength: template.cycleLength,
    );
    final newCycleStartedAt = nextDayIndex == 0 ? completedAt : null;
    return repository.markRoutineDayCompleted(
      completedDayIndex: completedDayIndex,
      nextDayIndex: nextDayIndex,
      completedAt: completedAt,
      newCycleStartedAt: newCycleStartedAt,
    );
  }
}
