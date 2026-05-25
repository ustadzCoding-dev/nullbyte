/// A single hint for a level, with a difficulty level (1–3).
class HintData {
  final int level; // 1 = easy hint, 3 = near-solution
  final String text;

  const HintData({required this.level, required this.text});

  factory HintData.fromJson(Map<String, dynamic> json) {
    return HintData(level: json['level'] as int, text: json['text'] as String);
  }
}
