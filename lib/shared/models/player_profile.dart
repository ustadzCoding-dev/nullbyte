import 'package:hive/hive.dart';

part 'player_profile.g.dart';

@HiveType(typeId: 0)
class PlayerProfile extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String username;

  @HiveField(2)
  final String? email;

  @HiveField(3)
  final bool isGuest;

  @HiveField(4)
  final int totalScore;

  @HiveField(5)
  final int level;

  @HiveField(6)
  final int xp;

  @HiveField(7)
  final DateTime createdAt;

  @HiveField(8)
  final DateTime lastSyncAt;

  PlayerProfile({
    required this.id,
    required this.username,
    this.email,
    required this.isGuest,
    this.totalScore = 0,
    this.level = 1,
    this.xp = 0,
    required this.createdAt,
    required this.lastSyncAt,
  });

  PlayerProfile copyWith({
    String? id,
    String? username,
    String? email,
    bool? isGuest,
    int? totalScore,
    int? level,
    int? xp,
    DateTime? createdAt,
    DateTime? lastSyncAt,
  }) {
    return PlayerProfile(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      isGuest: isGuest ?? this.isGuest,
      totalScore: totalScore ?? this.totalScore,
      level: level ?? this.level,
      xp: xp ?? this.xp,
      createdAt: createdAt ?? this.createdAt,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'email': email,
    'isGuest': isGuest,
    'totalScore': totalScore,
    'level': level,
    'xp': xp,
    'createdAt': createdAt.toIso8601String(),
    'lastSyncAt': lastSyncAt.toIso8601String(),
  };

  factory PlayerProfile.fromJson(Map<String, dynamic> json) => PlayerProfile(
    id: json['id'] as String,
    username: json['username'] as String,
    email: json['email'] as String?,
    isGuest: json['isGuest'] as bool? ?? true,
    totalScore: json['totalScore'] as int? ?? 0,
    level: json['level'] as int? ?? 1,
    xp: json['xp'] as int? ?? 0,
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    lastSyncAt:
        DateTime.tryParse(json['lastSyncAt'] as String? ?? '') ??
        DateTime.now(),
  );
}
