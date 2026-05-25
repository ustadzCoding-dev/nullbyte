import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nullbyte/core/constants/app_constants.dart';
import 'package:nullbyte/core/theme/app_theme.dart';
import 'package:nullbyte/features/active_session/providers/game_session_provider.dart';
import 'package:nullbyte/features/active_session/widgets/flag_submission_modal.dart';
import 'package:nullbyte/features/active_session/widgets/hint_modal.dart';
import 'package:nullbyte/features/active_session/widgets/net_map_view.dart';
import 'package:nullbyte/features/active_session/widgets/terminal_view.dart';
import 'package:nullbyte/features/active_session/widgets/timer_widget.dart';
import 'package:nullbyte/features/mission/providers/mission_provider.dart';
import 'package:nullbyte/features/save/providers/hive_repository_provider.dart';
import 'package:nullbyte/shared/models/game_session_state.dart';
import 'package:nullbyte/shared/models/hint_data.dart';
import 'package:nullbyte/shared/models/level_definition.dart';
import 'package:nullbyte/shared/models/node_state.dart';
import 'package:nullbyte/shared/providers/audio_manager.dart';
import 'package:nullbyte/shared/widgets/scanline_overlay.dart';
import 'package:nullbyte/shared/widgets/tour_guide.dart';

class ActiveSessionScreen extends ConsumerStatefulWidget {
  final String levelId;

  const ActiveSessionScreen({super.key, required this.levelId});

  @override
  ConsumerState<ActiveSessionScreen> createState() =>
      _ActiveSessionScreenState();
}

