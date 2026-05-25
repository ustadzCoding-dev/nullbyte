/// A single objective within a level that the player must complete.
class LevelObjective {
  final String id;
  final String description;
  final bool isCompleted;

  const LevelObjective({
    required this.id,
    required this.description,
    this.isCompleted = false,
  });

  factory LevelObjective.fromJson(Map<String, dynamic> json) {
    return LevelObjective(
      id: json['id'] as String,
      description: json['description'] as String,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  LevelObjective copyWith({bool? isCompleted}) {
    return LevelObjective(
      id: id,
      description: description,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
