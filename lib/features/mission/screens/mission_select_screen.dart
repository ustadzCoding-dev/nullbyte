import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nullbyte/core/constants/app_constants.dart';
import 'package:nullbyte/core/theme/app_theme.dart';
import 'package:nullbyte/features/mission/providers/mission_provider.dart';
import 'package:nullbyte/shared/providers/audio_manager.dart';
import 'package:nullbyte/shared/widgets/scanline_overlay.dart';

class _MissionPresentation {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Offset position;

  const _MissionPresentation({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.position,
  });
}

class _MissionViewData {
  final _MissionPresentation presentation;
  final bool isLocked;
  final bool isActive;
  final int stars;
  final int completedLevels;
  final int totalLevels;
  final int difficulty;
  final String? launchLevelId;

  const _MissionViewData({
    required this.presentation,
    required this.isLocked,
    required this.isActive,
    required this.stars,
    required this.completedLevels,
    required this.totalLevels,
    required this.difficulty,
    required this.launchLevelId,
  });
}

const _presentations = [
  _MissionPresentation(
    id: 'mission_1',
    title: 'NETWORK RECON',
    subtitle: 'ZERO DAY',
    description:
        'Mission pembuka untuk membangun ritme bermain. Mulai dari host discovery, port scan, service fingerprint, hingga ambil flag pertama.',
    icon: Icons.radar,
    position: Offset(0.15, 0.30),
  ),
  _MissionPresentation(
    id: 'mission_2',
    title: 'WEB EXPLOITATION',
    subtitle: 'BREACH VECTOR',
    description:
        'Masuk ke jalur web: endpoint discovery, SQL injection, auth bypass, file upload abuse, dan foothold ringan.',
    icon: Icons.language,
    position: Offset(0.45, 0.18),
  ),
  _MissionPresentation(
    id: 'mission_3',
    title: 'PRIVILEGE ESCALATION',
    subtitle: 'ROOT ACCESS',
    description:
        'Dari foothold menuju root: enumeration, sudo misconfig, privilege escalation, dan final flag.',
    icon: Icons.admin_panel_settings,
    position: Offset(0.52, 0.52),
  ),
];

class MissionSelectScreen extends ConsumerStatefulWidget {
  const MissionSelectScreen({super.key});

  @override
  ConsumerState<MissionSelectScreen> createState() =>
      _MissionSelectScreenState();
}

