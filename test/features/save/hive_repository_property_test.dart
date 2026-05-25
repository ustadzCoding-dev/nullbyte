// Property test untuk HiveRepository (round-trip)
//
// **Validates: Requirements 1.4, 5.1, 10.1**
//
// Property 2: Penyimpanan Lokal Round-Trip
// For any game progress data (LevelProgress, ToolItem, Achievement),
// saving to Hive and then reading back SHALL result in data identical
// to the original data.

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nullbyte/features/save/data/hive_repository.dart';
import 'package:nullbyte/shared/models/achievement.dart';
import 'package:nullbyte/shared/models/level_progress_data.dart';
import 'package:nullbyte/shared/models/tool_item.dart';

// ── Generators ────────────────────────────────────────────────────────────────

/// Generates a random [LevelProgressData] with varied properties.
LevelProgressData _generateLevelProgress(Random rng, String levelId) {
  return LevelProgressData(
    levelId: levelId,
    isCompleted: rng.nextBool(),
    bestScore: rng.nextInt(3000),
    bestTime: rng.nextInt(3600),
    starsEarned: rng.nextInt(4), // 0-3
    hintsUsed: rng.nextInt(5),
    completedAt: rng.nextBool() ? DateTime.now() : null,
  );
}

/// Generates a random [ToolItem] with varied properties.
ToolItem _generateToolItem(Random rng, String toolId) {
  final categories = ['recon', 'exploit', 'crypto', 'post-exploit'];
  return ToolItem(
    id: toolId,
    name: 'Tool_$toolId',
    category: categories[rng.nextInt(categories.length)],
    description: 'Description for $toolId',
    realWorldContext: 'Real world context for $toolId',
    level: rng.nextInt(5) + 1,
    stats: {
      'penetration': rng.nextInt(100),
      'stealth': rng.nextInt(100),
      'speed': rng.nextInt(100),
    },
    unlockedByLevelIds: [
      for (var i = 0; i < rng.nextInt(3); i++) 'level_${rng.nextInt(100)}',
    ],
  );
}