class _ActiveSessionScreenState extends ConsumerState<ActiveSessionScreen>
    with WidgetsBindingObserver {
  // Use shared provider via ref instead of creating new instance
  bool _sessionStarted = false;
  bool _tourShown = false;
  GameSessionState? _savedSession;
  int _previousObjectiveCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final missionId = _missionIdFromLevelId(widget.levelId);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(missionProvider.notifier).loadMission(missionId);
      final saved = await ref
          .read(hiveRepositoryProvider)
          .loadSessionState(widget.levelId);
      if (!mounted || saved == null || saved.isCompleted) return;
      setState(() => _savedSession = saved);
    });
  }

  String _missionIdFromLevelId(String levelId) {
    if (levelId.startsWith('m1')) return 'mission_1';
    if (levelId.startsWith('m2')) return 'mission_2';
    if (levelId.startsWith('m3')) return 'mission_3';
    return 'mission_1';
  }

  Future<void> _showTourDelayed() async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    TourGuide.show(context, activeSessionTour);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      ref.read(gameSessionProvider.notifier).pauseSession();
      _persistSessionSnapshot();
    } else if (state == AppLifecycleState.resumed) {
      ref.read(gameSessionProvider.notifier).resumeSession();
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(gameSessionProvider);
    final missionState = ref.watch(missionProvider);
    final liveScore = ref.watch(liveScoreProvider);
    final lives = ref.watch(livesProvider);
    final levelContext = ref.watch(levelContextProvider);

    // SFX feedback saat objective baru selesai
    final currentObjectiveCount = levelContext.completedObjectives.length;
    if (currentObjectiveCount > _previousObjectiveCount &&
        _previousObjectiveCount > 0) {
      final audio = ref.read(audioManagerProvider);
      audio.playSfx(AppConstants.sfxNodeDiscovered);
    }
    _previousObjectiveCount = currentObjectiveCount;

    if (missionState.isLoading) {
      return ScanlineOverlay(
        child: Scaffold(
          backgroundColor: AppTheme.surface,
          body: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppTheme.primaryContainer),
                SizedBox(height: 16),
                Text(
                  'LOADING MISSION...',
                  style: TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 12,
                    color: AppTheme.primaryContainer,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!missionState.levels.containsKey(widget.levelId)) {
      return ScanlineOverlay(
        child: Scaffold(
          backgroundColor: AppTheme.surface,
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'MISSION_NOT_FOUND',
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppTheme.error,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.levelId,
                  style: const TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 11,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: () {
                    final missionId = _missionIdFromLevelId(widget.levelId);
                    ref.read(missionProvider.notifier).loadMission(missionId);
                  },
                  child: const Text('RETRY'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final level = missionState.levels[widget.levelId]!;

    if (!_sessionStarted || session.levelId.isEmpty) {
      _sessionStarted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        final savedSession = _savedSession;
        final resumeSaved = savedSession != null
            ? await _showResumeDialog(context, savedSession)
            : false;

        if (!mounted) return;

        if (resumeSaved) {
          ref
              .read(gameSessionProvider.notifier)
              .startSession(level, restoredSession: savedSession);
          _restoreLevelContext(level, savedSession);
        } else {
          if (savedSession != null) {
            await ref
                .read(hiveRepositoryProvider)
                .clearSessionState(widget.levelId);
          }
          ref.read(gameSessionProvider.notifier).startSession(level);
          ref.read(levelContextProvider).startLevel(level);
        }

        final audio = ref.read(audioManagerProvider);
        // All in-game BGM uses the same track for consistency
        audio.playBgm(AppConstants.bgmMission3);

        if (!_tourShown && level.id == 'm1_l1') {
          _tourShown = true;
          _showTourDelayed();
        }
      });
    }

    final levelTitle = level.title.isNotEmpty
        ? level.title.toUpperCase()
        : session.levelId.toUpperCase();

    final nodeStates = levelContext.nodeStates;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _confirmExit(context);
      },
      child: ScanlineOverlay(
        child: Scaffold(
          backgroundColor: AppTheme.surface,
          appBar: AppBar(
            backgroundColor: AppTheme.surfaceContainerHigh,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppTheme.onSurface),
              onPressed: () => _confirmExit(context),
            ),
            title: MarqueeText(
              text: levelTitle,
              style: const TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppTheme.onSurface,
                letterSpacing: 0.05,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.help_outline,
                  color: AppTheme.onSurfaceVariant,
                ),
                tooltip: 'Panduan',
                onPressed: () => TourGuide.show(context, activeSessionTour),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  3,
                  (i) => Icon(
                    Icons.favorite,
                    size: 14,
                    color: i < lives ? AppTheme.error : AppTheme.outlineVariant,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showScoreBreakdown(context, ref),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      liveScore.toString().padLeft(5, '0'),
                      style: const TextStyle(
                        fontFamily: 'SpaceMono',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.secondaryContainer,
                        letterSpacing: 0.05,
                      ),
                    ),
                    const Text(
                      'SCORE',
                      style: TextStyle(
                        fontFamily: 'SpaceMono',
                        fontSize: 7,
                        color: AppTheme.onSurfaceVariant,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.flag, color: AppTheme.primaryContainer),
                tooltip: 'Submit Flag',
                onPressed: () => showFlagSubmissionModal(context, ref),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Center(child: TimerWidget()),
              ),
            ],
          ),
          body: Column(
            children: [
              _MissionBriefPanel(level: level),
              Expanded(
                flex: 40,
                child: Stack(
                  children: [
                    NetMapView(
                      topology: level.topology,
                      nodeStates: nodeStates,
                    ),
                    Positioned(
                      left: 12,
                      top: 12,
                      // BUG-09 FIX: tidak lagi perlu passing levelContext —
                      // widget langsung ref.watch ke levelContextProvider.
                      child: const _ObjectiveProgressIndicator(),
                    ),
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: _HintButton(
                        onPressed: () => showHintModal(
                          context,
                          ref,
                          level.hints.isNotEmpty ? level.hints : _defaultHints,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(
                height: 1,
                thickness: 1,
                color: AppTheme.outlineVariant,
              ),
              const Expanded(flex: 60, child: TerminalView()),
            ],
          ),
        ),
      ),
    );
  }

  void _showScoreBreakdown(BuildContext context, WidgetRef ref) {
    final session = ref.read(gameSessionProvider);
    // BUG-08 FIX: baca elapsedSeconds dari state (sudah di-sync setiap detik)
    final elapsedSec = session.elapsedSeconds;
    final hintsUsed = session.hintsUsed;
    final failedAttempts = session.failedAttempts;
    final base = AppConstants.scoreBase;
    final timeBonus = AppConstants.scoreTimeBonusMax - (elapsedSec ~/ 2);
    final effectiveTimeBonus = timeBonus < 0 ? 0 : timeBonus;
    final hintPenalty = hintsUsed * AppConstants.scoreHintPenalty;
    final failPenalty = failedAttempts * AppConstants.scoreFailPenalty;
    final noHintBonus = hintsUsed == 0 ? AppConstants.scoreNoHintBonus : 0;
    final total =
        base + effectiveTimeBonus - hintPenalty - failPenalty + noHintBonus;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceContainer,
      shape: const RoundedRectangleBorder(),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.analytics,
                  color: AppTheme.secondaryContainer,
                  size: 18,
                ),
                const SizedBox(width: 8),
                const Text(
                  'SCORE_BREAKDOWN',
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppTheme.onSurface,
                    letterSpacing: 0.08,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(
                    Icons.close,
                    color: AppTheme.onSurfaceVariant,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _scoreRow('BASE', '+$base', AppTheme.onSurface),
            _scoreRow(
              'TIME_BONUS',
              '+$effectiveTimeBonus',
              AppTheme.primaryContainer,
            ),
            if (hintPenalty > 0)
              _scoreRow('HINT_PENALTY', '-$hintPenalty', AppTheme.error),
            if (failPenalty > 0)
              _scoreRow('FAIL_PENALTY', '-$failPenalty', AppTheme.error),
            if (noHintBonus > 0)
              _scoreRow(
                'NO_HINT_BONUS',
                '+$noHintBonus',
                AppTheme.tertiaryContainer,
              ),
            const Divider(color: AppTheme.outlineVariant, height: 24),
            _scoreRow('TOTAL', '$total', AppTheme.secondaryContainer),
            const SizedBox(height: 12),
            const Text(
              'Time bonus berkurang 1 setiap 2 detik (max 500). Hint: -100/hint. Fail: -50/salah. No-hint: +200 jika 0 hint.',
              style: TextStyle(
                fontFamily: 'JetBrainsMono',
                fontSize: 10,
                color: AppTheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scoreRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 10,
              color: AppTheme.onSurfaceVariant,
              letterSpacing: 1.0,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmExit(BuildContext context) async {
    ref.read(gameSessionProvider.notifier).pauseSession();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceContainer,
        shape: const RoundedRectangleBorder(),
        title: const Text(
          'ABORT_MISSION?',
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: AppTheme.error,
          ),
        ),
        content: const Text(
          '[WARNING]: Sesi aktif akan dihentikan.\nSnapshot sesi akan tetap disimpan agar bisa dilanjutkan nanti.\nLanjutkan?',
          style: TextStyle(
            fontFamily: 'JetBrainsMono',
            fontSize: 13,
            color: AppTheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop(false);
              ref.read(gameSessionProvider.notifier).resumeSession();
            },
            child: const Text(
              'CONTINUE_MISSION',
              style: TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 11,
                color: AppTheme.primaryContainer,
              ),
            ),
          ),
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.error,
              side: const BorderSide(color: AppTheme.error),
              shape: const RoundedRectangleBorder(),
            ),
            child: const Text(
              'ABORT',
              style: TextStyle(fontFamily: 'SpaceMono', fontSize: 11),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await _persistSessionSnapshot();
      if (!context.mounted) return;
      context.go('/mission');
    } else {
      ref.read(gameSessionProvider.notifier).resumeSession();
    }
  }

  Future<void> _persistSessionSnapshot() async {
    final session = ref.read(gameSessionProvider);
    if (session.levelId.isEmpty || session.isCompleted) return;

    final levelContext = ref.read(levelContextProvider);
    final snapshot = ref
        .read(gameSessionProvider.notifier)
        .buildPersistenceSnapshot(levelContext);
    await ref
        .read(hiveRepositoryProvider)
        .saveSessionState(widget.levelId, snapshot);
  }

  void _restoreLevelContext(LevelDefinition level, GameSessionState snapshot) {
    final levelContext = ref.read(levelContextProvider);
    levelContext.startLevel(level);
    levelContext.restoreRuntimeState(
      currentDirectory: snapshot.currentDirectory,
      currentUser: snapshot.currentUser,
      currentHost: snapshot.currentHost,
      hasRootPrivilege: snapshot.hasRootPrivilege,
      commandHistory: snapshot.commandHistory,
      nodeStates: {
        for (final entry in snapshot.nodeStates.entries)
          entry.key: _parseNodeState(entry.value),
      },
      completedObjectives: snapshot.completedObjectives.toSet(),
    );
  }

  Future<bool> _showResumeDialog(
    BuildContext context,
    GameSessionState saved,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceContainer,
        shape: const RoundedRectangleBorder(),
        title: const Text(
          'RESUME_SAVED_SESSION?',
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: AppTheme.primaryContainer,
          ),
        ),
        content: Text(
          'Snapshot ditemukan untuk level ini.\n'
          'TIME_ELAPSED: ${_formatDuration(saved.elapsedSeconds)}\n'
          'HINTS_USED: ${saved.hintsUsed}\n'
          'FAILED_ATTEMPTS: ${saved.failedAttempts}\n'
          'LIVES: ${saved.lives}\n'
          'CURRENT_HOST: ${saved.currentHost}\n'
          'CURRENT_PATH: ${saved.currentDirectory}',
          style: const TextStyle(
            fontFamily: 'JetBrainsMono',
            fontSize: 12,
            color: AppTheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'RESTART',
              style: TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 11,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ),
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryContainer,
              side: const BorderSide(color: AppTheme.primaryContainer),
              shape: const RoundedRectangleBorder(),
            ),
            child: const Text(
              'RESUME',
              style: TextStyle(fontFamily: 'SpaceMono', fontSize: 11),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainingSeconds';
  }
}

class _MissionBriefPanel extends StatefulWidget {
  final LevelDefinition level;

  const _MissionBriefPanel({required this.level});

  @override
  State<_MissionBriefPanel> createState() => _MissionBriefPanelState();
}

class _MissionBriefPanelState extends State<_MissionBriefPanel> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final level = widget.level;
    final objectives = level.objectives.take(3).toList();
    final recommendedTools = level.recommendedTools.take(3).toList();

    return SelectionArea(
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(16, 8, 16, _expanded ? 12 : 8),
        color: AppTheme.surfaceContainerLow,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Row(
                children: [
                  const Text(
                    'MISSION_BRIEF',
                    style: TextStyle(
                      fontFamily: 'SpaceMono',
                      fontSize: 10,
                      color: AppTheme.primaryContainer,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 16,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
            if (_expanded) ...[
              const SizedBox(height: 8),
              Text(
                level.narrative,
                style: const TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 11,
                  color: AppTheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              if (objectives.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Text(
                  'LEVEL_OBJECTIVES',
                  style: TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 9,
                    color: AppTheme.primaryContainer,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                ...objectives.map(
                  (objective) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(
                            Icons.chevron_right,
                            size: 14,
                            color: AppTheme.primaryContainer,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            objective.description,
                            style: const TextStyle(
                              fontFamily: 'JetBrainsMono',
                              fontSize: 10,
                              color: AppTheme.onSurfaceVariant,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (recommendedTools.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Text(
                  'SUGGESTED_TOOLS',
                  style: TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 9,
                    color: AppTheme.secondaryContainer,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: recommendedTools
                      .map(
                        (tool) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          color: AppTheme.surfaceContainerHigh,
                          child: Text(
                            tool.toUpperCase(),
                            style: const TextStyle(
                              fontFamily: 'JetBrainsMono',
                              fontSize: 10,
                              color: AppTheme.onSurface,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: 10),
              const Text(
                'Fokus pada objective yang aktif. Jika mentok, buka hint bertahap untuk melihat arah berpikir tanpa langsung menyalin jawaban.',
                style: TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 10,
                  color: AppTheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

const List<HintData> _defaultHints = [
  HintData(
    level: 1,
    text:
        'Gunakan perintah "help" untuk melihat command yang tersedia. Mulai dari reconnaissance dulu, lalu lanjut ke service atau file yang paling relevan.',
  ),
  HintData(
    level: 2,
    text:
        'Flag jarang bisa diambil langsung. Selesaikan objective satu per satu dan perhatikan baris [tip] di output terminal untuk membaca arah berikutnya.',
  ),
  HintData(
    level: 3,
    text:
        'Jika level menuntut akses lebih tinggi, pastikan foothold atau privilege yang diperlukan sudah tercapai sebelum mencoba membaca flag.',
  ),
];

NodeState _parseNodeState(String name) {
  return NodeState.values.firstWhere(
    (s) => s.name == name,
    orElse: () => NodeState.undiscovered,
  );
}

class _HintButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _HintButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.secondaryContainer,
      shape: const RoundedRectangleBorder(),
      child: InkWell(
        onTap: onPressed,
        child: const Padding(
          padding: EdgeInsets.all(10),
          child: Icon(Icons.lightbulb, color: AppTheme.onSecondary, size: 22),
        ),
      ),
    );
  }
}

// BUG-09 FIX: pakai ConsumerStatefulWidget agar ref.watch(levelContextProvider)
// memicu rebuild langsung saat LevelContext.notifyListeners() dipanggil.
// Tidak lagi bergantung pada didUpdateWidget dari parent — lebih andal.
class _ObjectiveProgressIndicator extends ConsumerStatefulWidget {
  const _ObjectiveProgressIndicator();

  @override
  ConsumerState<_ObjectiveProgressIndicator> createState() =>
      _ObjectiveProgressIndicatorState();
}

class _ObjectiveProgressIndicatorState
    extends ConsumerState<_ObjectiveProgressIndicator>
    with SingleTickerProviderStateMixin {
  late int _prevCount;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _prevCount = ref.read(levelContextProvider).completedObjectives.length;
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _pulseAnim = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch langsung ke provider — rebuild otomatis setiap objective baru selesai.
    final levelContext = ref.watch(levelContextProvider);
    final newCount = levelContext.completedObjectives.length;
    if (newCount > _prevCount) {
      // Jalankan pulse animation hanya saat ada objective baru.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _pulseCtrl.forward(from: 0);
      });
    }
    _prevCount = newCount;

    final steps = _getStepsForLevel(levelContext.levelId);
    final completed = levelContext.completedObjectives;
    final hasRoot = levelContext.hasRootPrivilege;

    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, child) {
        final glowAlpha = _pulseAnim.value;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.surface.withValues(alpha: 0.85),
            border: Border.all(
              color: Color.lerp(
                AppTheme.outlineVariant,
                AppTheme.primaryContainer,
                glowAlpha,
              )!,
            ),
            borderRadius: BorderRadius.circular(4),
            boxShadow: glowAlpha > 0
                ? [
                    BoxShadow(
                      color: AppTheme.primaryContainer.withValues(
                        alpha: glowAlpha * 0.4,
                      ),
                      blurRadius: 8 * glowAlpha,
                    ),
                  ]
                : null,
          ),
          child: child,
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: steps.map((step) {
          final isDone = switch (step.checkKind) {
            _CheckKind.objective => completed.contains(step.objectiveId),
            _CheckKind.rootPrivilege => hasRoot,
            _CheckKind.flagAccessible => levelContext.isFlagAccessible,
          };
          final isLast = step == steps.last;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 14,
                color: isDone
                    ? AppTheme.primaryContainer
                    : AppTheme.outlineVariant,
              ),
              const SizedBox(width: 3),
              Text(
                step.label,
                style: TextStyle(
                  fontFamily: 'SpaceMono',
                  fontSize: 9,
                  color: isDone
                      ? AppTheme.primaryContainer
                      : AppTheme.outlineVariant,
                  fontWeight: isDone ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
              if (!isLast)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    Icons.arrow_forward,
                    size: 10,
                    color: AppTheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  List<_KillChainStep> _getStepsForLevel(String levelId) {
    if (levelId.startsWith('m1')) {
      return [
        _KillChainStep('hosts_discovered', 'RECON', _CheckKind.objective),
        _KillChainStep('service_fingerprinted', 'ENUM', _CheckKind.objective),
        _KillChainStep('', 'FLAG', _CheckKind.flagAccessible),
      ];
    }
    if (levelId == 'm2_l1') {
      return [
        _KillChainStep('endpoint_discovered', 'RECON', _CheckKind.objective),
        _KillChainStep('', 'FLAG', _CheckKind.flagAccessible),
      ];
    }
    if (levelId.startsWith('m2') && levelId != 'm2_l1') {
      return [
        _KillChainStep('hosts_discovered', 'RECON', _CheckKind.objective),
        _KillChainStep('exploit_successful', 'EXPLOIT', _CheckKind.objective),
        _KillChainStep('', 'FLAG', _CheckKind.flagAccessible),
      ];
    }
    if (levelId == 'm3_l1' || levelId == 'm3_l2') {
      return [
        _KillChainStep('exploit_successful', 'FOOTHOLD', _CheckKind.objective),
        _KillChainStep('', 'FLAG', _CheckKind.flagAccessible),
      ];
    }
    if (levelId == 'm3_l4') {
      return [
        _KillChainStep('pivot_discovered', 'RECON', _CheckKind.objective),
        _KillChainStep('internal_discovered', 'PIVOT', _CheckKind.objective),
        _KillChainStep('exploit_successful', 'FOOTHOLD', _CheckKind.objective),
        _KillChainStep('', 'FLAG', _CheckKind.flagAccessible),
      ];
    }
    // M3 L3/L5: FOOTHOLD via exploit_successful, PRIVESC via hasRootPrivilege, FLAG via isFlagAccessible
    return [
      _KillChainStep('exploit_successful', 'FOOTHOLD', _CheckKind.objective),
      _KillChainStep('root_privilege', 'PRIVESC', _CheckKind.rootPrivilege),
      _KillChainStep('', 'FLAG', _CheckKind.flagAccessible),
    ];
  }
}

enum _CheckKind { objective, rootPrivilege, flagAccessible }

class _KillChainStep {
  final String objectiveId;
  final String label;
  final _CheckKind checkKind;

  const _KillChainStep(this.objectiveId, this.label, this.checkKind);
}

/// Animated scrolling marquee text for titles in restricted layouts.
class MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const MarqueeText({
    super.key,
    required this.text,
    required this.style,
  });

  @override
  State<MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScrolling());
  }

  void _startScrolling() async {
    if (!mounted) return;
    // Wait a brief frame for scroll metrics to populate
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    if (maxScroll <= 0) return;

    while (mounted) {
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted || !_scrollController.hasClients) return;

      // Scroll to end with speed proportional to distance (linear rate)
      final durationMs = (maxScroll * 40).toInt().clamp(1500, 8000);
      await _scrollController.animateTo(
        maxScroll,
        duration: Duration(milliseconds: durationMs),
        curve: Curves.linear,
      );

      await Future.delayed(const Duration(seconds: 2));
      if (!mounted || !_scrollController.hasClients) return;

      // Snap or slide back to beginning quickly
      await _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Text(
            widget.text,
            style: widget.style,
            maxLines: 1,
          ),
        ),
      ),
    );
  }
}
