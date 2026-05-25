import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nullbyte/core/constants/app_constants.dart';
import 'package:nullbyte/core/theme/app_theme.dart';
import 'package:nullbyte/features/auth/data/auth_provider.dart';
import 'package:nullbyte/shared/providers/audio_manager.dart';
import 'package:nullbyte/shared/providers/progression_summary_provider.dart';
import 'package:nullbyte/shared/widgets/scanline_overlay.dart';

class MainMenuScreen extends ConsumerStatefulWidget {
  const MainMenuScreen({super.key});

  @override
  ConsumerState<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends ConsumerState<MainMenuScreen> {
  late Timer _uptimeTimer;
  int _uptimeSeconds = 0;

  @override
  void initState() {
    super.initState();
    _startUptime();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(audioManagerProvider).playBgm(AppConstants.bgmMainMenu);
    });
  }

  void _startUptime() {
    _uptimeTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _uptimeSeconds++);
      }
    });
  }

  String get _uptimeFormatted {
    final h = (_uptimeSeconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((_uptimeSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (_uptimeSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  void dispose() {
    _uptimeTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final currentUsername = currentUser?.username ?? 'GUEST_OPERATOR';
    final sessionLabel = currentUser?.isGuest ?? true
        ? 'GUEST_SESSION'
        : 'REGISTERED_OPERATOR';
    final summaryAsync = ref.watch(progressionSummaryProvider);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: _buildAppBar(),
      body: ScanlineOverlay(
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _GridPainter())),
            SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroSection(),
                    const SizedBox(height: 24),
                    _buildPrimaryCard(
                      currentUsername: currentUsername,
                      sessionLabel: sessionLabel,
                      summaryAsync: summaryAsync,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoGrid(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.surface,
      elevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(2),
        child: Container(height: 2, color: AppTheme.surfaceContainerHigh),
      ),
      title: Row(
        children: [
          const Icon(
            Icons.signal_cellular_alt,
            color: AppTheme.primaryContainer,
            size: 20,
          ),
          const SizedBox(width: 8),
          const Text(
            'NULLBYTE',
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: AppTheme.primaryContainer,
              letterSpacing: -0.5,
              shadows: [Shadow(color: Color(0x8000FF41), blurRadius: 8)],
            ),
          ),
        ],
      ),
      actions: [
        _buildUptimeWidget(),
        const SizedBox(width: 12),
        Container(width: 1, height: 32, color: AppTheme.surfaceContainerHigh),
        const SizedBox(width: 12),
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppTheme.primaryContainer,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              'SYSTEM_ACTIVE',
              style: TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 9,
                color: AppTheme.primaryContainer,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildUptimeWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text(
          'UPTIME',
          style: TextStyle(
            fontFamily: 'SpaceMono',
            fontSize: 9,
            color: Color(0x9900FF41),
            letterSpacing: 2,
          ),
        ),
        Text(
          _uptimeFormatted,
          style: const TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: AppTheme.primaryContainer,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroSection() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLow,
          border: Border.all(
            color: AppTheme.primaryContainer.withValues(alpha: 0.15),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryContainer.withValues(alpha: 0.03),
              blurRadius: 16,
              spreadRadius: 2,
            )
          ],
        ),
        child: Image.asset(
          'assets/images/logo.png',
          width: 96,
          height: 96,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildPrimaryCard({
    required String currentUsername,
    required String sessionLabel,
    required AsyncValue<ProgressionSummary> summaryAsync,
  }) {
    return Container(
      width: double.infinity,
      color: AppTheme.surfaceContainerLowest,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(width: 4, color: AppTheme.primaryContainer),
          ),
          Positioned(
            right: 16,
            top: 16,
            child: Opacity(
              opacity: 0.06,
              child: const Icon(
                Icons.terminal,
                size: 120,
                color: AppTheme.primaryContainer,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      color: AppTheme.primaryContainer,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'MISSION_LOOP_READY',
                      style: TextStyle(
                        fontFamily: 'SpaceMono',
                        fontSize: 10,
                        color: AppTheme.primaryContainer,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.go('/mission'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryContainer,
                      foregroundColor: AppTheme.onPrimary,
                      shape: const RoundedRectangleBorder(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 20,
                      ),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'START MISSION',
                          style: TextStyle(
                            fontFamily: 'SpaceGrotesk',
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Icon(Icons.chevron_right, size: 28),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 32,
                  runSpacing: 12,
                  children: [
                    _buildInfoItem(
                      label: 'CURRENT_USER',
                      icon: Icons.person,
                      value: currentUsername.toUpperCase(),
                      valueColor: AppTheme.primaryContainer,
                    ),
                    _buildInfoItem(
                      label: 'SESSION_TYPE',
                      value: sessionLabel,
                      valueColor: AppTheme.secondaryContainer,
                    ),
                    _buildInfoItem(
                      label: 'V1_LOOP',
                      value: 'MISSION > PLAY > FLAG > UNLOCK',
                      valueColor: AppTheme.onSurface.withValues(alpha: 0.75),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildProgressSummary(summaryAsync),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSummary(AsyncValue<ProgressionSummary> summaryAsync) {
    return summaryAsync.when(
      data: (summary) => Container(
        width: double.infinity,
        color: AppTheme.surfaceContainerHigh,
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 24,
          runSpacing: 8,
          children: [
            _buildInfoItem(
              label: 'LEVELS_CLEARED',
              value: summary.levelsCompleted.toString().padLeft(2, '0'),
              valueColor: AppTheme.primaryContainer,
            ),
            _buildInfoItem(
              label: 'TOTAL_STARS',
              value: summary.totalStars.toString().padLeft(2, '0'),
              valueColor: AppTheme.secondaryContainer,
            ),
            _buildInfoItem(
              label: 'TOTAL_SCORE',
              value: summary.totalScore.toString(),
              valueColor: AppTheme.tertiaryContainer,
            ),
          ],
        ),
      ),
      loading: () => Container(
        width: double.infinity,
        color: AppTheme.surfaceContainerHigh,
        padding: const EdgeInsets.all(12),
        child: const Text(
          'LOADING LOCAL PROGRESSION...',
          style: TextStyle(
            fontFamily: 'JetBrainsMono',
            fontSize: 11,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
      ),
      error: (_, __) => Container(
        width: double.infinity,
        color: AppTheme.surfaceContainerHigh,
        padding: const EdgeInsets.all(12),
        child: const Text(
          'LOCAL PROGRESSION UNAVAILABLE',
          style: TextStyle(
            fontFamily: 'JetBrainsMono',
            fontSize: 11,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoGrid() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _buildSecondaryCard(
              icon: Icons.route,
              iconColor: AppTheme.secondaryContainer,
              label: 'Mission Flow',
              title: 'Three Missions',
              subtitle:
                  'Network Recon, Web Exploitation, dan Privilege Escalation sebagai kurikulum utama.',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildSecondaryCard(
              icon: Icons.flag,
              iconColor: AppTheme.tertiaryContainer,
              label: 'Progression',
              title: 'Real Unlocks',
              subtitle:
                  'Score, stars, profile stats, dan unlock level sekarang mengikuti progress lokal yang nyata.',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required String label,
    IconData? icon,
    required String value,
    required Color valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'SpaceMono',
            fontSize: 9,
            color: AppTheme.onSurfaceVariant,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: valueColor),
              const SizedBox(width: 4),
            ],
            Text(
              value,
              style: TextStyle(
                fontFamily: 'JetBrainsMono',
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: valueColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSecondaryCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String title,
    required String subtitle,
  }) {
    return Container(
      color: AppTheme.surfaceContainerHigh,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: iconColor, size: 24),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'SpaceMono',
                  fontSize: 9,
                  color: iconColor,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: AppTheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 9,
              color: AppTheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x0800FF41)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const step = 32.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => false;
}
