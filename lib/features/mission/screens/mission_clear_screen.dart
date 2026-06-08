import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nullbyte/core/constants/app_constants.dart';
import 'package:nullbyte/features/active_session/domain/star_rating.dart';
import 'package:nullbyte/features/active_session/providers/game_session_provider.dart';
import 'package:nullbyte/features/mission/providers/mission_provider.dart';
import 'package:nullbyte/features/save/providers/hive_repository_provider.dart';
import 'package:nullbyte/shared/models/level_definition.dart';
import 'package:nullbyte/shared/providers/audio_manager.dart';
import 'package:nullbyte/shared/widgets/scanline_overlay.dart';

class MissionClearScreen extends ConsumerStatefulWidget {
  final String levelId;

  const MissionClearScreen({super.key, required this.levelId});

  @override
  ConsumerState<MissionClearScreen> createState() => _MissionClearScreenState();
}

class _MissionClearScreenState extends ConsumerState<MissionClearScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  static const _starRating = StarRating();

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _scaleAnim = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );

    _animController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(audioManagerProvider).playSfx(AppConstants.sfxFlagCaptured);
      await ref
          .read(missionProvider.notifier)
          .loadMission(_missionIdFromLevelId(widget.levelId));
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  String _missionIdFromLevelId(String levelId) {
    if (levelId.startsWith('m1')) return 'mission_1';
    if (levelId.startsWith('m2')) return 'mission_2';
    if (levelId.startsWith('m3')) return 'mission_3';
    return 'mission_1';
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _formatScoreHex(int score) {
    return '0x${score.toRadixString(16).toUpperCase().padLeft(7, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(gameSessionProvider);
    final elapsed = ref.watch(elapsedSecondsProvider);
    final missionState = ref.watch(missionProvider);
    final level = missionState.levels[widget.levelId];

    if (level == null) {
      return Scaffold(
        backgroundColor: AppConstants.colorSurface,
        body: ScanlineOverlay(
          child: const Center(
            child: CircularProgressIndicator(color: AppConstants.colorPrimary),
          ),
        ),
      );
    }

    final finalScore = session.finalScore ?? 0;
    final ratingResult = _starRating.result(finalScore);
    final noHintBonus = session.hintsUsed == 0;
    final nextLevelId = ref
        .read(missionProvider.notifier)
        .getNextLevelId(widget.levelId);
    final nextLevel = nextLevelId == null
        ? null
        : missionState.levels[nextLevelId];

    return Scaffold(
      backgroundColor: AppConstants.colorSurface,
      body: ScanlineOverlay(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _AnimatedHeader(
                  fadeAnim: _fadeAnim,
                  scaleAnim: _scaleAnim,
                  level: level,
                ),
                const SizedBox(height: 32),
                _ScoreSection(
                  finalScore: finalScore,
                  ratingResult: ratingResult,
                  formatScoreHex: _formatScoreHex,
                ),
                const SizedBox(height: 24),
                _StatsSection(
                  elapsedSeconds: elapsed,
                  hintsUsed: session.hintsUsed,
                  failedAttempts: session.failedAttempts,
                  noHintBonus: noHintBonus,
                  formatTime: _formatTime,
                ),
                const SizedBox(height: 24),
                _DebriefSection(
                  level: level,
                  commandHistory: session.commandHistory,
                  nextLevel: nextLevel,
                ),
                const SizedBox(height: 24),
                _RealWorldSection(level: level),
                const SizedBox(height: 32),
                _ActionButtons(
                  levelId: widget.levelId,
                  nextLevelId: nextLevelId,
                  nextLevelTitle: nextLevel?.title,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedHeader extends StatelessWidget {
  final Animation<double> fadeAnim;
  final Animation<double> scaleAnim;
  final LevelDefinition level;

  const _AnimatedHeader({
    required this.fadeAnim,
    required this.scaleAnim,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeAnim,
      child: ScaleTransition(
        scale: scaleAnim,
        child: Column(
          children: [
            Text(
              'FLAG CAPTURED',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 48,
                fontWeight: FontWeight.w900,
                color: AppConstants.colorPrimary,
                shadows: [
                  Shadow(
                    color: AppConstants.colorPrimary.withValues(alpha: 0.8),
                    blurRadius: 16,
                  ),
                  Shadow(
                    color: AppConstants.colorPrimary.withValues(alpha: 0.4),
                    blurRadius: 32,
                  ),
                ],
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              level.title.toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 12,
                color: AppConstants.colorOnSurfaceVariant,
                letterSpacing: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreSection extends StatelessWidget {
  final int finalScore;
  final StarRatingResult ratingResult;
  final String Function(int) formatScoreHex;

  const _ScoreSection({
    required this.finalScore,
    required this.ratingResult,
    required this.formatScoreHex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppConstants.colorSurfaceLow,
        border: Border.all(color: AppConstants.colorOutlineVariant, width: 1),
      ),
      child: Column(
        children: [
          const Text(
            'FINAL_SCORE',
            style: TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 10,
              color: AppConstants.colorOnSurfaceVariant,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            formatScoreHex(finalScore),
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: AppConstants.colorPrimary,
              shadows: [
                Shadow(
                  color: AppConstants.colorPrimary.withValues(alpha: 0.6),
                  blurRadius: 12,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              final filled = i < ratingResult.stars;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  filled ? Icons.star : Icons.star_border,
                  color: filled
                      ? AppConstants.colorPrimary
                      : AppConstants.colorOutlineVariant,
                  size: 32,
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            ratingResult.label,
            style: TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 12,
              color: AppConstants.colorPrimary,
              letterSpacing: 4,
              shadows: [
                Shadow(
                  color: AppConstants.colorPrimary.withValues(alpha: 0.5),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsSection extends StatelessWidget {
  final int elapsedSeconds;
  final int hintsUsed;
  final int failedAttempts;
  final bool noHintBonus;
  final String Function(int) formatTime;

  const _StatsSection({
    required this.elapsedSeconds,
    required this.hintsUsed,
    required this.failedAttempts,
    required this.noHintBonus,
    required this.formatTime,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.colorSurfaceLow,
        border: Border.all(color: AppConstants.colorOutlineVariant, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'STATS_BREAKDOWN',
            style: TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 10,
              color: AppConstants.colorOnSurfaceVariant,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 12),
          _StatRow(label: 'TIME_ELAPSED', value: formatTime(elapsedSeconds)),
          const SizedBox(height: 8),
          _StatRow(label: 'HINTS_USED', value: hintsUsed.toString()),
          const SizedBox(height: 8),
          _StatRow(label: 'FAILED_ATTEMPTS', value: failedAttempts.toString()),
          if (noHintBonus) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: AppConstants.colorPrimary, width: 1),
              ),
              child: Text(
                '+ NO HINT BONUS',
                style: TextStyle(
                  fontFamily: 'SpaceMono',
                  fontSize: 10,
                  color: AppConstants.colorPrimary,
                  letterSpacing: 2,
                  shadows: [
                    Shadow(
                      color: AppConstants.colorPrimary.withValues(alpha: 0.6),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'SpaceMono',
            fontSize: 10,
            color: AppConstants.colorOnSurfaceVariant,
            letterSpacing: 1,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'JetBrainsMono',
            fontSize: 14,
            color: AppConstants.colorOnSurface,
          ),
        ),
      ],
    );
  }
}

class _RealWorldSection extends StatelessWidget {
  final LevelDefinition level;

  const _RealWorldSection({required this.level});

  @override
  Widget build(BuildContext context) {
    final tools = level.recommendedTools.join(', ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppConstants.colorSurfaceLow,
        border: Border(
          left: BorderSide(color: AppConstants.colorSecondary, width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'REAL_WORLD_CONTEXT',
            style: TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 10,
              color: AppConstants.colorSecondary,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            level.realWorldContext,
            style: const TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: 12,
              color: AppConstants.colorOnSurfaceVariant,
              height: 1.6,
            ),
          ),
          if (tools.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'RECOMMENDED_TOOLS: $tools',
              style: const TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 10,
                color: AppConstants.colorPrimary,
                letterSpacing: 1,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DebriefSection extends StatelessWidget {
  final LevelDefinition level;
  final List<String> commandHistory;
  final LevelDefinition? nextLevel;

  const _DebriefSection({
    required this.level,
    required this.commandHistory,
    required this.nextLevel,
  });

  @override
  Widget build(BuildContext context) {
    final objectives = level.objectives.take(3).toList();
    final usedRuntimeHistory = commandHistory.isNotEmpty;
    final commandPath = usedRuntimeHistory
        ? commandHistory.take(6).toList()
        : level.expectedCommandPath.take(4).toList();
    final learned = _learningRecapFor(level);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.colorSurfaceLow,
        border: Border.all(color: AppConstants.colorOutlineVariant, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MISSION_DEBRIEF',
            style: TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 10,
              color: AppConstants.colorPrimary,
              letterSpacing: 3,
            ),
          ),
          if (objectives.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'OBJECTIVES_CLEARED',
              style: TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 9,
                color: AppConstants.colorOnSurfaceVariant,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            ...objectives.map(
              (objective) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 1),
                      child: Icon(
                        Icons.check_circle,
                        size: 14,
                        color: AppConstants.colorPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        objective.description,
                        style: const TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: 11,
                          color: AppConstants.colorOnSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          const Text(
            'WHAT_YOU_LEARNED',
            style: TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 9,
              color: AppConstants.colorSecondary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(
                left: BorderSide(color: AppConstants.colorSecondary, width: 3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  learned.title,
                  style: const TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppConstants.colorOnSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  learned.body,
                  style: const TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 11,
                    color: AppConstants.colorOnSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          if (commandPath.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              usedRuntimeHistory ? 'COMMANDS_YOU_USED' : 'REFERENCE_ROUTE',
              style: const TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 9,
                color: AppConstants.colorOnSurfaceVariant,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: commandPath
                  .map(
                    (command) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppConstants.colorOutlineVariant,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        command,
                        style: const TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: 10,
                          color: AppConstants.colorOnSurface,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (!usedRuntimeHistory) ...[
            const SizedBox(height: 10),
            const Text(
              'Runtime command history tidak tersedia, jadi panel ini menampilkan jalur referensi level sebagai fallback.',
              style: TextStyle(
                fontFamily: 'JetBrainsMono',
                fontSize: 10,
                color: AppConstants.colorOnSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            nextLevel == null
                ? 'NEXT_STEP: kembali ke mission directory untuk memilih operasi berikutnya.'
                : 'NEXT_STEP: lanjut ke ${nextLevel!.title.toUpperCase()} untuk menjaga progression tetap berjalan.',
            style: const TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: 11,
              color: AppConstants.colorPrimary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  _LearningRecap _learningRecapFor(LevelDefinition level) {
    return switch (level.id) {
      'm1_l1' => const _LearningRecap(
        title: 'Discovery Comes Before Exploitation',
        body:
            'Anda belajar bahwa reconnaissance dimulai dari menemukan host yang hidup dulu. Setelah target terlihat, baru service web yang terbuka bisa diperiksa untuk mencari artefak sensitif.',
      ),
      'm1_l2' => const _LearningRecap(
        title: 'Unusual Ports Often Hide Valuable Surface',
        body:
            'Anda melihat bahwa service penting tidak selalu berada di port default. Port non-standar perlu di-scan dan divalidasi karena sering menyimpan admin panel, staging service, atau endpoint tersembunyi.',
      ),
      'm1_l3' => const _LearningRecap(
        title: 'Version Fingerprinting Changes Your Next Move',
        body:
            'Port terbuka saja belum cukup. Dengan mengetahui versi service, Anda bisa menghubungkan temuan ke kerentanan atau misconfiguration yang lebih spesifik sebelum mencoba ekstraksi data.',
      ),
      'm1_l4' => const _LearningRecap(
        title: 'Content Enumeration Beats Guesswork',
        body:
            'Anda belajar mencari backup, notes, dan artefak yang terekspos dari service web. Banyak kebocoran terjadi bukan karena exploit rumit, tetapi karena file operasional dibiarkan bisa diakses.',
      ),
      'm1_l5' => const _LearningRecap(
        title: 'Recon Can Be Enough To Extract Sensitive Data',
        body:
            'Level ini menegaskan bahwa recon yang rapi bisa langsung menghasilkan data penting. Fokus utamanya adalah memilih service yang paling relevan lalu mengekstrak artefak dengan bersih.',
      ),
      'm2_l1' => const _LearningRecap(
        title: 'Map The Surface Before Testing Exploits',
        body:
            'Anda belajar memetakan endpoint publik, parameter input, dan route yang relevan sebelum mencoba exploit. Dalam web exploitation, observasi struktur aplikasi sering menentukan arah serangan berikutnya.',
      ),
      'm2_l2' => const _LearningRecap(
        title: 'Validate Injection Before Automating It',
        body:
            'Level ini menunjukkan bahwa sinyal kecil seperti error SQL atau respons aneh sudah cukup untuk memvalidasi hipotesis. Setelah titik injeksi dipahami, automation seperti sqlmap menjadi jauh lebih bernilai.',
      ),
      'm2_l3' => const _LearningRecap(
        title: 'Tiny Input Bugs Can Become Full Admin Access',
        body:
            'Anda melihat bagaimana manipulasi sederhana pada input login bisa mem-bypass autentikasi sepenuhnya. Pelajarannya bukan sekadar payload, tetapi memahami logika query yang disalahgunakan.',
      ),
      'm2_l4' => const _LearningRecap(
        title: 'Weak Upload Validation Becomes Code Execution',
        body:
            'Upload feature yang hanya memeriksa MIME type atau sisi klien mudah disalahgunakan. Begitu file berbahaya bisa dipanggil dari web root, permukaan serang langsung naik ke remote command execution.',
      ),
      'm2_l5' => const _LearningRecap(
        title: 'A Foothold Is Only Useful If You Can Operate From It',
        body:
            'Webshell bukan tujuan akhir. Anda belajar mengubah foothold yang rapuh menjadi kontrol operasional yang lebih stabil untuk mengekstrak data penting dari target produksi.',
      ),
      'm3_l1' => const _LearningRecap(
        title: 'Foothold Before Escalation',
        body:
            'Anda belajar bahwa privilege escalation selalu dimulai dari akses user-level yang stabil. Tanpa foothold yang bisa diverifikasi, tidak ada titik awal untuk enumerasi dan escalation berikutnya.',
      ),
      'm3_l2' => const _LearningRecap(
        title: 'Enumeration Reveals What Scanning Cannot',
        body:
            'Setelah foothold aktif, enumerasi lokal menjadi sumber intel utama. File sistem, log autentikasi, dan jejak sudo sering mengungkap jalur escalation yang tidak terlihat dari luar jaringan.',
      ),
      'm3_l3' => const _LearningRecap(
        title: 'Misconfigured Sudo Is A Free Root Shell',
        body:
            'Whitelist sudo yang longgar bukan sekadar keteledoran — itu adalah kerentanan struktural. Binary seperti find, vim, atau tar yang diizinkan tanpa password bisa langsung diubah menjadi shell istimewa.',
      ),
      'm3_l4' => const _LearningRecap(
        title: 'Pivoting Extends Your Reach Beyond The Initial Target',
        body:
            'Satu foothold jarang cukup. Anda belajar menggunakan host yang sudah dikuasai sebagai batu loncatan untuk menjangkau segmen internal yang sebelumnya tidak terlihat dari luar.',
      ),
      'm3_l5' => const _LearningRecap(
        title: 'From Foothold To Root: The Full Kill Chain',
        body:
            'Level ini menyatukan seluruh kill chain: foothold, enumerasi, escalation, dan objective capture. Anda membuktikan bahwa setiap tahap punya peran kritis dan bahwa memahami mengapa jalur escalation berhasil sama pentingnya dengan mendapatkan root itu sendiri.',
      ),
      _ => const _LearningRecap(
        title: 'Mission Complete',
        body:
            'Anda menyelesaikan objective inti level ini. Gunakan debrief dan command route di bawah untuk mengingat pola pikir yang berhasil dipakai.',
      ),
    };
  }
}

class _LearningRecap {
  final String title;
  final String body;

  const _LearningRecap({required this.title, required this.body});
}

// BUG-10 FIX: pakai ConsumerWidget agar bisa reset gameSessionProvider
// sebelum navigate ke replay, mencegah state lama (isCompleted/finalScore) bocor.
class _ActionButtons extends ConsumerWidget {
  final String levelId;
  final String? nextLevelId;
  final String? nextLevelTitle;

  const _ActionButtons({
    required this.levelId,
    required this.nextLevelId,
    required this.nextLevelTitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasNextLevel = nextLevelId != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: () {
            if (hasNextLevel) {
              ref.invalidate(gameSessionProvider);
              ref.invalidate(levelContextProvider);
              context.go('/session/$nextLevelId');
            } else {
              context.go('/mission');
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.colorPrimary,
            foregroundColor: AppConstants.colorSurface,
            shape: const RoundedRectangleBorder(),
            padding: const EdgeInsets.symmetric(vertical: 16),
            elevation: 0,
          ),
          child: Text(
            hasNextLevel
                ? 'NEXT LEVEL${nextLevelTitle == null ? '' : ' - ${nextLevelTitle!.toUpperCase()}'}'
                : 'BACK TO MISSION SELECT',
            style: const TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontWeight: FontWeight.w700,
              fontSize: 13,
              letterSpacing: 2,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () async {
            // BUG-10 FIX: reset session state dan level context sebelum replay dimulai
            // agar isCompleted/finalScore dan peta node lama tidak bocor ke sesi baru.
            ref.invalidate(gameSessionProvider);
            ref.invalidate(levelContextProvider);
            
            // Tambahan FIX: Hapus sesi tersimpan di Hive (offline DB) agar layar 
            // ActiveSessionScreen tidak me-load state 'isCompleted' kembali secara otomatis.
            await ref.read(hiveRepositoryProvider).clearSessionState(levelId);
            
            if (context.mounted) {
              context.go('/session/$levelId');
            }
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: AppConstants.colorPrimary,
            side: const BorderSide(color: AppConstants.colorPrimary, width: 1),
            shape: const RoundedRectangleBorder(),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text(
            'REPLAY',
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontWeight: FontWeight.w600,
              fontSize: 14,
              letterSpacing: 3,
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => context.go('/mission'),
          style: TextButton.styleFrom(
            foregroundColor: AppConstants.colorOnSurfaceVariant,
            shape: const RoundedRectangleBorder(),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: const Text(
            'BACK TO MISSION SELECT',
            style: TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: 12,
              letterSpacing: 2,
            ),
          ),
        ),
      ],
    );
  }
}

