import 'package:hive/hive.dart';

part 'achievement.g.dart';

@HiveType(typeId: 4)
class Achievement extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final bool isSecret;

  @HiveField(4)
  final String conditionType;

  @HiveField(5)
  final int conditionValue;

  @HiveField(6)
  final int bonusPoints;

  @HiveField(7)
  bool isUnlocked;

  @HiveField(8)
  DateTime? unlockedAt;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    this.isSecret = false,
    required this.conditionType,
    required this.conditionValue,
    this.bonusPoints = 0,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    bool? isSecret,
    String? conditionType,
    int? conditionValue,
    int? bonusPoints,
    bool? isUnlocked,
    DateTime? unlockedAt,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isSecret: isSecret ?? this.isSecret,
      conditionType: conditionType ?? this.conditionType,
      conditionValue: conditionValue ?? this.conditionValue,
      bonusPoints: bonusPoints ?? this.bonusPoints,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }
}