class _MissionSelectScreenState extends ConsumerState<MissionSelectScreen> {
  int _selectedIndex = 0;
  bool _isLevelsExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(audioManagerProvider).playBgm(AppConstants.bgmMainMenu);
      final notifier = ref.read(missionProvider.notifier);
      await notifier.loadMission('mission_1');
      await notifier.loadMission('mission_2');
      await notifier.loadMission('mission_3');
      await notifier.refreshProgress();
    });
  }

  void _onNodeTap(int index) {
    setState(() {
      _selectedIndex = index;
      _isLevelsExpanded = false;
    });
    ref.read(audioManagerProvider).playSfx(AppConstants.sfxButtonTap);
  }

  void _executeMission(List<_MissionViewData> missions) {
    final mission = missions[_selectedIndex];
    if (mission.isLocked || mission.launchLevelId == null) return;
    ref.read(audioManagerProvider).playSfx(AppConstants.sfxButtonTap);
    context.go('/session/${mission.launchLevelId}');
  }

  void _showLockedDialog(BuildContext context, _MissionViewData mission) {
    ref.read(audioManagerProvider).playSfx(AppConstants.sfxCommandError);

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: ScanlineOverlay(
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              border: Border.all(color: AppTheme.error, width: 2),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.gpp_bad,
                      color: AppTheme.error,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ACCESS RESTRICTED',
                            style: TextStyle(
                              fontFamily: 'SpaceGrotesk',
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              color: AppTheme.error,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'PROTOCOL: DECRYPT_VECTOR_FAIL',
                            style: TextStyle(
                              fontFamily: 'SpaceMono',
                              fontSize: 9,
                              color: AppTheme.error.withValues(alpha: 0.7),
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLowest,
                    border: Border.all(
                      color: AppTheme.error.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '// ERROR: ACCESS_DENIED',
                        style: TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: AppTheme.error,
                        ),
                      ),
                      Text(
                        '// TARGET_ID: ${mission.presentation.id.toUpperCase()}',
                        style: TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: 10,
                          color: AppTheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                      Text(
                        '// FIREWALL_STATUS: CLASSIFIED_ACTIVE',
                        style: TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: 10,
                          color: AppTheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        mission.presentation.id == 'mission_2'
                            ? 'Vector "Web Exploitation" terenkripsi oleh firewall eksternal target. Selesaikan "Mission 1: Network Recon" secara penuh untuk memperoleh otorisasi bypass gateway.'
                            : 'Akses root internal dikunci di bawah protokol pertahanan militer. Selesaikan seluruh target di "Mission 2: Web Exploitation" untuk meretas rantai credential.',
                        style: TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: 11,
                          color: AppTheme.onSurface.withValues(alpha: 0.85),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.error,
                    foregroundColor: AppTheme.surface,
                    shape: const RoundedRectangleBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  child: const Text(
                    'DISMISS WARNING',
                    style: TextStyle(
                      fontFamily: 'SpaceMono',
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 600;
    final missionState = ref.watch(missionProvider);
    final notifier = ref.read(missionProvider.notifier);
    final allRequiredMissionsLoaded = notifier.areMissionsLoaded(
      _presentations.map((mission) => mission.id),
    );

    if (missionState.isLoading || !allRequiredMissionsLoaded) {
      return Scaffold(
        backgroundColor: AppTheme.surfaceContainerLowest,
        appBar: _buildAppBar(),
        body: ScanlineOverlay(
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppTheme.primaryContainer),
                SizedBox(height: 14),
                Text(
                  'SYNCING MISSION DIRECTORY...',
                  style: TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 10,
                    color: AppTheme.primaryContainer,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final missions = _buildMissionData();
    final selectedIndex = _selectedIndex.clamp(0, missions.length - 1);

    return Scaffold(
      backgroundColor: AppTheme.surfaceContainerLowest,
      appBar: _buildAppBar(),
      body: ScanlineOverlay(
        child: isWide
            ? _buildWideLayout(missions, selectedIndex)
            : _buildMobileLayout(missions, selectedIndex),
      ),
    );
  }

  List<_MissionViewData> _buildMissionData() {
    final notifier = ref.read(missionProvider.notifier);

    final activeMissionId = _presentations
        .map((presentation) => presentation.id)
        .firstWhere(
          (missionId) =>
              notifier.isMissionUnlocked(missionId) &&
              !notifier.isMissionCompleted(missionId),
          orElse: () => 'mission_1',
        );

    return _presentations.map((presentation) {
      final levels = notifier.getLevelsForMission(presentation.id);
      final launchLevelId = notifier.getCurrentPlayableLevelId(presentation.id);
      final difficulty = levels.isEmpty
          ? 1
          : levels
                .map((level) => level.difficulty)
                .fold<int>(
                  0,
                  (maxDifficulty, value) => math.max(maxDifficulty, value),
                );

      return _MissionViewData(
        presentation: presentation,
        isLocked: !notifier.isMissionUnlocked(presentation.id),
        isActive: presentation.id == activeMissionId,
        stars: notifier.getMissionStars(presentation.id),
        completedLevels: notifier.getCompletedLevelsCount(presentation.id),
        totalLevels: levels.length,
        difficulty: difficulty,
        launchLevelId: launchLevelId,
      );
    }).toList();
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
        children: const [
          Icon(
            Icons.signal_cellular_alt,
            color: AppTheme.primaryContainer,
            size: 20,
          ),
          SizedBox(width: 8),
          Text(
            'MISSION_SELECT',
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
    );
  }

  Widget _buildWideLayout(List<_MissionViewData> missions, int selectedIndex) {
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _NetworkTopologyPainter(
              nodePositions: _presentations.map((m) => m.position).toList(),
              color: AppTheme.tertiaryContainer.withValues(alpha: 0.4),
            ),
          ),
        ),
        ...List.generate(
          missions.length,
          (i) => _PositionedNode(
            fraction: _presentations[i].position,
            child: _buildMissionNode(missions, selectedIndex, i),
          ),
        ),
        Positioned(
          bottom: 24,
          right: 24,
          child: _buildFloatingHud(missions, selectedIndex, width: 340),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(
    List<_MissionViewData> missions,
    int selectedIndex,
  ) {
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            itemCount: missions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) =>
                _buildMobileNodeCard(missions, selectedIndex, i),
          ),
        ),
        _buildFloatingHud(missions, selectedIndex, width: double.infinity),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildMobileNodeCard(
    List<_MissionViewData> missions,
    int selectedIndex,
    int index,
  ) {
    final mission = missions[index];
    final isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: mission.isLocked
          ? () => _showLockedDialog(context, mission)
          : () => _onNodeTap(index),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: mission.isLocked ? 0.5 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: mission.isActive
                ? AppTheme.primaryContainer.withValues(alpha: 0.12)
                : AppTheme.surfaceContainerHigh,
            border: Border.all(
              color: isSelected
                  ? AppTheme.primaryContainer
                  : mission.isActive
                  ? AppTheme.primaryContainer.withValues(alpha: 0.5)
                  : AppTheme.outlineVariant,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                color: mission.isActive
                    ? AppTheme.primaryContainer
                    : AppTheme.surfaceContainerHighest,
                child: Icon(
                  mission.isLocked ? Icons.lock : mission.presentation.icon,
                  color: mission.isActive
                      ? AppTheme.onPrimary
                      : mission.isLocked
                      ? AppTheme.outline
                      : AppTheme.tertiaryContainer,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mission.presentation.title,
                      style: TextStyle(
                        fontFamily: 'SpaceMono',
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        color: mission.isActive
                            ? AppTheme.primaryContainer
                            : mission.isLocked
                            ? AppTheme.outline
                            : AppTheme.onSurface,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      mission.presentation.subtitle,
                      style: const TextStyle(
                        fontFamily: 'SpaceMono',
                        fontSize: 9,
                        color: AppTheme.onSurfaceVariant,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${mission.completedLevels}/${mission.totalLevels}',
                style: const TextStyle(
                  fontFamily: 'SpaceMono',
                  fontSize: 10,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMissionNode(
    List<_MissionViewData> missions,
    int selectedIndex,
    int index,
  ) {
    final mission = missions[index];
    final isSelected = selectedIndex == index;
    final nodeSize = mission.isActive ? 48.0 : 40.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: mission.isLocked
              ? () => _showLockedDialog(context, mission)
              : () => _onNodeTap(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: nodeSize,
            height: nodeSize,
            decoration: BoxDecoration(
              color: mission.isActive
                  ? AppTheme.primaryContainer
                  : AppTheme.surfaceContainerHigh,
              border: Border.all(
                color: isSelected
                    ? AppTheme.primaryContainer
                    : mission.isActive
                    ? AppTheme.primaryFixed
                    : AppTheme.outlineVariant,
                width: 2,
              ),
              boxShadow: mission.isActive || isSelected
                  ? [
                      BoxShadow(
                        color: AppTheme.primaryContainer.withValues(alpha: 0.4),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Opacity(
              opacity: mission.isLocked ? 0.5 : 1.0,
              child: Icon(
                mission.isLocked ? Icons.lock : mission.presentation.icon,
                color: mission.isActive
                    ? AppTheme.onPrimary
                    : mission.isLocked
                    ? AppTheme.outline
                    : AppTheme.tertiaryContainer,
                size: mission.isActive ? 24 : 20,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 140,
          child: Text(
            mission.presentation.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'SpaceMono',
              fontWeight: FontWeight.w700,
              fontSize: 9,
              color: mission.isActive
                  ? AppTheme.primaryContainer
                  : mission.isLocked
                  ? AppTheme.outline
                  : AppTheme.onSurfaceVariant,
              letterSpacing: 0.5,
              shadows: mission.isActive
                  ? const [Shadow(color: Color(0x8000FF41), blurRadius: 5)]
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingHud(
    List<_MissionViewData> missions,
    int selectedIndex, {
    required double width,
  }) {
    final mission = missions[selectedIndex];
    final notifier = ref.read(missionProvider.notifier);
    final levels = notifier.getLevelsForMission(mission.presentation.id);
    final missionState = ref.read(missionProvider);

    return Container(
      width: width,
      margin: width == double.infinity
          ? const EdgeInsets.symmetric(horizontal: 16)
          : EdgeInsets.zero,
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerHigh.withValues(alpha: 0.95),
        border: const Border(
          left: BorderSide(color: AppTheme.primaryContainer, width: 4),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mission.presentation.title,
                      style: const TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        color: AppTheme.onSurface,
                        letterSpacing: -0.5,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mission.presentation.subtitle,
                      style: TextStyle(
                        fontFamily: 'SpaceMono',
                        fontSize: 9,
                        color: AppTheme.primaryContainer.withValues(alpha: 0.8),
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                color: AppTheme.surfaceContainerHighest,
                child: Icon(
                  mission.presentation.icon,
                  color: AppTheme.primaryContainer,
                  size: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              border: Border.symmetric(
                horizontal: BorderSide(
                  color: AppTheme.outlineVariant.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  'DIFFICULTY',
                  style: TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 9,
                    color: AppTheme.onSurfaceVariant,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(width: 12),
                ...List.generate(3, (i) {
                  final filled = i < mission.difficulty;
                  return Container(
                    width: 24,
                    height: 8,
                    margin: const EdgeInsets.only(right: 4),
                    color: filled
                        ? AppTheme.primaryContainer
                        : AppTheme.surfaceContainerHighest,
                  );
                }),
                const Spacer(),
                Text(
                  '${mission.completedLevels}/${mission.totalLevels} LEVELS CLEARED',
                  style: const TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 9,
                    color: AppTheme.onSurfaceVariant,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'MISSION_RATING',
                style: TextStyle(
                  fontFamily: 'SpaceMono',
                  fontSize: 9,
                  color: AppTheme.onSurfaceVariant,
                  letterSpacing: 1,
                ),
              ),
              Row(
                children: List.generate(3, (i) {
                  final filled = i < mission.stars;
                  return Icon(
                    filled ? Icons.star : Icons.star_border,
                    color: AppTheme.primaryContainer,
                    size: 18,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Collapsible Levels Dropdown
          GestureDetector(
            onTap: () {
              setState(() => _isLevelsExpanded = !_isLevelsExpanded);
              ref.read(audioManagerProvider).playSfx(AppConstants.sfxButtonTap);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                border: Border.all(
                  color: _isLevelsExpanded
                      ? AppTheme.primaryContainer
                      : AppTheme.outlineVariant,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        _isLevelsExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: AppTheme.primaryContainer,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'LEVELS DIRECTORY',
                        style: TextStyle(
                          fontFamily: 'SpaceMono',
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryContainer,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${mission.completedLevels}/${mission.totalLevels} VECTOR(S)',
                    style: const TextStyle(
                      fontFamily: 'SpaceMono',
                      fontSize: 9,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLevelsExpanded) ...[
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 180),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                border: Border.all(
                  color: AppTheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.all(8),
                itemCount: levels.length,
                separatorBuilder: (_, __) => Divider(
                  color: AppTheme.outlineVariant.withValues(alpha: 0.3),
                  height: 12,
                ),
                itemBuilder: (context, i) {
                  final level = levels[i];
                  final isCompleted = missionState.progress[level.id]?.isCompleted ?? false;
                  final isUnlocked = notifier.isLevelUnlocked(level.id);
                  final levelStars = missionState.progress[level.id]?.starsEarned ?? 0;

                  return InkWell(
                    onTap: isUnlocked && !mission.isLocked
                        ? () {
                            ref.read(audioManagerProvider).playSfx(AppConstants.sfxButtonTap);
                            context.go('/session/${level.id}');
                          }
                        : () {
                            ref.read(audioManagerProvider).playSfx(AppConstants.sfxCommandError);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  !isUnlocked
                                      ? '[RESTRICTED] LEVEL ${i + 1} MASIH TERKUNCI. SELESAIKAN LEVEL SEBELUMNYA.'
                                      : '[RESTRICTED] SEKTOR MISI UTAMA MASIH TERKUNCI.',
                                ),
                              ),
                            );
                          },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            color: isCompleted
                                ? AppTheme.primaryContainer.withValues(alpha: 0.15)
                                : AppTheme.surfaceContainerHigh,
                            child: Center(
                              child: Icon(
                                !isUnlocked
                                    ? Icons.lock
                                    : isCompleted
                                        ? Icons.check
                                        : Icons.radar,
                                size: 11,
                                color: !isUnlocked
                                    ? AppTheme.outline
                                    : isCompleted
                                        ? AppTheme.primaryContainer
                                        : AppTheme.tertiaryContainer,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'LEVEL ${i + 1}: ${level.title.toUpperCase()}',
                                  style: TextStyle(
                                    fontFamily: 'SpaceMono',
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: !isUnlocked
                                        ? AppTheme.outline
                                        : AppTheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'RECOMMENDED: ${level.recommendedTools.join(", ").toUpperCase()}',
                                  style: TextStyle(
                                    fontFamily: 'SpaceMono',
                                    fontSize: 8,
                                    color: AppTheme.onSurfaceVariant.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isCompleted)
                            Row(
                              children: List.generate(3, (starIdx) {
                                return Icon(
                                  starIdx < levelStars ? Icons.star : Icons.star_border,
                                  color: AppTheme.primaryContainer,
                                  size: 10,
                                );
                              }),
                            )
                          else if (!isUnlocked)
                            const Text(
                              'LOCKED',
                              style: TextStyle(
                                fontFamily: 'SpaceMono',
                                fontSize: 8,
                                color: AppTheme.outline,
                              ),
                            )
                          else
                            const Text(
                              'READY',
                              style: TextStyle(
                                fontFamily: 'SpaceMono',
                                fontSize: 8,
                                color: AppTheme.tertiaryContainer,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 16),
          GestureDetector(
            onTap: mission.isLocked
                ? () => _showLockedDialog(context, mission)
                : null,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: mission.isLocked
                    ? null
                    : () => _executeMission(missions),
                style: ElevatedButton.styleFrom(
                  backgroundColor: mission.isLocked
                      ? AppTheme.surfaceContainerHighest
                      : AppTheme.primaryContainer,
                  foregroundColor: mission.isLocked
                      ? AppTheme.outline
                      : AppTheme.onPrimary,
                  disabledBackgroundColor: AppTheme.surfaceContainerHighest,
                  disabledForegroundColor: AppTheme.outline,
                  shape: const RoundedRectangleBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                child: Text(
                  mission.isLocked
                      ? 'LOCKED - COMPLETE PREVIOUS MISSION'
                      : 'START ${mission.presentation.title}',
                  style: const TextStyle(
                    fontFamily: 'SpaceMono',
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    letterSpacing: 2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            mission.presentation.description,
            style: TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 9,
              color: AppTheme.onSurfaceVariant.withValues(alpha: 0.7),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _PositionedNode extends StatelessWidget {
  const _PositionedNode({required this.fraction, required this.child});

  final Offset fraction;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final left = constraints.maxWidth * fraction.dx;
          final top = constraints.maxHeight * fraction.dy;
          return Stack(
            children: [
              Positioned(left: left - 60, top: top - 30, child: child),
            ],
          );
        },
      ),
    );
  }
}

class _NetworkTopologyPainter extends CustomPainter {
  final List<Offset> nodePositions;
  final Color color;

  const _NetworkTopologyPainter({
    required this.nodePositions,
    required this.color,
  });

  static const _connections = [(0, 1), (1, 2)];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    const dashLen = 8.0;
    const gapLen = 4.0;

    for (final (fromIdx, toIdx) in _connections) {
      final from = Offset(
        nodePositions[fromIdx].dx * size.width,
        nodePositions[fromIdx].dy * size.height,
      );
      final to = Offset(
        nodePositions[toIdx].dx * size.width,
        nodePositions[toIdx].dy * size.height,
      );
      _drawDashedLine(canvas, paint, from, to, dashLen, gapLen);
    }
  }

  void _drawDashedLine(
    Canvas canvas,
    Paint paint,
    Offset from,
    Offset to,
    double dashLen,
    double gapLen,
  ) {
    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;
    final dist = math.sqrt(dx * dx + dy * dy);
    if (dist == 0) return;

    final ux = dx / dist;
    final uy = dy / dist;

    double traveled = 0;
    bool drawing = true;

    while (traveled < dist) {
      final segLen = drawing ? dashLen : gapLen;
      final end = math.min(traveled + segLen, dist);
      if (drawing) {
        canvas.drawLine(
          Offset(from.dx + ux * traveled, from.dy + uy * traveled),
          Offset(from.dx + ux * end, from.dy + uy * end),
          paint,
        );
      }
      traveled = end;
      drawing = !drawing;
    }
  }

  @override
  bool shouldRepaint(_NetworkTopologyPainter old) =>
      old.nodePositions != nodePositions || old.color != color;
}
