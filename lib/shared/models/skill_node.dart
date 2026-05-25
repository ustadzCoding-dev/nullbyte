import 'package:hive/hive.dart';

part 'skill_node.g.dart';

@HiveType(typeId: 3)
class SkillNode extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String domain; // network | web | crypto | social | forensics

  @HiveField(2)
  final String name;

  @HiveField(3)
  final String description;

  @HiveField(4)
  final int xpRequired;

  @HiveField(5)
  final List<String> prerequisiteIds;

  @HiveField(6)
  final String? unlocksToolId;

  @HiveField(7)
  final Map<String, dynamic> bonuses;

  @HiveField(8)
  bool isUnlocked;

  SkillNode({
    required this.id,
    required this.domain,
    required this.name,
    required this.description,
    required this.xpRequired,
    List<String>? prerequisiteIds,
    this.unlocksToolId,
    Map<String, dynamic>? bonuses,
    this.isUnlocked = false,
  }) : prerequisiteIds = prerequisiteIds ?? [],
       bonuses = bonuses ?? {};

  SkillNode copyWith({
    String? id,
    String? domain,
    String? name,
    String? description,
    int? xpRequired,
    List<String>? prerequisiteIds,
    String? unlocksToolId,
    Map<String, dynamic>? bonuses,
    bool? isUnlocked,
  }) {
    return SkillNode(
      id: id ?? this.id,
      domain: domain ?? this.domain,
      name: name ?? this.name,
      description: description ?? this.description,
      xpRequired: xpRequired ?? this.xpRequired,
      prerequisiteIds: prerequisiteIds ?? List.from(this.prerequisiteIds),
      unlocksToolId: unlocksToolId ?? this.unlocksToolId,
      bonuses: bonuses ?? Map.from(this.bonuses),
      isUnlocked: isUnlocked ?? this.isUnlocked,
    );
  }
}
