import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nullbyte/core/theme/app_theme.dart';
import 'package:nullbyte/features/active_session/providers/game_session_provider.dart';

/// Menampilkan elapsed time sesi aktif dalam format MM:SS.
/// Watch [elapsedSecondsProvider] dan rebuild setiap detik.
class TimerWidget extends ConsumerWidget {
  const TimerWidget({super.key});

  String _format(int seconds) {
    final mm = (seconds ~/ 60).toString().padLeft(2, '0');
    final ss = (seconds % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final elapsed = ref.watch(elapsedSecondsProvider);
    return Text(
      _format(elapsed),
      style: const TextStyle(
        fontFamily: 'SpaceMono',
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppTheme.primaryContainer,
        letterSpacing: 0.1,
        shadows: [
          Shadow(color: AppTheme.primaryContainer, blurRadius: 8),
          Shadow(color: AppTheme.primaryContainer, blurRadius: 16),
        ],
      ),
    );
  }
}
