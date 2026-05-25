import 'package:hive/hive.dart';

part 'level_progress_data.g.dart';

@HiveType(typeId: 5)
class LevelProgressData extends HiveObject {
  @HiveField(0)
  final String levelId;

  @HiveField(1)
  final bool isCompleted;

  @HiveField(2)
  final int bestScore;

  @HiveField(3)
  final int bestTime; // in seconds

  @HiveField(4)
  final int starsEarned; // 0–3

  @HiveField(5)
  final int hintsUsed;

  @HiveField(6)
  final DateTime? completedAt;

  LevelProgressData({
    required this.levelId,
    this.isCompleted = false,
    this.bestScore = 0,
    this.bestTime = 0,
    this.starsEarned = 0,
    this.hintsUsed = 0,
    this.completedAt,
  });

  LevelProgressData copyWith({
    String? levelId,
    bool? isCompleted,
    int? bestScore,
    int? bestTime,
    int? starsEarned,
    int? hintsUsed,
    DateTime? completedAt,
  }) {
    return LevelProgressData(
      levelId: levelId ?? this.levelId,
      isCompleted: isCompleted ?? this.isCompleted,
      bestScore: bestScore ?? this.bestScore,
      bestTime: bestTime ?? this.bestTime,
      starsEarned: starsEarned ?? this.starsEarned,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LevelProgressData &&
        other.levelId == levelId &&
        other.isCompleted == isCompleted &&
        other.bestScore == bestScore &&
        other.bestTime == bestTime &&
        other.starsEarned == starsEarned &&
        other.hintsUsed == hintsUsed &&
        other.completedAt == completedAt;
  }

  @override
  int get hashCode => Object.hash(
    levelId,
    isCompleted,
    bestScore,
    bestTime,
    starsEarned,
    hintsUsed,
    completedAt,
  );
}
