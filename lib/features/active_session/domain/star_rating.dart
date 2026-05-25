import 'package:nullbyte/core/constants/app_constants.dart';

/// Hasil rating bintang dari sebuah skor.
class StarRatingResult {
  final int stars;
  final int score;
  final String label;

  const StarRatingResult({
    required this.stars,
    required this.score,
    required this.label,
  });

  @override
  String toString() =>
      'StarRatingResult(stars: $stars, score: $score, label: $label)';
}

/// Kalkulasi rating bintang berdasarkan skor akhir.
class StarRating {
  const StarRating();

  /// Return jumlah bintang (1-3) berdasarkan [score].
  int calculate(int score) {
    if (score >= AppConstants.scoreStarThreshold3) return 3;
    if (score >= AppConstants.scoreStarThreshold2) return 2;
    return 1;
  }

  /// Return [StarRatingResult] lengkap dengan label.
  StarRatingResult result(int score) {
    final stars = calculate(score);
    final label = switch (stars) {
      3 => 'ELITE',
      2 => 'HACKER',
      _ => 'SCRIPT KIDDIE',
    };
    return StarRatingResult(stars: stars, score: score, label: label);
  }
}
