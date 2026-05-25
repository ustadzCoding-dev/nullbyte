import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nullbyte/features/active_session/domain/level_context.dart';
import 'package:nullbyte/features/active_session/domain/score_calculator.dart';
import 'package:nullbyte/shared/models/game_session_state.dart';
import 'package:nullbyte/shared/models/level_definition.dart';
import 'package:nullbyte/shared/models/node_state.dart';

// ── GameSessionNotifier ────────────────────────────────────────────────────

/// Mengelola state [GameSessionState] selama sesi gameplay aktif.
///
/// Bertanggung jawab atas:
/// - Inisialisasi dan penyelesaian sesi
/// - Timer elapsed seconds
/// - Pencatatan command history
/// - Penghitungan skor akhir
class GameSessionNotifier extends StateNotifier<GameSessionState> {
  final ScoreCalculator _scoreCalculator;

  Timer? _timer;
  int _elapsedSeconds = 0;
  bool _isPaused = false;

  GameSessionNotifier({ScoreCalculator? scoreCalculator})
    : _scoreCalculator = scoreCalculator ?? const ScoreCalculator(),
      super(GameSessionState(levelId: '', startTime: DateTime.now()));

  /// Elapsed seconds saat ini (tidak disimpan di state untuk efisiensi).
  int get elapsedSeconds => _elapsedSeconds;

  // ── Session lifecycle ────────────────────────────────────────────────────

  /// Inisialisasi sesi baru dari [LevelDefinition].
  void startSession(
    LevelDefinition level, {
    GameSessionState? restoredSession,
  }) {
    _stopTimer();
    _isPaused = false;
    if (restoredSession != null) {
      _elapsedSeconds = restoredSession.elapsedSeconds;
      state = restoredSession.copyWith(
        levelId: level.id,
        isCompleted: false,
        finalScore: null,
      );
    } else {
      _elapsedSeconds = 0;
      state = GameSessionState(levelId: level.id, startTime: DateTime.now());
    }

    _startTimer();
  }

  /// Selesaikan sesi: set isCompleted = true dan hitung finalScore.
  void setCompleted() {
    if (state.isCompleted) return;
    _stopTimer();

    final score = calculateFinalScore();
    state = state.copyWith(isCompleted: true, finalScore: score);
  }

  // ── Command & attempt tracking ───────────────────────────────────────────

  /// Tambah [command] ke commandHistory.
  void recordCommand(String command) {
    if (command.trim().isEmpty) return;
    final updated = List<String>.from(state.commandHistory)..add(command);
    state = state.copyWith(commandHistory: updated);
  }

  /// Tambah failedAttempts sebesar 1 dan kurangi lives sebesar 1.
  void incrementFailedAttempts() {
    final newLives = (state.lives - 1).clamp(0, 3);
    state = state.copyWith(
      failedAttempts: state.failedAttempts + 1,
      lives: newLives,
    );
  }

  /// Tambah hintsUsed sebesar 1.
  void useHint() {
    state = state.copyWith(hintsUsed: state.hintsUsed + 1);
  }

  /// Update state sebuah node di nodeStates map.
  /// BUG-06 FIX: state juga di-persist ke Hive via copyWith (auto-save on next save cycle)
  void updateNodeState(String nodeId, NodeState nodeState) {
    final updated = Map<String, String>.from(state.nodeStates)
      ..[nodeId] = nodeState.name;
    state = state.copyWith(nodeStates: updated);
  }

  GameSessionState buildPersistenceSnapshot(LevelContext context) {
    return state.copyWith(
      elapsedSeconds: _elapsedSeconds,
      commandHistory: List<String>.from(context.commandHistory),
      nodeStates: {
        for (final entry in context.nodeStates.entries)
          entry.key: entry.value.name,
      },
      currentDirectory: context.currentDirectory,
      currentUser: context.currentUser,
      hasRootPrivilege: context.hasRootPrivilege,
      completedObjectives: List<String>.from(context.completedObjectives),
      currentHost: context.currentHost,
    );
  }

  // ── Score ────────────────────────────────────────────────────────────────

  /// Hitung skor akhir berdasarkan state sesi saat ini.
  int calculateFinalScore() {
    return _scoreCalculator.calculate(
      elapsedSeconds: _elapsedSeconds,
      hintsUsed: state.hintsUsed,
      failedAttempts: state.failedAttempts,
    );
  }

  // ── Timer management ─────────────────────────────────────────────────────

  /// Pause timer (misal saat AppLifecycle.paused).
  void pauseSession() {
    if (_isPaused) return;
    _isPaused = true;
    _stopTimer();
  }

  /// Resume timer setelah pause.
  void resumeSession() {
    if (!_isPaused) return;
    _isPaused = false;
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      // BUG-07 FIX: stop timer jika session sudah selesai (race-condition guard)
      if (state.isCompleted) {
        _stopTimer();
        return;
      }
      _elapsedSeconds++;
      // BUG-08 FIX: sync _elapsedSeconds ke state agar provider downstream
      // selalu membaca nilai yang akurat (bukan field terpisah via ref.read)
      state = state.copyWith(elapsedSeconds: _elapsedSeconds);
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}

// ── Providers ──────────────────────────────────────────────────────────────

/// Provider utama untuk [GameSessionState].
final gameSessionProvider =
    StateNotifierProvider<GameSessionNotifier, GameSessionState>(
      (ref) => GameSessionNotifier(),
    );

/// Provider derived yang expose elapsed seconds dari state (bukan field notifier).
/// BUG-08 FIX: ref.watch(gameSessionProvider) mengembalikan state.elapsedSeconds
/// yang di-update setiap detik oleh timer — tidak pernah stale.
final elapsedSecondsProvider = Provider<int>((ref) {
  return ref.watch(gameSessionProvider).elapsedSeconds;
});

/// Provider derived untuk live score (dihitung realtime).
final liveScoreProvider = Provider<int>((ref) {
  ref.watch(gameSessionProvider);
  ref.watch(elapsedSecondsProvider);
  return ref.read(gameSessionProvider.notifier).calculateFinalScore();
});

/// Provider derived untuk sisa lives.
final livesProvider = Provider<int>((ref) {
  return ref.watch(gameSessionProvider).lives;
});

/// Provider untuk [LevelContext] yang digunakan oleh command execution.
///
/// Harus di-override dengan [ProviderScope] atau [ChangeNotifierProvider.family]
/// saat sesi dimulai dengan level tertentu.
final levelContextProvider = ChangeNotifierProvider<LevelContext>((ref) {
  // Default context — akan di-override saat startSession dipanggil.
  return LevelContext(levelId: '');
});
