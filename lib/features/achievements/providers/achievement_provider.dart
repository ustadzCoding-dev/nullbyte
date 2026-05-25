import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nullbyte/features/save/data/hive_repository.dart';
import 'package:nullbyte/features/save/providers/hive_repository_provider.dart';
import 'package:nullbyte/shared/models/achievement.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class AchievementState {
  final Map<String, Achievement> achievements;
  final Achievement? pendingUnlock;

  const AchievementState({this.achievements = const {}, this.pendingUnlock});

  AchievementState copyWith({
    Map<String, Achievement>? achievements,
    Achievement? pendingUnlock,
    bool clearPending = false,
  }) {
    return AchievementState(
      achievements: achievements ?? this.achievements,
      pendingUnlock: clearPending
          ? null
          : (pendingUnlock ?? this.pendingUnlock),
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class AchievementNotifier extends StateNotifier<AchievementState> {
  final HiveRepository _hive;

  AchievementNotifier(this._hive) : super(const AchievementState());

  /// Load achievement definitions from JSON asset and merge with Hive progress.
  Future<void> loadAchievements() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/data/achievements.json',
      );
      final jsonList = json.decode(jsonString) as List<dynamic>;
      final definitions = {
        for (final e in jsonList)
          (e as Map<String, dynamic>)['id'] as String: Achievement(
            id: e['id'] as String,
            title: e['title'] as String,
            description: e['description'] as String,
            isSecret: e['isSecret'] as bool? ?? false,
            conditionType: e['conditionType'] as String,
            conditionValue: e['conditionValue'] as int,
            bonusPoints: e['bonusPoints'] as int? ?? 0,
          ),
      };

      // Merge with persisted unlock state from Hive.
      final saved = await _hive.loadAchievements();
      final savedMap = {for (final a in saved) a.id: a};

      final merged = definitions.map((id, def) {
        final persisted = savedMap[id];
        if (persisted != null && persisted.isUnlocked) {
          return MapEntry(
            id,
            def.copyWith(isUnlocked: true, unlockedAt: persisted.unlockedAt),
          );
        }
        return MapEntry(id, def);
      });

      state = state.copyWith(achievements: merged);
    } catch (_) {
      // Asset may not exist yet; silently ignore.
    }
  }

  /// Check all achievements against a condition and unlock matching ones.
  Future<void> checkCondition(String conditionType, int value) async {
    Achievement? justUnlocked;
    final updated = Map<String, Achievement>.from(state.achievements);

    for (final entry in updated.entries) {
      final a = entry.value;
      if (a.isUnlocked) continue;
      if (a.conditionType == conditionType && value >= a.conditionValue) {
        final unlocked = a.copyWith(
          isUnlocked: true,
          unlockedAt: DateTime.now(),
        );
        updated[entry.key] = unlocked;
        justUnlocked = unlocked;
      }
    }

    if (justUnlocked != null) {
      await _hive.saveAchievements(updated.values.toList());
      state = state.copyWith(
        achievements: updated,
        pendingUnlock: justUnlocked,
      );
    }
  }

  /// Clear the pending unlock notification after it has been displayed.
  void clearPendingUnlock() {
    state = state.copyWith(clearPending: true);
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final achievementProvider =
    StateNotifierProvider<AchievementNotifier, AchievementState>((ref) {
      return AchievementNotifier(ref.watch(hiveRepositoryProvider));
    });
