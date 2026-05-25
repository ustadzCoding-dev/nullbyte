import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nullbyte/app.dart';
import 'package:nullbyte/core/constants/hive_boxes.dart';
import 'package:nullbyte/shared/models/achievement.dart';
import 'package:nullbyte/shared/models/game_session_state.dart';
import 'package:nullbyte/shared/models/level_progress_data.dart';
import 'package:nullbyte/shared/models/player_profile.dart';
import 'package:nullbyte/shared/models/skill_node.dart';
import 'package:nullbyte/shared/models/tool_item.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hive initialization
  await Hive.initFlutter();

  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(PlayerProfileAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(GameSessionStateAdapter());
  }
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(ToolItemAdapter());
  }
  if (!Hive.isAdapterRegistered(3)) {
    Hive.registerAdapter(SkillNodeAdapter());
  }
  if (!Hive.isAdapterRegistered(4)) {
    Hive.registerAdapter(AchievementAdapter());
  }
  if (!Hive.isAdapterRegistered(5)) {
    Hive.registerAdapter(LevelProgressDataAdapter());
  }

  await Future.wait([
    Hive.openBox<dynamic>(HiveBoxes.settings),
    Hive.openBox<LevelProgressData>(HiveBoxes.gameProgress),
    Hive.openBox<PlayerProfile>(HiveBoxes.playerProfile),
    Hive.openBox<GameSessionState>(HiveBoxes.sessionState),
    Hive.openBox<Achievement>(HiveBoxes.achievements),
  ]);

  runApp(const ProviderScope(child: NullbyteApp()));
}
