import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nullbyte/core/theme/app_theme.dart';
import 'package:nullbyte/features/achievements/providers/achievement_provider.dart';
import 'package:nullbyte/shared/models/achievement.dart';
import 'package:nullbyte/shared/providers/progression_summary_provider.dart';
import 'package:nullbyte/shared/widgets/scanline_overlay.dart';

class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key});

  @override
  ConsumerState<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(achievementProvider.notifier).loadAchievements();
    });
  }

  @override
  Widget build(BuildContext context) {
    final achievementState = ref.watch(achievementProvider);
    final summaryAsync = ref.watch(progressionSummaryProvider);
    final achievements = achievementState.achievements.values.toList()
      ..sort((a, b) {
        if (a.isUnlocked != b.isUnlocked) {
          return a.isUnlocked ? -1 : 1;
        }
        return a.title.compareTo(b.title);
      });

    final unlockedCount = achievements.where((a) => a.isUnlocked).length;

    return ScanlineOverlay(
      child: Scaffold(
        backgroundColor: AppTheme.surface,
        appBar: AppBar(
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
                'ACHIEVEMENT_ARCHIVE',
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
        ),
        body: Column(
          children: [
            _ArchiveHeader(
              totalCount: achievements.length,
              unlockedCount: unlockedCount,
              summaryAsync: summaryAsync,
            ),
            Expanded(
              child: achievements.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryContainer,
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      itemCount: achievements.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        return _AchievementCard(achievement: achievements[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArchiveHeader extends StatelessWidget {
  const _ArchiveHeader({
    required this.totalCount,
    required this.unlockedCount,
    required this.summaryAsync,
  });

  final int totalCount;
  final int unlockedCount;
  final AsyncValue<ProgressionSummary> summaryAsync;

  @override
  Widget build(BuildContext context) {
    final lockedCount = (totalCount - unlockedCount).clamp(0, totalCount);

    return Container(
      width: double.infinity,
      color: AppTheme.surfaceContainerLow,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'UNLOCK_PROGRESS',
            style: TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 10,
              color: AppTheme.primaryContainer,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 24,
            runSpacing: 10,
            children: [
              _HeaderItem(
                label: 'UNLOCKED',
                value: unlockedCount.toString().padLeft(2, '0'),
                color: AppTheme.primaryContainer,
              ),
              _HeaderItem(
                label: 'LOCKED',
                value: lockedCount.toString().padLeft(2, '0'),
                color: AppTheme.secondaryContainer,
              ),
              summaryAsync.maybeWhen(
                data: (summary) => _HeaderItem(
                  label: 'LEVELS_CLEARED',
                  value: summary.levelsCompleted.toString().padLeft(2, '0'),
                  color: AppTheme.tertiaryContainer,
                ),
                orElse: () => const _HeaderItem(
                  label: 'LEVELS_CLEARED',
                  value: '--',
                  color: AppTheme.tertiaryContainer,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderItem extends StatelessWidget {
  const _HeaderItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'SpaceMono',
            fontSize: 9,
            color: AppTheme.onSurfaceVariant,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.achievement});

  final Achievement achievement;

  @override
  Widget build(BuildContext context) {
    final isUnlocked = achievement.isUnlocked;
    final isSecret = achievement.isSecret;
    final lockedTitle = isSecret ? '???' : achievement.title;
    final lockedDescription = isSecret
        ? 'Achievement ini masih tersembunyi. Teruskan progression untuk mengungkapnya.'
        : achievement.description;

    return Container(
      decoration: BoxDecoration(
        color: isUnlocked
            ? AppTheme.primaryContainer.withValues(alpha: 0.10)
            : AppTheme.surfaceContainerLow,
        border: Border.all(
          color: isUnlocked
              ? AppTheme.primaryContainer
              : AppTheme.outlineVariant,
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            color: isUnlocked
                ? AppTheme.primaryContainer
                : AppTheme.surfaceContainerHighest,
            child: Icon(
              isUnlocked ? Icons.workspace_premium : Icons.lock,
              color: isUnlocked ? AppTheme.onPrimary : AppTheme.outline,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        isUnlocked ? achievement.title : lockedTitle,
                        style: TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: isUnlocked
                              ? AppTheme.primaryContainer
                              : AppTheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '+${achievement.bonusPoints} XP',
                      style: const TextStyle(
                        fontFamily: 'SpaceMono',
                        fontSize: 10,
                        color: AppTheme.secondaryContainer,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  isUnlocked ? achievement.description : lockedDescription,
                  style: const TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 11,
                    color: AppTheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  children: [
                    _TagChip(
                      label: isUnlocked ? 'UNLOCKED' : 'LOCKED',
                      color: isUnlocked
                          ? AppTheme.primaryContainer
                          : AppTheme.outline,
                    ),
                    _TagChip(
                      label: isSecret ? 'SECRET' : 'VISIBLE',
                      color: isSecret
                          ? AppTheme.secondaryContainer
                          : AppTheme.tertiaryContainer,
                    ),
                    if (achievement.unlockedAt != null)
                      _TagChip(
                        label: _formatUnlockedAt(achievement.unlockedAt!),
                        color: AppTheme.onSurfaceVariant,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatUnlockedAt(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.7)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'SpaceMono',
          fontSize: 9,
          color: color,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
