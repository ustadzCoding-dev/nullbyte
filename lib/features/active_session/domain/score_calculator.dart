import 'dart:math';

import 'package:nullbyte/core/constants/app_constants.dart';

/// Kalkulasi skor akhir sesi berdasarkan waktu, hint, dan percobaan gagal.
/// Pure class — tidak ada side effects.
class ScoreCalculator {
  const ScoreCalculator();

  /// Hitung skor akhir.
  ///
  /// Formula:
  /// ```
  /// baseScore    = 1000
  /// timeBonus    = max(0, 500 - (elapsedSeconds / 2))
  /// hintPenalty  = hintsUsed * 100
  /// failPenalty  = failedAttempts * 50
  /// noHintBonus  = hintsUsed == 0 ? 200 : 0
  /// finalScore   = baseScore + timeBonus - hintPenalty - failPenalty + noHintBonus
  /// ```
  ///
  /// Minimum return value adalah 0.
  int calculate({
    required int elapsedSeconds,
    required int hintsUsed,
    required int failedAttempts,
  }) {
    final base = AppConstants.scoreBase;
    final tb = timeBonus(elapsedSeconds);
    final hp = hintsUsed * AppConstants.scoreHintPenalty;
    final fp = failedAttempts * AppConstants.scoreFailPenalty;
    final nhb = isNoHintBonus(hintsUsed) ? AppConstants.scoreNoHintBonus : 0;

    final score = base + tb - hp - fp + nhb;
    return max(0, score);
  }

  /// Hitung time bonus saja.
  /// max(0, 500 - (elapsedSeconds / 2))
  int timeBonus(int elapsedSeconds) {
    final bonus = AppConstants.scoreTimeBonusMax - (elapsedSeconds ~/ 2);
    return max(0, bonus);
  }

  /// Return true jika pemain berhak mendapat no-hint bonus (tidak pakai hint).
  bool isNoHintBonus(int hintsUsed) => hintsUsed == 0;
}
