import 'package:hive_flutter/hive_flutter.dart';
import 'package:nullbyte/core/constants/hive_boxes.dart';
import 'package:nullbyte/shared/models/achievement.dart';
import 'package:nullbyte/shared/models/game_session_state.dart';
import 'package:nullbyte/shared/models/level_progress_data.dart';
import 'package:nullbyte/shared/models/player_profile.dart';
import 'package:nullbyte/shared/models/tool_item.dart';

/// Offline-first local storage repository backed by Hive.
///
/// All write operations persist to Hive immediately.
/// Firebase sync is queued separately (see FirebaseRepository).
class HiveRepository {
  // ── Progress ────────────────────────────────────────────────────────────────

  Future<void> saveProgress(String levelId, LevelProgressData data) async {
    final box = await _openBox<LevelProgressData>(HiveBoxes.gameProgress);
    await box.put(levelId, data);
  }

  Future<LevelProgressData?> loadProgress(String levelId) async {
    final box = await _openBox<LevelProgressData>(HiveBoxes.gameProgress);
    return box.get(levelId);
  }

  Future<Map<String, LevelProgressData>> loadAllProgress() async {
    final box = await _openBox<LevelProgressData>(HiveBoxes.gameProgress);
    return {
      for (final key in box.keys) key.toString(): box.get(key)!,
    };
  }

  // ── Inventory ────────────────────────────────────────────────────────────────

  Future<void> saveInventory(String toolId, ToolItem tool) async {
    final box = await _openBox<ToolItem>(HiveBoxes.inventory);
    await box.put(toolId, tool);
  }

  Future<List<ToolItem>> loadInventory() async {
    final box = await _openBox<ToolItem>(HiveBoxes.inventory);
    return box.values.toList();
  }

  // ── Achievements ─────────────────────────────────────────────────────────────

  Future<void> saveAchievements(List<Achievement> achievements) async {
    final box = await _openBox<Achievement>(HiveBoxes.achievements);
    final entries = {for (final a in achievements) a.id: a};
    await box.putAll(entries);
  }

  Future<List<Achievement>> loadAchievements() async {
    final box = await _openBox<Achievement>(HiveBoxes.achievements);
    return box.values.toList();
  }

  // ── Settings ─────────────────────────────────────────────────────────────────

  Future<void> saveSettings(String key, dynamic value) async {
    final box = await _openBox<dynamic>(HiveBoxes.settings);
    await box.put(key, value);
  }

  /// Returns the stored value synchronously if the box is already open,
  /// otherwise returns null. Call [saveSettings] first to ensure the box
  /// is open, or use [loadSettingsAsync] for a guaranteed async read.
  dynamic loadSettings(String key) {
    if (Hive.isBoxOpen(HiveBoxes.settings)) {
      return Hive.box<dynamic>(HiveBoxes.settings).get(key);
    }
    return null;
  }

  Future<dynamic> loadSettingsAsync(String key) async {
    final box = await _openBox<dynamic>(HiveBoxes.settings);
    return box.get(key);
  }

  // ── Session State ─────────────────────────────────────────────────────────────

  Future<void> saveSessionState(String levelId, GameSessionState state) async {
    final box = await _openBox<GameSessionState>(HiveBoxes.sessionState);
    await box.put(levelId, state);
  }

  Future<GameSessionState?> loadSessionState(String levelId) async {
    final box = await _openBox<GameSessionState>(HiveBoxes.sessionState);
    return box.get(levelId);
  }

  Future<void> clearSessionState(String levelId) async {
    final box = await _openBox<GameSessionState>(HiveBoxes.sessionState);
    await box.delete(levelId);
  }

  // ── Player Profile ────────────────────────────────────────────────────────────

  Future<void> savePlayerProfile(PlayerProfile profile) async {
    final box = await _openBox<PlayerProfile>(HiveBoxes.playerProfile);
    await box.put('current', profile);
  }

  Future<PlayerProfile?> loadPlayerProfile() async {
    final box = await _openBox<PlayerProfile>(HiveBoxes.playerProfile);
    return box.get('current');
  }

  // ── Clear All (logout) ────────────────────────────────────────────────────────

  /// Clears all user data from every Hive box. Used on logout.
  Future<void> clearAll() async {
    final boxNames = [
      HiveBoxes.playerProfile,
      HiveBoxes.gameProgress,
      HiveBoxes.inventory,
      HiveBoxes.skillTree,
      HiveBoxes.achievements,
      HiveBoxes.settings,
      HiveBoxes.sessionState,
      HiveBoxes.leaderboardCache,
    ];

    for (final name in boxNames) {
      if (Hive.isBoxOpen(name)) {
        await Hive.box(name).clear();
      } else {
        final box = await Hive.openBox(name);
        await box.clear();
      }
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  /// Opens a typed Hive box if not already open, otherwise returns the
  /// already-open instance. Gracefully handles the case where the box
  /// was opened with a different type by falling back to the dynamic box.
  Future<Box<T>> _openBox<T>(String name) async {
    if (Hive.isBoxOpen(name)) {
      return Hive.box<T>(name);
    }
    return Hive.openBox<T>(name);
  }
}
