import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nullbyte/features/achievements/providers/achievement_provider.dart';
import 'package:nullbyte/features/active_session/domain/star_rating.dart';
import 'package:nullbyte/features/auth/data/auth_provider.dart';
import 'package:nullbyte/features/mission/providers/mission_provider.dart';
import 'package:nullbyte/shared/models/game_session_state.dart';
import 'package:nullbyte/shared/models/level_definition.dart';
import 'package:nullbyte/shared/models/level_progress_data.dart';

class LevelCompletionService {
  LevelCompletionService(this._ref);

  final Ref _ref;
  static const _starRating = StarRating();

  Future<void> persistCompletedLevel({
    required LevelDefinition level,
    required GameSessionState session,
    required int elapsedSeconds,
  }) async {
    final missionNotifier = _ref.read(missionProvider.notifier);
    final currentProgress = _ref.read(missionProvider).progress[level.id];
    final finalScore = session.finalScore ?? 0;
    final starsEarned = _starRating.calculate(finalScore);

    final mergedProgress = (currentProgress ?? LevelProgressData(levelId: level.id))
        .copyWith(
          isCompleted: true,
          bestScore: max(currentProgress?.bestScore ?? 0, finalScore),
          bestTime: _mergeBestTime(currentProgress?.bestTime ?? 0, elapsedSeconds),
          starsEarned: max(currentProgress?.starsEarned ?? 0, starsEarned),
          hintsUsed: _mergeHintCount(currentProgress?.hintsUsed, session.hintsUsed),
          completedAt: DateTime.now(),
        );

    await missionNotifier.completeLevel(level.id, mergedProgress);

    final progressMap = _ref.read(missionProvider).progress;
    final completedLevels = progressMap.values.where((p) => p.isCompleted).toList();
    final totalScore = completedLevels.fold<int>(
      0,
      (sum, progress) => sum + progress.bestScore,
    );
    final operatorLevel = 1 + (completedLevels.length ~/ 3);
    final xp = completedLevels.fold<int>(
      0,
      (sum, progress) => sum + max(1, progress.starsEarned) * 100,
    );

    await _ref.read(authNotifierProvider.notifier).applyProgressStats(
          totalScore: totalScore,
          level: operatorLevel,
          xp: xp,
        );

    await _syncAchievements(
      level: level,
      session: session,
      totalScore: totalScore,
      completedCount: completedLevels.length,
      progressMap: progressMap,
      starsEarned: starsEarned,
    );
  }

  int _mergeBestTime(int currentBest, int candidate) {
    if (candidate <= 0) return currentBest;
    if (currentBest <= 0) return candidate;
    return min(currentBest, candidate);
  }

  int _mergeHintCount(int? currentHints, int candidate) {
    if (currentHints == null || currentHints <= 0) return candidate;
    return min(currentHints, candidate);
  }

  Future<void> _syncAchievements({
    required LevelDefinition level,
    required GameSessionState session,
    required int totalScore,
    required int completedCount,
    required Map<String, LevelProgressData> progressMap,
    required int starsEarned,
  }) async {
    final achievementNotifier = _ref.read(achievementProvider.notifier);
    if (_ref.read(achievementProvider).achievements.isEmpty) {
      await achievementNotifier.loadAchievements();
    }

    await achievementNotifier.checkCondition('level_complete', completedCount);
    await achievementNotifier.checkCondition(
      'total_levels_complete',
      completedCount,
    );
    await achievementNotifier.checkCondition('total_points', totalScore);
    await achievementNotifier.checkCondition('difficulty_clear', level.difficulty);

    if (session.hintsUsed == 0) {
      await achievementNotifier.checkCondition('no_hint_clear', 1);
    }

    if (starsEarned == 3 && session.hintsUsed == 0 && session.failedAttempts == 0) {
      await achievementNotifier.checkCondition('perfect_level', 1);
    }

    final missionNotifier = _ref.read(missionProvider.notifier);
    if (missionNotifier.isMissionCompleted(level.missionId)) {
      await achievementNotifier.checkCondition(
        'mission_complete',
        _extractMissionNumber(level.missionId),
      );
    }

    final allMissionsComplete = const ['mission_1', 'mission_2', 'mission_3']
        .every(missionNotifier.isMissionCompleted);
    if (allMissionsComplete) {
      await achievementNotifier.checkCondition('all_missions_complete', 3);
    }
  }

  int _extractMissionNumber(String missionId) {
    final match = RegExp(r'mission_(\d+)').firstMatch(missionId);
    return int.tryParse(match?.group(1) ?? '') ?? 1;
  }
}

final levelCompletionServiceProvider = Provider<LevelCompletionService>((ref) {
  return LevelCompletionService(ref);
});
