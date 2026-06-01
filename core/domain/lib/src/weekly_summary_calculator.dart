import 'package:smart_trainner_core_model/smart_trainner_core_model.dart';

class WeeklySummaryCalculator {
  WeeklySummary calculate({
    required DateTime weekStartDate,
    required WeeklyPlan plan,
    required List<WorkoutLog> logs,
  }) {
    final plannedCount = plan.days.fold<int>(
      0,
      (sum, day) => sum + day.exercises.length,
    );
    final completedLogs = logs.where((log) => log.completed).toList();
    final completedIds = completedLogs
        .map((log) => log.plannedExerciseId)
        .toSet();
    final completedCount = plan.days.fold<int>(
      0,
      (sum, day) =>
          sum +
          day.exercises
              .where((exercise) => completedIds.contains(exercise.id))
              .length,
    );
    final totalSets = completedLogs.fold<int>(
      0,
      (sum, log) =>
          sum + (log.setEntries.isNotEmpty ? log.setEntries.length : log.sets),
    );
    final totalVolume = completedLogs.fold<double>(
      0,
      (sum, log) => sum + log.volumeKg,
    );
    final totalMinutes = completedLogs.fold<int>(0, (sum, log) {
      if (log.setEntries.isNotEmpty) {
        return sum +
            log.setEntries.fold<int>(
              0,
              (entrySum, entry) => entrySum + (entry.durationMinutes ?? 0),
            );
      }
      return sum + (log.durationMinutes ?? 0);
    });
    final exerciseByPlanId = {
      for (final day in plan.days)
        for (final exercise in day.exercises) exercise.id: exercise,
    };
    final muscleBalance = <MuscleGroup, int>{};
    for (final log in completedLogs) {
      final muscleGroup =
          exerciseByPlanId[log.plannedExerciseId]?.exercise.muscleGroup;
      if (muscleGroup != null) {
        muscleBalance[muscleGroup] = (muscleBalance[muscleGroup] ?? 0) + 1;
      }
    }
    final streakDays = completedLogs
        .map((log) => normalizeDate(log.performedAt))
        .toSet()
        .toList()
        .longestCurrentStreak(weekStartDate.add(const Duration(days: 6)));
    final rate = plannedCount == 0 ? 0 : completedCount * 100 ~/ plannedCount;
    final weakestMuscle = MuscleGroup.values
        .where(
          (muscle) =>
              muscle != MuscleGroup.cardio &&
              muscle != MuscleGroup.arms &&
              muscle != MuscleGroup.fullBody,
        )
        .fold<MuscleGroup?>(null, (weakest, muscle) {
          if (weakest == null) {
            return muscle;
          }
          return (muscleBalance[muscle] ?? 0) < (muscleBalance[weakest] ?? 0)
              ? muscle
              : weakest;
        });
    final insight = switch ((
      plannedCount,
      completedCount,
      rate,
      totalVolume,
      weakestMuscle,
    )) {
      (0, _, _, _, _) => '이번 주 플랜을 만들면 분석을 시작할 수 있어요.',
      (_, 0, _, _, _) => '첫 기록을 남기면 완료율과 볼륨 변화를 바로 볼 수 있어요.',
      (_, _, >= 80, _, _) => '이번 주 플랜 달성률이 좋아요. 다음 주에는 같은 자세 품질로 소폭만 올려보세요.',
      (_, _, _, > 0, final MuscleGroup muscle) =>
        '${muscle.displayName} 운동이 적어요. 다음 세션에 균형을 조금 맞춰보세요.',
      _ => '꾸준히 기록 중이에요. 실패 지점보다 안정적인 반복을 우선해보세요.',
    };

    return WeeklySummary(
      weekStartDate: weekStartDate,
      plannedExerciseCount: plannedCount,
      completedExerciseCount: completedCount,
      totalSets: totalSets,
      totalVolumeKg: totalVolume,
      totalMinutes: totalMinutes,
      streakDays: streakDays,
      muscleBalance: muscleBalance,
      insight: insight,
    );
  }
}

extension on List<DateTime> {
  int longestCurrentStreak(DateTime anchor) {
    if (isEmpty) {
      return 0;
    }
    final dates = map(normalizeDate).toSet();
    var cursor = normalizeDate(anchor);
    var streak = 0;
    while (dates.contains(cursor)) {
      streak += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    if (streak > 0) {
      return streak;
    }

    final latest = dates.reduce((a, b) => a.isAfter(b) ? a : b);
    cursor = latest;
    while (dates.contains(cursor)) {
      streak += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }
}
