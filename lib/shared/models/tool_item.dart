import 'package:hive/hive.dart';

part 'tool_item.g.dart';

@HiveType(typeId: 2)
class ToolItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String category; // recon | exploit | crypto | post-exploit

  @HiveField(3)
  final String description;

  @HiveField(4)
  final String realWorldContext;

  @HiveField(5)
  final int level; // upgrade level

  @HiveField(6)
  final Map<String, int> stats; // penetration, stealth, speed

  @HiveField(7)
  final List<String> unlockedByLevelIds;

  ToolItem({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.realWorldContext,
    this.level = 1,
    Map<String, int>? stats,
    List<String>? unlockedByLevelIds,
  }) : stats = stats ?? {},
       unlockedByLevelIds = unlockedByLevelIds ?? [];

  ToolItem copyWith({
    String? id,
    String? name,
    String? category,
    String? description,
    String? realWorldContext,
    int? level,
    Map<String, int>? stats,
    List<String>? unlockedByLevelIds,
  }) {
    return ToolItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
      realWorldContext: realWorldContext ?? this.realWorldContext,
      level: level ?? this.level,
      stats: stats ?? Map.from(this.stats),
      unlockedByLevelIds:
          unlockedByLevelIds ?? List.from(this.unlockedByLevelIds),
    );
  }
}
