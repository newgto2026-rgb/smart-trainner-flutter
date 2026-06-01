import 'package:smart_trainner_core_database/smart_trainner_core_database.dart';
import 'package:smart_trainner_core_model/smart_trainner_core_model.dart';

extension CustomRoutineInputEntityMapper on CustomRoutineInput {
  CustomRoutineEntity toEntity({
    required String routineId,
    required String sessionId,
    required String createdAt,
    required String updatedAt,
  }) {
    return CustomRoutineEntity(
      id: routineId,
      sessionId: sessionId,
      name: name.trim(),
      description: description.trim(),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  List<CustomRoutineDayWrite> toDayWrites(String routineId) {
    return days.indexed.map((entry) {
      final dayIndex = entry.$1;
      final day = entry.$2;
      final dayId = customRoutineDayId(routineId, dayIndex);
      return CustomRoutineDayWrite(
        day: day.toEntity(id: dayId, routineId: routineId, dayIndex: dayIndex),
        exercises: day.exercises.indexed.map((exerciseEntry) {
          final slotIndex = exerciseEntry.$1;
          return exerciseEntry.$2.toEntity(
            id: customRoutineExerciseId(dayId, slotIndex),
            dayId: dayId,
            slotIndex: slotIndex,
          );
        }).toList(),
      );
    }).toList();
  }
}

extension CustomRoutineDayInputEntityMapper on CustomRoutineDayInput {
  CustomRoutineDayEntity toEntity({
    required String id,
    required String routineId,
    required int dayIndex,
  }) {
    return CustomRoutineDayEntity(
      id: id,
      routineId: routineId,
      dayIndex: dayIndex,
      title: title.trim(),
      focus: focus.trim().isEmpty ? (primaryFocus?.dbName ?? '') : focus.trim(),
      primaryFocus: primaryFocus?.dbName ?? '',
      secondaryFocuses: secondaryFocuses.map((focus) => focus.dbName).join(','),
      minRecoveryHours: minRecoveryHours,
    );
  }
}

extension CustomRoutineExerciseInputEntityMapper on CustomRoutineExerciseInput {
  CustomRoutineExerciseEntity toEntity({
    required String id,
    required String dayId,
    required int slotIndex,
  }) {
    return CustomRoutineExerciseEntity(
      id: id,
      dayId: dayId,
      slotIndex: slotIndex,
      exerciseId: exerciseId.value,
      sets: sets,
      repRangeStart: repRangeStart,
      repRangeEnd: repRangeEnd,
      durationMinutes: durationMinutes,
      restSeconds: restSeconds,
      note: note,
    );
  }
}

extension on RoutineFocus {
  String get dbName {
    final buffer = StringBuffer();
    for (final codeUnit in name.codeUnits) {
      final char = String.fromCharCode(codeUnit);
      if (char.toUpperCase() == char && buffer.isNotEmpty) {
        buffer.write('_');
      }
      buffer.write(char.toUpperCase());
    }
    return buffer.toString();
  }
}

String customRoutineDayId(String routineId, int dayIndex) {
  return '$routineId-day-${dayIndex + 1}';
}

String customRoutineExerciseId(String dayId, int slotIndex) {
  return '$dayId-slot-${slotIndex + 1}';
}
