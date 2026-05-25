import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nullbyte/features/save/data/hive_repository.dart';
import 'package:nullbyte/features/save/providers/hive_repository_provider.dart';
import 'package:nullbyte/shared/models/level_definition.dart';
import 'package:nullbyte/shared/models/level_progress_data.dart';

class MissionState {
  final Map<String, LevelDefinition> levels;
  final Map<String, LevelProgressData> progress;
  final Set<String> loadedMissionIds;
  final bool isLoading;

  const MissionState({
    this.levels = const {},
    this.progress = const {},
    this.loadedMissionIds = const {},
    this.isLoading = false,
  });

  MissionState copyWith({
    Map<String, LevelDefinition>? levels,
    Map<String, LevelProgressData>? progress,
    Set<String>? loadedMissionIds,
    bool? isLoading,
  }) {
    return MissionState(
      levels: levels ?? this.levels,
      progress: progress ?? this.progress,
      loadedMissionIds: loadedMissionIds ?? this.loadedMissionIds,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class MissionNotifier extends StateNotifier<MissionState> {
  final HiveRepository _hive;

  MissionNotifier(this._hive) : super(const MissionState());

  Future<void> loadMission(String missionId) async {
    if (state.loadedMissionIds.contains(missionId)) return;

    state = state.copyWith(isLoading: true);
    try {
      final jsonString = await rootBundle.loadString(
        'assets/data/levels/$missionId.json',
      );
      final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
      final levelList = (jsonMap['levels'] as List<dynamic>? ?? [])
          .map((e) => LevelDefinition.fromJson(e as Map<String, dynamic>))
          .toList();

      final newLevels = Map<String, LevelDefinition>.from(state.levels);
      for (final level in levelList) {
        newLevels[level.id] = level;
      }

      final mergedProgress = {
        ...state.progress,
        ...await _hive.loadAllProgress(),
      };

      state = state.copyWith(
        levels: newLevels,
        progress: mergedProgress,
        loadedMissionIds: {...state.loadedMissionIds, missionId},
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> refreshProgress() async {
    final progress = await _hive.loadAllProgress();
    state = state.copyWith(progress: progress);
  }

  Future<void> completeLevel(String levelId, LevelProgressData data) async {
    await _hive.saveProgress(levelId, data);
    final newProgress = Map<String, LevelProgressData>.from(state.progress);
    newProgress[levelId] = data;
    state = state.copyWith(progress: newProgress);
  }

  Future<void> loadProgress(String levelId) async {
    final data = await _hive.loadProgress(levelId);
    if (data != null) {
      final newProgress = Map<String, LevelProgressData>.from(state.progress);
      newProgress[levelId] = data;
      state = state.copyWith(progress: newProgress);
    }
  }

  bool areMissionsLoaded(Iterable<String> missionIds) {
    return missionIds.every(state.loadedMissionIds.contains);
  }

  bool isLevelUnlocked(String levelId) {
    final level = state.levels[levelId];
    if (level == null) return false;

    final missionLevels = getLevelsForMission(level.missionId);
    final index = missionLevels.indexWhere((l) => l.id == levelId);
    if (index <= 0) return true;

    final previousLevel = missionLevels[index - 1];
    return state.progress[previousLevel.id]?.isCompleted ?? false;
  }

  List<LevelDefinition> getLevelsForMission(String missionId) {
    final levels = state.levels.values
        .where((l) => l.missionId == missionId)
        .toList();
    levels.sort(_compareLevels);
    return levels;
  }

  List<LevelDefinition> getAllLevelsSorted() {
    final levels = state.levels.values.toList();
    levels.sort(_compareLevels);
    return levels;
  }

  bool isMissionCompleted(String missionId) {
    final levels = getLevelsForMission(missionId);
    return levels.isNotEmpty &&
        levels.every((level) => state.progress[level.id]?.isCompleted ?? false);
  }

  bool isMissionUnlocked(String missionId) {
    final missionNumber = _extractMissionNumber(missionId);
    // BUG-18 FIX: null berarti missionId tidak dikenali → anggap locked.
    if (missionNumber == null) return false;
    if (missionNumber <= 1) return true;
    return isMissionCompleted('mission_${missionNumber - 1}');
  }

  String? getCurrentPlayableLevelId(String missionId) {
    if (!isMissionUnlocked(missionId)) return null;

    final levels = getLevelsForMission(missionId);
    for (final level in levels) {
      if (!(state.progress[level.id]?.isCompleted ?? false)) {
        return level.id;
      }
    }

    return levels.isNotEmpty ? levels.first.id : null;
  }

  String? getNextLevelId(String currentLevelId) {
    final levels = getAllLevelsSorted();
    final index = levels.indexWhere((level) => level.id == currentLevelId);
    if (index == -1 || index >= levels.length - 1) return null;

    final nextLevel = levels[index + 1];
    return isMissionUnlocked(nextLevel.missionId) ? nextLevel.id : null;
  }

  int getMissionStars(String missionId) {
    final levels = getLevelsForMission(missionId);
    final completed = levels
        .map((level) => state.progress[level.id])
        .whereType<LevelProgressData>()
        .where((progress) => progress.isCompleted)
        .toList();
    if (completed.isEmpty) return 0;

    final average =
        completed.fold<int>(0, (sum, progress) => sum + progress.starsEarned) /
        completed.length;
    return average.round().clamp(0, 3);
  }

  int getCompletedLevelsCount(String missionId) {
    return getLevelsForMission(
      missionId,
    ).where((level) => state.progress[level.id]?.isCompleted ?? false).length;
  }

  int _compareLevels(LevelDefinition a, LevelDefinition b) {
    final aMission = _extractMissionNumber(a.missionId) ?? 0;
    final bMission = _extractMissionNumber(b.missionId) ?? 0;
    if (aMission != bMission) return aMission.compareTo(bMission);

    final aLevel = _extractLevelNumber(a.id) ?? 0;
    final bLevel = _extractLevelNumber(b.id) ?? 0;
    return aLevel.compareTo(bLevel);
  }

  // BUG-18 FIX: return null (bukan 0) jika regex tidak match.
  // Mencegah missionId yang typo (misal 'mission1') menyebabkan semua misi
  // tampak unlocked karena 0 <= 1 selalu true.
  int? _extractMissionNumber(String missionId) {
    final match = RegExp(r'mission_(\d+)').firstMatch(missionId);
    return int.tryParse(match?.group(1) ?? '');
  }

  int? _extractLevelNumber(String levelId) {
    final match = RegExp(r'l(\d+)$').firstMatch(levelId);
    return int.tryParse(match?.group(1) ?? '');
  }
}

final missionProvider = StateNotifierProvider<MissionNotifier, MissionState>((
  ref,
) {
  return MissionNotifier(ref.watch(hiveRepositoryProvider));
});

final isLevelUnlockedProvider = Provider.family<bool, String>((ref, levelId) {
  return ref.watch(missionProvider.notifier).isLevelUnlocked(levelId);
});
