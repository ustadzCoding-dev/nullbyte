import 'package:flutter/material.dart';

/// App-wide constants for NULLBYTE.
abstract final class AppConstants {
  AppConstants._();

  static const String appName = 'NULLBYTE';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';
  static const String appTagline = 'HACK THE SYSTEM. LEARN THE TRUTH.';

  static const Color colorPrimary = Color(0xFF00FF41);
  static const Color colorPrimaryFixed = Color(0xFF72FF70);
  static const Color colorSecondary = Color(0xFFFDAF00);
  static const Color colorTertiary = Color(0xFF1DF3FF);
  static const Color colorSurface = Color(0xFF131313);
  static const Color colorSurfaceLowest = Color(0xFF0E0E0E);
  static const Color colorSurfaceLow = Color(0xFF1C1B1B);
  static const Color colorSurfaceContainer = Color(0xFF201F1F);
  static const Color colorSurfaceHigh = Color(0xFF2A2A2A);
  static const Color colorSurfaceHighest = Color(0xFF353534);
  static const Color colorOnSurface = Color(0xFFE5E2E1);
  static const Color colorOnSurfaceVariant = Color(0xFFB9CCB2);
  static const Color colorOutline = Color(0xFF84967E);
  static const Color colorOutlineVariant = Color(0xFF3B4B37);
  static const Color colorError = Color(0xFFFFB4AB);

  static const String bgmMainMenu = 'assets/audio/bgm/main_menu_theme.ogg';
  static const String bgmMission1 = 'assets/audio/bgm/mission_1_theme.ogg';
  static const String bgmMission2 = 'assets/audio/bgm/mission_2_theme.ogg';
  static const String bgmMission3 = 'assets/audio/bgm/mission_3_theme.ogg';

  static const String sfxKeypress = 'assets/audio/sfx/typing.ogg';
  static const String sfxFlagCaptured = 'assets/audio/sfx/flag_captured.ogg';
  static const String sfxCommandError = 'assets/audio/sfx/command_error.ogg';
  static const String sfxScanRunning = 'assets/audio/sfx/scan_running.ogg';
  static const String sfxNodeDiscovered =
      'assets/audio/sfx/node_discovered.ogg';
  static const String sfxButtonTap = 'assets/audio/sfx/button_tap.ogg';
  static const String sfxAchievementUnlock =
      'assets/audio/sfx/achievement_unlock.ogg';

  static const String fontSpaceGrotesk = 'SpaceGrotesk';
  static const String fontJetBrainsMono = 'JetBrainsMono';
  static const String fontSpaceMono = 'SpaceMono';

  static const String dataMission1 = 'assets/data/levels/mission_1.json';
  static const String dataMission2 = 'assets/data/levels/mission_2.json';
  static const String dataMission3 = 'assets/data/levels/mission_3.json';
  static const String dataAchievements = 'assets/data/achievements.json';
  static const String dataDictionary = 'assets/data/dictionary.json';

  static const int scoreBase = 1000;
  static const int scoreTimeBonusMax = 500;
  static const int scoreHintPenalty = 100;
  static const int scoreFailPenalty = 50;
  static const int scoreNoHintBonus = 200;
  static const int scoreStarThreshold3 = 1500;
  static const int scoreStarThreshold2 = 1000;

  static const int maxHintsPerLevel = 3;
  static const double netMapZoomMin = 0.5;
  static const double netMapZoomMax = 3.0;

  static const Duration commandTimeout = Duration(milliseconds: 500);
}
