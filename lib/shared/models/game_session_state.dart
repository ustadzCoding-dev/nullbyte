import 'package:hive/hive.dart';

import 'node_state.dart';

part 'game_session_state.g.dart';

@HiveType(typeId: 1)
class GameSessionState extends HiveObject {
  @HiveField(0)
  final String levelId;

  @HiveField(1)
  final DateTime startTime;

  @HiveField(2)
  final int hintsUsed;

  @HiveField(3)
  final int failedAttempts;

  @HiveField(4)
  final List<String> commandHistory;

  /// Maps nodeId → NodeState name (stored as String for Hive compatibility).
  @HiveField(5)
  final Map<String, String> nodeStates;

  @HiveField(6)
  final bool isCompleted;

  @HiveField(7)
  final int? finalScore;

  @HiveField(8)
  final int lives;

  @HiveField(9)
  final int elapsedSeconds;

  @HiveField(10)
  final String currentDirectory;

  @HiveField(11)
  final String currentUser;

  @HiveField(12)
  final bool hasRootPrivilege;

  /// Objective IDs yang sudah diselesaikan player (kill chain progression).
  @HiveField(13)
  final List<String> completedObjectives;

  /// Host yang sedang aktif (setelah SSH). Default: 'attacker'.
  @HiveField(14)
  final String currentHost;

  GameSessionState({
    required this.levelId,
    required this.startTime,
    this.hintsUsed = 0,
    this.failedAttempts = 0,
    List<String>? commandHistory,
    Map<String, String>? nodeStates,
    this.isCompleted = false,
    this.finalScore,
    this.lives = 3,
    this.elapsedSeconds = 0,
    this.currentDirectory = '/',
    this.currentUser = 'user',
    this.hasRootPrivilege = false,
    List<String>? completedObjectives,
    this.currentHost = 'attacker',
  }) : commandHistory = commandHistory ?? [],
       nodeStates = nodeStates ?? {},
       completedObjectives = completedObjectives ?? [];

  /// Convenience getter that converts stored strings back to [NodeState] enums.
  Map<String, NodeState> get nodeStateMap {
    return nodeStates.map(
      (key, value) => MapEntry(
        key,
        NodeState.values.firstWhere(
          (e) => e.name == value,
          orElse: () => NodeState.undiscovered,
        ),
      ),
    );
  }

  GameSessionState copyWith({
    String? levelId,
    DateTime? startTime,
    int? hintsUsed,
    int? failedAttempts,
    List<String>? commandHistory,
    Map<String, String>? nodeStates,
    bool? isCompleted,
    int? finalScore,
    int? lives,
    int? elapsedSeconds,
    String? currentDirectory,
    String? currentUser,
    bool? hasRootPrivilege,
    List<String>? completedObjectives,
    String? currentHost,
  }) {
    return GameSessionState(
      levelId: levelId ?? this.levelId,
      startTime: startTime ?? this.startTime,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      commandHistory: commandHistory ?? List.from(this.commandHistory),
      nodeStates: nodeStates ?? Map.from(this.nodeStates),
      isCompleted: isCompleted ?? this.isCompleted,
      finalScore: finalScore ?? this.finalScore,
      lives: lives ?? this.lives,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      currentDirectory: currentDirectory ?? this.currentDirectory,
      currentUser: currentUser ?? this.currentUser,
      hasRootPrivilege: hasRootPrivilege ?? this.hasRootPrivilege,
      completedObjectives:
          completedObjectives ?? List.from(this.completedObjectives),
      currentHost: currentHost ?? this.currentHost,
    );
  }
}
