// Property test untuk FirebaseRepository.resolveConflict
//
// **Validates: Requirements 10.4**
//
// Property 10: Conflict Resolution Timestamp
// For any pair (localData, remoteData) with different timestamps,
// resolveConflict SHALL always return the data with the newer timestamp,
// regardless of parameter order.

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:nullbyte/features/save/data/firebase_repository.dart';
import 'package:nullbyte/shared/models/level_progress_data.dart';
// ── Generators ────────────────────────────────────────────────────────────────

LevelProgressData _makeProgress({
  String levelId = 'level_1',
  bool isCompleted = true,
  int bestScore = 1000,
  DateTime? completedAt,
}) {
  return LevelProgressData(
    levelId: levelId,
    isCompleted: isCompleted,
    bestScore: bestScore,
    completedAt: completedAt,
  );
}

/// Generates a random [DateTime] within a wide range.
DateTime _randomDate(Random rng) {
  final base = DateTime(2020).millisecondsSinceEpoch;
  // Use days as unit to stay within nextInt's 2^32 limit
  final rangeDays = 365 * 5;
  return DateTime.fromMillisecondsSinceEpoch(
    base + rng.nextInt(rangeDays) * const Duration(days: 1).inMilliseconds,
  );
}

/// Generates a pair of distinct [DateTime] values (earlier, later).
(DateTime, DateTime) _distinctDates(Random rng) {
  final a = _randomDate(rng);
  // Ensure b is strictly after a by at least 1 second.
  final b = a.add(Duration(seconds: rng.nextInt(86400) + 1));
  return (a, b);
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  const iterations = 200;

  group('Property 10: Conflict Resolution Timestamp', () {
    test('always returns the entry with the newer completedAt, '
        'regardless of parameter order', () {
      final rng = Random(42); // fixed seed for reproducibility

      for (var i = 0; i < iterations; i++) {
        final (earlier, later) = _distinctDates(rng);

        final olderData = _makeProgress(
          levelId: 'level_$i',
          bestScore: rng.nextInt(2000),
          completedAt: earlier,
        );
        final newerData = _makeProgress(
          levelId: 'level_$i',
          bestScore: rng.nextInt(2000),
          completedAt: later,
        );

        // Order 1: local=older, remote=newer → expect newer
        final result1 = FirebaseRepository.resolveConflict(
          olderData,
          newerData,
        );
        expect(
          result1.completedAt,
          equals(later),
          reason: 'iteration $i: local=older, remote=newer should return newer',
        );

        // Order 2: local=newer, remote=older → expect newer (commutativity)
        final result2 = FirebaseRepository.resolveConflict(
          newerData,
          olderData,
        );
        expect(
          result2.completedAt,
          equals(later),
          reason: 'iteration $i: local=newer, remote=older should return newer',
        );

        // Both calls must agree (commutativity)
        expect(
          result1.completedAt,
          equals(result2.completedAt),
          reason: 'iteration $i: result must be commutative',
        );
      }
    });

    test('returns remote when local has no completedAt', () {
      final rng = Random(7);
      for (var i = 0; i < iterations; i++) {
        final ts = _randomDate(rng);
        final local = _makeProgress(levelId: 'l$i', completedAt: null);
        final remote = _makeProgress(levelId: 'l$i', completedAt: ts);

        final result = FirebaseRepository.resolveConflict(local, remote);
        expect(
          result.completedAt,
          equals(ts),
          reason:
              'iteration $i: should prefer remote when local has no timestamp',
        );
      }
    });

    test('returns local when remote has no completedAt', () {
      final rng = Random(13);
      for (var i = 0; i < iterations; i++) {
        final ts = _randomDate(rng);
        final local = _makeProgress(levelId: 'l$i', completedAt: ts);
        final remote = _makeProgress(levelId: 'l$i', completedAt: null);

        final result = FirebaseRepository.resolveConflict(local, remote);
        expect(
          result.completedAt,
          equals(ts),
          reason:
              'iteration $i: should prefer local when remote has no timestamp',
        );
      }
    });

    test('returns remote when both have no completedAt', () {
      final local = _makeProgress(levelId: 'x', completedAt: null);
      final remote = _makeProgress(levelId: 'x', completedAt: null);

      final result = FirebaseRepository.resolveConflict(local, remote);
      // When neither has a timestamp, remote (server) is source of truth.
      expect(result, equals(remote));
    });

    test('result is always one of the two inputs (no fabrication)', () {
      final rng = Random(99);
      for (var i = 0; i < iterations; i++) {
        final (earlier, later) = _distinctDates(rng);
        final local = _makeProgress(levelId: 'l$i', completedAt: earlier);
        final remote = _makeProgress(levelId: 'l$i', completedAt: later);

        final result = FirebaseRepository.resolveConflict(local, remote);
        final isLocalOrRemote = result == local || result == remote;
        expect(
          isLocalOrRemote,
          isTrue,
          reason: 'iteration $i: result must be one of the two inputs',
        );
      }
    });
  });
}
