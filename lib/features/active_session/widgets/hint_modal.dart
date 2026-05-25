import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nullbyte/core/constants/app_constants.dart';
import 'package:nullbyte/core/theme/app_theme.dart';
import 'package:nullbyte/features/active_session/providers/game_session_provider.dart';
import 'package:nullbyte/shared/models/hint_data.dart';

void showHintModal(BuildContext context, WidgetRef ref, List<HintData> hints) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.surfaceContainer,
    shape: const RoundedRectangleBorder(),
    builder: (_) => _HintSheet(hints: hints),
  );
}

class _HintSheet extends ConsumerWidget {
  final List<HintData> hints;

  const _HintSheet({required this.hints});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameSessionProvider);
    final hintsUsed = session.hintsUsed;
    final maxHints = AppConstants.maxHintsPerLevel;
    final revealedHints = hints.take(hintsUsed).toList();
    final canRevealHint = hintsUsed < maxHints;
    final canOpenSolution = hintsUsed >= maxHints;

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceContainer,
        border: Border(
          top: BorderSide(color: AppTheme.secondaryContainer, width: 2),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb,
                color: AppTheme.secondaryContainer,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                'HINT SYSTEM',
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
          const SizedBox(height: 4),
          Text(
            '-${AppConstants.scoreHintPenalty} poin setiap membuka hint baru',
            style: const TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: 11,
              color: AppTheme.secondaryContainer,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Buka hint secara bertahap. Hint pertama memberi arah berpikir, hint berikutnya semakin spesifik, dan rute solusi hanya muncul sebagai opsi terakhir.',
            style: TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: 11,
              color: AppTheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          if (revealedHints.isEmpty)
            _buildLockedState()
          else
            ...revealedHints.asMap().entries.map(
              (entry) => _buildHintTile(entry.value, entry.key + 1),
            ),
          const SizedBox(height: 16),
          if (canRevealHint)
            _buildUnlockButton(ref, hintsUsed + 1)
          else if (canOpenSolution)
            _buildSolutionButton(context, ref),
        ],
      ),
    );
  }

  Widget _buildLockedState() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.surfaceContainerHigh,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Belum ada hint yang dibuka.',
            style: TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: 13,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Hint 1 memberi arah konseptual. Coba pecahkan objective dulu sebelum membuka bantuan lebih dalam.',
            style: TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: 11,
              color: AppTheme.outline,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHintTile(HintData hint, int index) {
    final levelLabel = switch (hint.level) {
      1 => 'KONSEPTUAL',
      2 => 'ARAH TOOL',
      3 => 'LANGKAH BERIKUTNYA',
      _ => 'HINT $index',
    };

    final labelColor = switch (hint.level) {
      1 => AppTheme.onSurfaceVariant,
      2 => AppTheme.secondaryContainer,
      3 => AppTheme.error,
      _ => AppTheme.onSurfaceVariant,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        color: AppTheme.surfaceContainerHigh,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'HINT $index',
                  style: const TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurface,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '[$levelLabel]',
                  style: TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 10,
                    color: labelColor,
                    letterSpacing: 0.05,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              hint.text,
              style: const TextStyle(
                fontFamily: 'JetBrainsMono',
                fontSize: 13,
                color: AppTheme.onSurface,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnlockButton(WidgetRef ref, int nextHintNum) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () {
          ref.read(gameSessionProvider.notifier).useHint();
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.secondaryContainer,
          side: const BorderSide(color: AppTheme.secondaryContainer, width: 1),
          shape: const RoundedRectangleBorder(),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(
          'BUKA HINT $nextHintNum  (-${AppConstants.scoreHintPenalty} POIN)',
          style: const TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontWeight: FontWeight.w700,
            fontSize: 13,
            letterSpacing: 0.05,
          ),
        ),
      ),
    );
  }

  Widget _buildSolutionButton(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          color: AppTheme.errorContainer,
          child: const Row(
            children: [
              Icon(Icons.warning, color: AppTheme.error, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Semua hint sudah terbuka. Gunakan rute solusi ini hanya jika Anda benar-benar ingin melihat jalur penyelesaian intinya.',
                  style: TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 11,
                    color: AppTheme.onErrorContainer,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => _showSolutionPreview(context, ref),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.error,
              side: const BorderSide(color: AppTheme.error, width: 1),
              shape: const RoundedRectangleBorder(),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text(
              'LIHAT RUTE SOLUSI',
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontWeight: FontWeight.w700,
                fontSize: 13,
                letterSpacing: 0.05,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showSolutionPreview(BuildContext context, WidgetRef ref) {
    final level = ref.read(levelContextProvider).levelDefinition;
    final commands = level?.expectedCommandPath ?? const <String>[];

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceContainer,
        shape: const RoundedRectangleBorder(),
        title: const Text(
          'SOLUTION_ROUTE',
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: AppTheme.error,
          ),
        ),
        content: SizedBox(
          width: 420,
          child: commands.isEmpty
              ? const Text(
                  'Rute command belum tersedia untuk level ini.',
                  style: TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 12,
                    color: AppTheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Gunakan daftar ini sebagai referensi terakhir. Setelah melihatnya, coba pahami alasan tiap command dipakai, bukan hanya menyalinnya.',
                      style: TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontSize: 12,
                        color: AppTheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...commands.map(
                      (command) => Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        color: AppTheme.surfaceContainerHigh,
                        child: Text(
                          command,
                          style: const TextStyle(
                            fontFamily: 'JetBrainsMono',
                            fontSize: 11,
                            color: AppTheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryContainer,
              side: const BorderSide(color: AppTheme.primaryContainer),
              shape: const RoundedRectangleBorder(),
            ),
            child: const Text(
              'CLOSE',
              style: TextStyle(fontFamily: 'SpaceMono', fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
