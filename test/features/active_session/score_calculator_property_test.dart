// Property test untuk ScoreCalculator
//
// **Validates: Requirements 2.4, 7.4**
//
// Property 5: Kalkulasi Skor Monoton
// For any two sessions with the same parameters except for the number of hints used,
// the session with more hints SHALL always result in a lower or equal score;
// and the session with more failed attempts SHALL always result in a lower or equal score.
// Specifically, each hint reduces the score by exactly 100 points;
// each failed attempt reduces the score by exactly 50 points.

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:nullbyte/features/active_session/domain/score_calculator.dart';

// ── Generators ────────────────────────────────────────────────────────────────

/// Generate random but reasonable game session parameters.
Map<String, int> _generateSessionParams(Random rng) {
  return {
    'elapsedSeconds': rng.nextInt(3600), // 0-3600 seconds (1 hour)
    'hintsUsed': rng.nextInt(4), // 0-3 hints
    'failedAttempts': rng.nextInt(10), // 0-9 failed attempts
  };
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  const iterations = 100;
  late ScoreCalculator calculator;

  setUpAll(() {
    calculator = const ScoreCalculator();
  });

  group('Property 5: Kalkulasi Skor Monoton', () {
    test('more hints always results in lower or equal score', () async {
      final rng = Random(42);

      for (var i = 0; i < iterations; i++) {
        final baseParams = _generateSessionParams(rng);
        final elapsedSeconds = baseParams['elapsedSeconds']!;
        final failedAttempts = baseParams['failedAttempts']!;

        // Generate two hint counts where hintsUsed1 < hintsUsed2
        final hintsUsed1 = rng.nextInt(3); // 0-2
        final hintsUsed2 =
            hintsUsed1 + rng.nextInt(2) + 1; // hintsUsed1+1 to hintsUsed1+2

        final score1 = calculator.calculate(
          elapsedSeconds: elapsedSeconds,
          hintsUsed: hintsUsed1,
          failedAttempts: failedAttempts,
        );

        final score2 = calculator.calculate(
          elapsedSeconds: elapsedSeconds,
          hintsUsed: hintsUsed2,
          failedAttempts: failedAttempts,
        );

        expect(
          score1,
          greaterThanOrEqualTo(score2),
          reason:
              'iteration $i: score with fewer hints ($hintsUsed1) '
              'must be >= score with more hints ($hintsUsed2)',
        );
      }
    });

    test('more failed attempts always results in lower or equal score', () async {
      final rng = Random(99);

      for (var i = 0; i < iterations; i++) {
        final baseParams = _generateSessionParams(rng);
        final elapsedSeconds = baseParams['elapsedSeconds']!;
        final hintsUsed = baseParams['hintsUsed']!;

        // Generate two failed attempt counts where failedAttempts1 < failedAttempts2
        final failedAttempts1 = rng.nextInt(5); // 0-4
        final failedAttempts2 =
            failedAttempts1 +
            rng.nextInt(3) +
            1; // failedAttempts1+1 to failedAttempts1+3

        final score1 = calculator.calculate(
          elapsedSeconds: elapsedSeconds,
          hintsUsed: hintsUsed,
          failedAttempts: failedAttempts1,
        );

        final score2 = calculator.calculate(
          elapsedSeconds: elapsedSeconds,
          hintsUsed: hintsUsed,
          failedAttempts: failedAttempts2,
        );

        expect(
          score1,
          greaterThanOrEqualTo(score2),
          reason:
              'iteration $i: score with fewer failed attempts ($failedAttempts1) '
              'must be >= score with more failed attempts ($failedAttempts2)',
        );
      }
    });

    test('each hint reduces score by exactly 100 points', () async {
      final rng = Random(77);

      for (var i = 0; i < iterations; i++) {
        final elapsedSeconds = rng.nextInt(3600);
        final failedAttempts = rng.nextInt(10);

        // Calculate scores with 1 and 2 hints (to avoid no-hint bonus interference)
        final score1Hint = calculator.calculate(
          elapsedSeconds: elapsedSeconds,
          hintsUsed: 1,
          failedAttempts: failedAttempts,
        );

        final score2Hints = calculator.calculate(
          elapsedSeconds: elapsedSeconds,
          hintsUsed: 2,
          failedAttempts: failedAttempts,
        );

        final difference = score1Hint - score2Hints;

        expect(
          difference,
          equals(100),
          reason:
              'iteration $i: each hint must reduce score by exactly 100 points',
        );
      }
    });

    test('each failed attempt reduces score by exactly 50 points', () async {
      final rng = Random(55);

      for (var i = 0; i < iterations; i++) {
        final elapsedSeconds = rng.nextInt(3600);
        final hintsUsed = rng.nextInt(4);

        // Calculate scores with 0 and 1 failed attempt
        final score0Fails = calculator.calculate(
          elapsedSeconds: elapsedSeconds,
          hintsUsed: hintsUsed,
          failedAttempts: 0,
        );

        final score1Fail = calculator.calculate(
          elapsedSeconds: elapsedSeconds,
          hintsUsed: hintsUsed,
          failedAttempts: 1,
        );

        final difference = score0Fails - score1Fail;

        expect(
          difference,
          equals(50),
          reason:
              'iteration $i: each failed attempt must reduce score by exactly 50 points',
        );
      }
    });

    test('multiple hints accumulate penalty correctly', () async {
      final rng = Random(33);

      for (var i = 0; i < iterations; i++) {
        final elapsedSeconds = rng.nextInt(3600);
        final failedAttempts = rng.nextInt(10);

        final score1Hint = calculator.calculate(
          elapsedSeconds: elapsedSeconds,
          hintsUsed: 1,
          failedAttempts: failedAttempts,
        );

        final score4Hints = calculator.calculate(
          elapsedSeconds: elapsedSeconds,
          hintsUsed: 4,
          failedAttempts: failedAttempts,
        );

        final totalPenalty = score1Hint - score4Hints;
        final expectedPenalty = 3 * 100; // 3 additional hints * 100 points each

        expect(
          totalPenalty,
          equals(expectedPenalty),
          reason:
              'iteration $i: 3 additional hints must reduce score by exactly 300 points',
        );
      }
    });

    test('multiple failed attempts accumulate penalty correctly', () async {
      final rng = Random(11);

      for (var i = 0; i < iterations; i++) {
        final elapsedSeconds = rng.nextInt(3600);
        final hintsUsed = rng.nextInt(4);

        final score0Fails = calculator.calculate(
          elapsedSeconds: elapsedSeconds,
          hintsUsed: hintsUsed,
          failedAttempts: 0,
        );

        final score5Fails = calculator.calculate(
          elapsedSeconds: elapsedSeconds,
          hintsUsed: hintsUsed,
          failedAttempts: 5,
        );

        final totalPenalty = score0Fails - score5Fails;
        final expectedPenalty = 5 * 50; // 5 attempts * 50 points each

        expect(
          totalPenalty,
          equals(expectedPenalty),
          reason:
              'iteration $i: 5 failed attempts must reduce score by exactly 250 points',
        );
      }
    });

    test('score never goes below zero', () async {
      final rng = Random(88);

      for (var i = 0; i < iterations; i++) {
        final elapsedSeconds = rng.nextInt(3600);
        final hintsUsed = rng.nextInt(10) + 5; // 5-14 hints (high penalty)
        final failedAttempts =
            rng.nextInt(20) + 10; // 10-29 failed attempts (high penalty)

        final score = calculator.calculate(
          elapsedSeconds: elapsedSeconds,
          hintsUsed: hintsUsed,
          failedAttempts: failedAttempts,
        );

        expect(
          score,
          greaterThanOrEqualTo(0),
          reason: 'iteration $i: score must never be negative',
        );
      }
    });

    test('no-hint bonus is applied only when hints are zero', () async {
      final rng = Random(66);

      for (var i = 0; i < iterations; i++) {
        final elapsedSeconds = rng.nextInt(3600);
        final failedAttempts = rng.nextInt(10);

        // Score with 0 hints (should include no-hint bonus)
        final score0Hints = calculator.calculate(
          elapsedSeconds: elapsedSeconds,
          hintsUsed: 0,
          failedAttempts: failedAttempts,
        );

        // Score with 1 hint (no no-hint bonus)
        final score1Hint = calculator.calculate(
          elapsedSeconds: elapsedSeconds,
          hintsUsed: 1,
          failedAttempts: failedAttempts,
        );

        // The difference should be 100 (hint penalty) + 200 (no-hint bonus) = 300
        final difference = score0Hints - score1Hint;

        expect(
          difference,
          equals(300),
          reason:
              'iteration $i: difference must include both hint penalty (100) '
              'and no-hint bonus (200)',
        );
      }
    });

    test('time bonus decreases as elapsed time increases', () async {
      final rng = Random(44);

      for (var i = 0; i < iterations; i++) {
        final hintsUsed = rng.nextInt(4);
        final failedAttempts = rng.nextInt(10);

        // Two different elapsed times
        final elapsedSeconds1 = rng.nextInt(1000);
        final elapsedSeconds2 = elapsedSeconds1 + rng.nextInt(1000) + 1;

        final score1 = calculator.calculate(
          elapsedSeconds: elapsedSeconds1,
          hintsUsed: hintsUsed,
          failedAttempts: failedAttempts,
        );

        final score2 = calculator.calculate(
          elapsedSeconds: elapsedSeconds2,
          hintsUsed: hintsUsed,
          failedAttempts: failedAttempts,
        );

        expect(
          score1,
          greaterThanOrEqualTo(score2),
          reason:
              'iteration $i: score with less elapsed time must be >= '
              'score with more elapsed time',
        );
      }
    });

    test(
      'perfect play (no hints, no fails, fast time) yields highest score',
      () async {
        final rng = Random(22);

        for (var i = 0; i < iterations; i++) {
          final elapsedSeconds = rng.nextInt(100); // Very fast

          final perfectScore = calculator.calculate(
            elapsedSeconds: elapsedSeconds,
            hintsUsed: 0,
            failedAttempts: 0,
          );

          // Compare with any other scenario
          final otherScore = calculator.calculate(
            elapsedSeconds: elapsedSeconds + 100,
            hintsUsed: 1,
            failedAttempts: 1,
          );

          expect(
            perfectScore,
            greaterThan(otherScore),
            reason: 'iteration $i: perfect play must yield higher score',
          );
        }
      },
    );
  });
}
