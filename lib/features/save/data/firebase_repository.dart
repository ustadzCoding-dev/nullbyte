import 'package:nullbyte/shared/models/level_progress_data.dart';
import 'package:nullbyte/shared/models/player_profile.dart';

/// Repository sinkronisasi remote yang sengaja ditunda untuk V1.
/// Semua operasi di-no-op karena progression lokal menjadi sumber kebenaran.
class FirebaseRepository {
  const FirebaseRepository();

  Future<void> syncProgress(
    String userId,
    String levelId,
    LevelProgressData data,
  ) async {}

  Future<void> syncPlayerProfile(String userId, PlayerProfile profile) async {}

  Future<Map<String, LevelProgressData>> fetchProgress(String userId) async =>
      {};

  /// Resolusi konflik sederhana: pilih data dengan completedAt paling baru.
  static LevelProgressData resolveConflict(
    LevelProgressData local,
    LevelProgressData remote,
  ) {
    final localTime = local.completedAt;
    final remoteTime = remote.completedAt;
    if (localTime == null) return remote;
    if (remoteTime == null) return local;
    return localTime.isAfter(remoteTime) ? local : remote;
  }

  Future<void> updateLeaderboard(
    String userId,
    String username,
    int totalScore,
    int playerLevel,
    int levelsCompleted,
  ) async {}
}