/// Generates a random [Achievement] with varied properties.
Achievement _generateAchievement(Random rng, String achId) {
  final conditionTypes = ['level_complete', 'score_threshold', 'time_limit'];
  return Achievement(
    id: achId,
    title: 'Achievement_$achId',
    description: 'Description for $achId',
    isSecret: rng.nextBool(),
    conditionType: conditionTypes[rng.nextInt(conditionTypes.length)],
    conditionValue: rng.nextInt(5000),
    bonusPoints: rng.nextInt(500),
    isUnlocked: rng.nextBool(),
    unlockedAt: rng.nextBool() ? DateTime.now() : null,
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  const iterations = 50;

  setUpAll(() async {
    // Initialize Hive for testing (use in-memory for unit tests)
    Hive.init('.');

    // Register adapters
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(LevelProgressDataAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(ToolItemAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(AchievementAdapter());
    }
  });

  group('Property 2: Penyimpanan Lokal Round-Trip', () {
    test(
      'LevelProgressData round-trip: save and load returns identical data',
      () async {
        final repo = HiveRepository();
        final rng = Random(42);

        for (var i = 0; i < iterations; i++) {
          final levelId = 'level_roundtrip_$i';
          final original = _generateLevelProgress(rng, levelId);

          // Save to Hive
          await repo.saveProgress(levelId, original);

          // Load from Hive
          final loaded = await repo.loadProgress(levelId);

          // Verify round-trip equality
          expect(
            loaded,
            equals(original),
            reason:
                'iteration $i: loaded LevelProgressData must equal original',
          );
        }
      },
    );

    test('ToolItem round-trip: save and load returns identical data', () async {
      final repo = HiveRepository();
      final rng = Random(99);

      for (var i = 0; i < iterations; i++) {
        final toolId = 'tool_roundtrip_$i';
        final original = _generateToolItem(rng, toolId);

        // Save to Hive
        await repo.saveInventory(toolId, original);

        // Load from Hive
        final loaded = await repo.loadInventory();
        final loadedTool = loaded.firstWhere((t) => t.id == toolId);

        // Verify round-trip equality
        expect(
          loadedTool,
          equals(original),
          reason: 'iteration $i: loaded ToolItem must equal original',
        );
      }
    });

    test(
      'Achievement round-trip: save and load returns identical data',
      () async {
        final repo = HiveRepository();
        final rng = Random(77);

        for (var i = 0; i < iterations; i++) {
          final achId = 'ach_roundtrip_$i';
          final original = _generateAchievement(rng, achId);

          // Save to Hive
          await repo.saveAchievements([original]);

          // Load from Hive
          final loaded = await repo.loadAchievements();
          final loadedAch = loaded.firstWhere((a) => a.id == achId);

          // Verify round-trip equality
          expect(
            loadedAch,
            equals(original),
            reason: 'iteration $i: loaded Achievement must equal original',
          );
        }
      },
    );

    test(
      'LevelProgressData with null completedAt round-trips correctly',
      () async {
        final repo = HiveRepository();

        final original = LevelProgressData(
          levelId: 'level_incomplete_rt',
          isCompleted: false,
          bestScore: 0,
          bestTime: 0,
          starsEarned: 0,
          hintsUsed: 0,
          completedAt: null,
        );

        await repo.saveProgress('level_incomplete_rt', original);
        final loaded = await repo.loadProgress('level_incomplete_rt');

        expect(
          loaded,
          equals(original),
          reason: 'LevelProgressData with null completedAt must round-trip',
        );
        expect(
          loaded?.completedAt,
          isNull,
          reason: 'completedAt must remain null',
        );
      },
    );

    test(
      'ToolItem with empty stats and unlockedByLevelIds round-trips',
      () async {
        final repo = HiveRepository();

        final original = ToolItem(
          id: 'tool_empty_rt',
          name: 'Empty Tool',
          category: 'recon',
          description: 'A tool with empty stats',
          realWorldContext: 'Context',
          level: 1,
          stats: {},
          unlockedByLevelIds: [],
        );

        await repo.saveInventory('tool_empty_rt', original);
        final loaded = await repo.loadInventory();
        final loadedTool = loaded.firstWhere((t) => t.id == 'tool_empty_rt');

        expect(
          loadedTool,
          equals(original),
          reason: 'ToolItem with empty collections must round-trip',
        );
        expect(
          loadedTool.stats.isEmpty,
          isTrue,
          reason: 'stats must remain empty',
        );
        expect(
          loadedTool.unlockedByLevelIds.isEmpty,
          isTrue,
          reason: 'unlockedByLevelIds must remain empty',
        );
      },
    );

    test('Achievement with null unlockedAt round-trips correctly', () async {
      final repo = HiveRepository();

      final original = Achievement(
        id: 'ach_locked_rt',
        title: 'Locked Achievement',
        description: 'Not yet unlocked',
        isSecret: false,
        conditionType: 'level_complete',
        conditionValue: 10,
        bonusPoints: 100,
        isUnlocked: false,
        unlockedAt: null,
      );

      await repo.saveAchievements([original]);
      final loaded = await repo.loadAchievements();
      final loadedAch = loaded.firstWhere((a) => a.id == 'ach_locked_rt');

      expect(
        loadedAch,
        equals(original),
        reason: 'Achievement with null unlockedAt must round-trip',
      );
      expect(
        loadedAch.unlockedAt,
        isNull,
        reason: 'unlockedAt must remain null',
      );
    });

    test('Overwriting existing data preserves round-trip property', () async {
      final repo = HiveRepository();
      final rng = Random(33);

      const levelId = 'level_overwrite_rt';
      final original1 = _generateLevelProgress(rng, levelId);

      // Save first version
      await repo.saveProgress(levelId, original1);
      final loaded1 = await repo.loadProgress(levelId);
      expect(loaded1, equals(original1));

      // Overwrite with second version
      final original2 = _generateLevelProgress(rng, levelId);
      await repo.saveProgress(levelId, original2);
      final loaded2 = await repo.loadProgress(levelId);

      // Verify second version is loaded
      expect(
        loaded2,
        equals(original2),
        reason: 'overwritten data must round-trip correctly',
      );
      expect(
        loaded2,
        isNot(equals(original1)),
        reason: 'overwritten data must differ from first version',
      );
    });

    test('All data types preserve equality through round-trip', () async {
      final repo = HiveRepository();
      final rng = Random(123);

      // Test LevelProgressData
      final progress = _generateLevelProgress(rng, 'level_all_types');
      await repo.saveProgress('level_all_types', progress);
      final loadedProgress = await repo.loadProgress('level_all_types');
      expect(loadedProgress, equals(progress));

      // Test ToolItem
      final tool = _generateToolItem(rng, 'tool_all_types');
      await repo.saveInventory('tool_all_types', tool);
      final loadedTools = await repo.loadInventory();
      final loadedTool = loadedTools.firstWhere(
        (t) => t.id == 'tool_all_types',
      );
      expect(loadedTool, equals(tool));

      // Test Achievement
      final achievement = _generateAchievement(rng, 'ach_all_types');
      await repo.saveAchievements([achievement]);
      final loadedAchievements = await repo.loadAchievements();
      final loadedAch = loadedAchievements.firstWhere(
        (a) => a.id == 'ach_all_types',
      );
      expect(loadedAch, equals(achievement));
    });
  });
}
