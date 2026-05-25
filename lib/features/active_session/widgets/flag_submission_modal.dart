import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nullbyte/core/constants/app_constants.dart';
import 'package:nullbyte/core/theme/app_theme.dart';
import 'package:nullbyte/features/active_session/domain/flag_verifier.dart';
import 'package:nullbyte/features/active_session/providers/game_session_provider.dart';
import 'package:nullbyte/features/mission/providers/level_completion_provider.dart';
import 'package:nullbyte/features/save/providers/hive_repository_provider.dart';
import 'package:nullbyte/shared/providers/audio_manager.dart';

/// Tampilkan modal bottom sheet untuk submit flag.
void showFlagSubmissionModal(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.surfaceContainerLow,
    shape: const RoundedRectangleBorder(),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: _FlagSubmissionSheet(parentRef: ref),
    ),
  );
}

class _FlagSubmissionSheet extends ConsumerStatefulWidget {
  final WidgetRef parentRef;

  const _FlagSubmissionSheet({required this.parentRef});

  @override
  ConsumerState<_FlagSubmissionSheet> createState() =>
      _FlagSubmissionSheetState();
}

class _FlagSubmissionSheetState extends ConsumerState<_FlagSubmissionSheet> {
  final _controller = TextEditingController();
  // Use shared provider instead of creating new instance
  String? _errorMessage;
  bool _showSuccess = false;
  bool _isSubmitting = false; // BUG-05: prevent concurrent submissions

  static const _verifier = FlagVerifier();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return; // BUG-05: debounce concurrent submissions
    final input = _controller.text.trim();
    if (input.isEmpty) return;

    setState(() => _isSubmitting = true);

    // BUG-01 FIX: ambil flagHash dari LevelContext, bukan hardcoded ''
    final levelContext = ref.read(levelContextProvider);
    final flagHash = levelContext.levelDefinition?.flagHash ?? '';
    final audio = ref.read(audioManagerProvider);

    if (_verifier.verify(input, flagHash)) {
      await audio.playSfx(AppConstants.sfxFlagCaptured);
      setState(() => _showSuccess = true);
      ref.read(gameSessionProvider.notifier).setCompleted();
      final session = ref.read(gameSessionProvider);
      final levelDefinition = levelContext.levelDefinition;
      final elapsedSeconds = ref.read(elapsedSecondsProvider);
      if (levelDefinition != null) {
        await ref
            .read(levelCompletionServiceProvider)
            .persistCompletedLevel(
              level: levelDefinition,
              session: session,
              elapsedSeconds: elapsedSeconds,
            );
        await ref
            .read(hiveRepositoryProvider)
            .clearSessionState(levelDefinition.id);
      }
      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) {
        final levelId = ref.read(gameSessionProvider).levelId;
        context.go('/session/$levelId/result');
      }
    } else {
      await audio.playSfx(AppConstants.sfxCommandError);
      ref.read(gameSessionProvider.notifier).incrementFailedAttempts();

      // BUG-02 FIX: cek game over saat lives habis
      final lives = ref.read(livesProvider);
      if (lives <= 0) {
        setState(() {
          _errorMessage = 'NYAWA HABIS. MISI GAGAL.';
          _isSubmitting = false;
        });
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) {
          final levelId = ref.read(gameSessionProvider).levelId;
          if (levelId.isNotEmpty) {
            await ref.read(hiveRepositoryProvider).clearSessionState(levelId);
          }
          if (!mounted) return;
          Navigator.of(context).pop();
          context.go('/mission');
        }
        return;
      }

      setState(() {
        _errorMessage = 'FLAG SALAH. COBA LAGI. ($lives nyawa tersisa)';
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        border: Border(
          top: BorderSide(color: AppTheme.primaryContainer, width: 2),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: _showSuccess ? _buildSuccess() : _buildForm(),
    );
  }

  Widget _buildSuccess() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.check_circle,
          color: AppTheme.primaryContainer,
          size: 48,
        ),
        const SizedBox(height: 12),
        const Text(
          'FLAG CAPTURED!',
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: AppTheme.primaryContainer,
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Menghitung skor...',
          style: TextStyle(
            fontFamily: 'JetBrainsMono',
            fontSize: 13,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            const Icon(Icons.flag, color: AppTheme.primaryContainer, size: 18),
            const SizedBox(width: 8),
            const Text(
              'SUBMIT FLAG',
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
        const SizedBox(height: 20),

        // Input field
        TextField(
          controller: _controller,
          autofocus: true,
          style: const TextStyle(
            fontFamily: 'JetBrainsMono',
            fontSize: 14,
            color: AppTheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: 'nullbyte{...}',
            hintStyle: const TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: 14,
              color: AppTheme.outlineVariant,
            ),
            filled: true,
            fillColor: AppTheme.surfaceContainerLowest,
            border: const UnderlineInputBorder(
              borderSide: BorderSide(
                color: AppTheme.primaryContainer,
                width: 2,
              ),
              borderRadius: BorderRadius.zero,
            ),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppTheme.outlineVariant, width: 2),
              borderRadius: BorderRadius.zero,
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(
                color: AppTheme.primaryContainer,
                width: 2,
              ),
              borderRadius: BorderRadius.zero,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
          onSubmitted: (_) => _submit(),
        ),

        // Error message
        if (_errorMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: const TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: 12,
              color: AppTheme.error,
            ),
          ),
        ],

        const SizedBox(height: 20),

        // Submit button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryContainer,
              foregroundColor: AppTheme.onPrimary,
              disabledBackgroundColor: AppTheme.outlineVariant,
              shape: const RoundedRectangleBorder(),
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 0,
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.onPrimary,
                    ),
                  )
                : const Text(
                    'SUBMIT FLAG',
                    style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      letterSpacing: 0.1,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
