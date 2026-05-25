import 'hint_data.dart';
import 'level_objective.dart';
import 'network_topology.dart';

/// Defines a single playable level loaded from a JSON asset.
class LevelDefinition {
  final String id;
  final String missionId;
  final String title;
  final String narrative;
  final String domain; // network | web | crypto | social | forensics
  final int difficulty; // 1-5
  final NetworkTopology topology;
  final List<LevelObjective> objectives;
  final String flagHash; // SHA-256 of the flag string
  final List<HintData> hints;
  final List<String> expectedCommandPath;
  final String realWorldContext;
  final List<String> recommendedTools;

  const LevelDefinition({
    required this.id,
    required this.missionId,
    required this.title,
    required this.narrative,
    required this.domain,
    required this.difficulty,
    required this.topology,
    required this.objectives,
    required this.flagHash,
    required this.hints,
    required this.expectedCommandPath,
    required this.realWorldContext,
    required this.recommendedTools,
  });

  factory LevelDefinition.fromJson(Map<String, dynamic> json) {
    return LevelDefinition(
      id: json['id'] as String,
      missionId: json['missionId'] as String,
      title: json['title'] as String,
      narrative: json['narrative'] as String,
      domain: json['domain'] as String,
      difficulty: json['difficulty'] as int,
      topology: NetworkTopology.fromJson(
        json['topology'] as Map<String, dynamic>,
      ),
      objectives: (json['objectives'] as List<dynamic>? ?? [])
          .map((e) => LevelObjective.fromJson(e as Map<String, dynamic>))
          .toList(),
      flagHash: json['flagHash'] as String,
      hints: (json['hints'] as List<dynamic>? ?? [])
          .map((e) => HintData.fromJson(e as Map<String, dynamic>))
          .toList(),
      expectedCommandPath: (json['expectedCommandPath'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      realWorldContext: json['realWorldContext'] as String,
      recommendedTools: (json['recommendedTools'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
    );
  }
}
