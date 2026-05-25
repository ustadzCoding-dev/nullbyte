import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nullbyte/features/auth/data/auth_provider.dart';
import 'package:nullbyte/features/save/providers/hive_repository_provider.dart';

class ProgressionSummary {
  const ProgressionSummary({
    required this.levelsCompleted,
    required this.totalScore,
    required this.totalStars,
    required this.operatorLevel,
    required this.achievementsUnlocked,
  });

  final int levelsCompleted;
  final int totalScore;
  final int totalStars;
  final int operatorLevel;
  final int achievementsUnlocked;
}

final progressionSummaryProvider = FutureProvider<ProgressionSummary>((
  ref,
) async {
  final repo = ref.watch(hiveRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  final progressMap = await repo.loadAllProgress();
  final achievements = await repo.loadAchievements();

  final completedLevels = progressMap.values
      .where((progress) => progress.isCompleted)
      .toList();
  final totalScore = completedLevels.fold<int>(
    0,
    (sum, progress) => sum + progress.bestScore,
  );
  final totalStars = completedLevels.fold<int>(
    0,
    (sum, progress) => sum + progress.starsEarned,
  );
  final derivedLevel = 1 + (completedLevels.length ~/ 3);

  return ProgressionSummary(
    levelsCompleted: completedLevels.length,
    totalScore: totalScore > 0 ? totalScore : (user?.totalScore ?? 0),
    totalStars: totalStars,
    operatorLevel: user != null
        ? (user.level > derivedLevel ? user.level : derivedLevel)
        : derivedLevel,
    achievementsUnlocked: achievements.where((a) => a.isUnlocked).length,
  );
});
