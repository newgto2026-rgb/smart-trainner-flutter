class CustomExerciseEntity {
  const CustomExerciseEntity({
    required this.id,
    required this.ownerUserId,
    required this.name,
    required this.muscleGroup,
    required this.equipment,
    required this.difficulty,
    required this.imageKey,
    required this.imagePath,
    required this.summary,
    required this.instructions,
    required this.safetyCues,
    required this.defaultSets,
    required this.defaultRepRangeFirst,
    required this.defaultRepRangeLast,
    required this.defaultDurationMinutes,
    required this.restSeconds,
    required this.source,
    required this.originExerciseId,
    required this.sourceOwnerUserId,
    required this.sourceShareId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String ownerUserId;
  final String name;
  final String muscleGroup;
  final String equipment;
  final String difficulty;
  final String imageKey;
  final String? imagePath;
  final String summary;
  final List<String> instructions;
  final List<String> safetyCues;
  final int defaultSets;
  final int? defaultRepRangeFirst;
  final int? defaultRepRangeLast;
  final int? defaultDurationMinutes;
  final int restSeconds;
  final String source;
  final String? originExerciseId;
  final String? sourceOwnerUserId;
  final String? sourceShareId;
  final String createdAt;
  final String updatedAt;

  CustomExerciseEntity copyWith({
    String? id,
    String? ownerUserId,
    String? name,
    String? muscleGroup,
    String? equipment,
    String? difficulty,
    String? imageKey,
    String? imagePath,
    String? summary,
    List<String>? instructions,
    List<String>? safetyCues,
    int? defaultSets,
    int? defaultRepRangeFirst,
    int? defaultRepRangeLast,
    int? defaultDurationMinutes,
    int? restSeconds,
    String? source,
    String? originExerciseId,
    String? sourceOwnerUserId,
    String? sourceShareId,
    String? createdAt,
    String? updatedAt,
  }) {
    return CustomExerciseEntity(
      id: id ?? this.id,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      name: name ?? this.name,
      muscleGroup: muscleGroup ?? this.muscleGroup,
      equipment: equipment ?? this.equipment,
      difficulty: difficulty ?? this.difficulty,
      imageKey: imageKey ?? this.imageKey,
      imagePath: imagePath ?? this.imagePath,
      summary: summary ?? this.summary,
      instructions: instructions ?? this.instructions,
      safetyCues: safetyCues ?? this.safetyCues,
      defaultSets: defaultSets ?? this.defaultSets,
      defaultRepRangeFirst: defaultRepRangeFirst ?? this.defaultRepRangeFirst,
      defaultRepRangeLast: defaultRepRangeLast ?? this.defaultRepRangeLast,
      defaultDurationMinutes:
          defaultDurationMinutes ?? this.defaultDurationMinutes,
      restSeconds: restSeconds ?? this.restSeconds,
      source: source ?? this.source,
      originExerciseId: originExerciseId ?? this.originExerciseId,
      sourceOwnerUserId: sourceOwnerUserId ?? this.sourceOwnerUserId,
      sourceShareId: sourceShareId ?? this.sourceShareId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
