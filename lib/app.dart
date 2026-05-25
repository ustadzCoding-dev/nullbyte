import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nullbyte/core/constants/app_constants.dart';
import 'package:nullbyte/core/router/app_router.dart';
import 'package:nullbyte/core/theme/app_theme.dart';
import 'package:nullbyte/features/achievements/providers/achievement_provider.dart';
import 'package:nullbyte/features/settings/data/settings_preferences.dart';
import 'package:nullbyte/shared/providers/audio_manager.dart';

class NullbyteApp extends ConsumerWidget {
  const NullbyteApp({super.key});

  static final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    ref.listen(settingsPreferencesProvider, (_, next) {
      next.whenData((prefs) {
        final audio = ref.read(audioManagerProvider);
        audio.setBgmVolume(prefs.masterGain);
        audio.setSfxVolume(prefs.interfaceSfxGain);
      });
    });
    ref.listen<AchievementState>(achievementProvider, (previous, next) async {
      final pending = next.pendingUnlock;
      if (pending == null || identical(previous?.pendingUnlock, pending)) {
        return;
      }

      await ref.read(audioManagerProvider).playSfx(
            AppConstants.sfxAchievementUnlock,
          );

      final messenger = scaffoldMessengerKey.currentState;
      if (messenger != null) {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              duration: const Duration(seconds: 4),
              backgroundColor: AppTheme.surfaceContainerHigh,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ACHIEVEMENT UNLOCKED',
                    style: TextStyle(
                      fontFamily: 'SpaceMono',
                      fontSize: 10,
                      color: AppTheme.primaryContainer,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pending.title,
                    style: const TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    pending.description,
                    style: const TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 11,
                      color: AppTheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          );
      }

      ref.read(achievementProvider.notifier).clearPendingUnlock();
    });

    return MaterialApp.router(
      title: 'NULLBYTE',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: scaffoldMessengerKey,
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
