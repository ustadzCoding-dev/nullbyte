import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nullbyte/core/theme/app_theme.dart';
import 'package:nullbyte/features/auth/data/auth_provider.dart';
import 'package:nullbyte/features/auth/data/auth_repository.dart';
import 'package:nullbyte/shared/models/player_profile.dart';
import 'package:nullbyte/shared/providers/progression_summary_provider.dart';
import 'package:nullbyte/shared/widgets/scanline_overlay.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return ScanlineOverlay(
      child: Scaffold(
        backgroundColor: AppTheme.surface,
        appBar: _buildAppBar(context),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProfileHeader(user: user),
              const SizedBox(height: 24),
              _SectionDivider(label: 'OPERATOR_STATS'),
              const SizedBox(height: 12),
              const _StatsGrid(),
              const SizedBox(height: 24),
              _SectionDivider(label: 'DATA_VIEWS'),
              const SizedBox(height: 12),
              const _DataViewsSection(),
              const SizedBox(height: 24),
              _SectionDivider(label: 'ACCOUNT_MANAGEMENT'),
              const SizedBox(height: 12),
              _AccountSection(user: user),
              const SizedBox(height: 24),
              _SectionDivider(label: 'DANGER_ZONE', color: AppTheme.error),
              const SizedBox(height: 12),
              const _DangerZone(),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
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
            'OPERATOR_PROFILE',
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
}

// ── Profile Header ────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});
  final PlayerProfile? user;

  @override
  Widget build(BuildContext context) {
    final username = user?.username ?? 'GHOST_OPERATOR';
    final email = user?.email;
    final isGuest = user?.isGuest ?? true;
    final initial = username.isNotEmpty ? username[0].toUpperCase() : 'G';

    return Container(
      padding: const EdgeInsets.all(20),
      color: AppTheme.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerHigh,
                  border: Border.all(
                    color: AppTheme.primaryContainer,
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontWeight: FontWeight.w900,
                    fontSize: 36,
                    color: AppTheme.primaryContainer,
                    shadows: [
                      Shadow(color: AppTheme.primaryContainer, blurRadius: 10),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      style: const TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        fontWeight: FontWeight.w700,
                        fontSize: 24,
                        color: AppTheme.primaryContainer,
                        shadows: [
                          Shadow(
                            color: AppTheme.primaryContainer,
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email ?? 'GUEST_OPERATOR',
                      style: const TextStyle(
                        fontFamily: 'SpaceMono',
                        fontSize: 12,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          color: isGuest
                              ? AppTheme.secondaryContainer
                              : AppTheme.primaryContainer,
                          child: Text(
                            isGuest ? 'GUEST' : 'ONLINE',
                            style: TextStyle(
                              fontFamily: 'SpaceMono',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isGuest
                                  ? AppTheme.onSecondaryContainer
                                  : AppTheme.onPrimary,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          isGuest ? 'LOCAL_GUEST' : 'LOCAL_PROFILE',
                          style: const TextStyle(
                            fontFamily: 'SpaceMono',
                            fontSize: 10,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Stats Grid ────────────────────────────────────────────────────────────────

class _StatsGrid extends ConsumerWidget {
  const _StatsGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(progressionSummaryProvider);

    return summaryAsync.when(
      data: (summary) => GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        childAspectRatio: 2.2,
        children: [
          _StatCell(
            label: 'TOTAL_SCORE',
            value:
                '0x${summary.totalScore.toRadixString(16).toUpperCase().padLeft(4, '0')}',
          ),
          _StatCell(
            label: 'OPERATOR_LEVEL',
            value: summary.operatorLevel.toString(),
          ),
          _StatCell(
            label: 'LEVELS_COMPLETED',
            value: summary.levelsCompleted.toString().padLeft(2, '0'),
          ),
          _StatCell(
            label: 'ACHIEVEMENTS',
            value: summary.achievementsUnlocked.toString().padLeft(2, '0'),
          ),
        ],
      ),
      loading: () => GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        childAspectRatio: 2.2,
        children: const [
          _StatCell(label: 'TOTAL_SCORE', value: '--'),
          _StatCell(label: 'OPERATOR_LEVEL', value: '--'),
          _StatCell(label: 'LEVELS_COMPLETED', value: '--'),
          _StatCell(label: 'ACHIEVEMENTS', value: '--'),
        ],
      ),
      error: (_, __) => GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        childAspectRatio: 2.2,
        children: const [
          _StatCell(label: 'TOTAL_SCORE', value: 'ERR'),
          _StatCell(label: 'OPERATOR_LEVEL', value: 'ERR'),
          _StatCell(label: 'LEVELS_COMPLETED', value: 'ERR'),
          _StatCell(label: 'ACHIEVEMENTS', value: 'ERR'),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: AppTheme.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 9,
              color: AppTheme.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontWeight: FontWeight.w700,
              fontSize: 22,
              color: AppTheme.primaryContainer,
              shadows: [
                Shadow(color: AppTheme.primaryContainer, blurRadius: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section Divider ───────────────────────────────────────────────────────────

class _SectionDivider extends StatelessWidget {
  const _SectionDivider({required this.label, this.color});
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.onSurfaceVariant;
    return Row(
      children: [
        Text(
          '// $label',
          style: TextStyle(
            fontFamily: 'SpaceMono',
            fontSize: 10,
            color: c,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Container(height: 1, color: AppTheme.outlineVariant)),
      ],
    );
  }
}

// ── Account Section ───────────────────────────────────────────────────────────

class _DataViewsSection extends StatelessWidget {
  const _DataViewsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton(
          onPressed: () => context.go('/profile/settings'),
          child: const Text(
            'OPEN_SETTINGS',
            style: TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 11,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }
}

class _AccountSection extends ConsumerWidget {
  const _AccountSection({required this.user});
  final PlayerProfile? user;

  Future<void> _showChangeUsernameDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final controller = TextEditingController(text: user?.username ?? '');
    final focusNode = FocusNode();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceContainer,
        shape: const RoundedRectangleBorder(),
        title: const Text(
          'CHANGE_USERNAME',
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: AppTheme.onSurface,
          ),
        ),
        content: TextField(
          controller: controller,
          focusNode: focusNode,
          autofocus: true,
          onTap: () {
            focusNode.requestFocus();
          },
          style: const TextStyle(
            fontFamily: 'JetBrainsMono',
            fontSize: 14,
            color: AppTheme.primaryContainer,
          ),
          decoration: const InputDecoration(
            hintText: 'NEW_USERNAME',
            hintStyle: TextStyle(color: AppTheme.outlineVariant),
            prefixText: '> ',
            prefixStyle: TextStyle(color: AppTheme.primaryContainer),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'ABORT',
              style: TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 12,
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
              'CONFIRM',
              style: TextStyle(fontFamily: 'SpaceMono', fontSize: 12),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      try {
        await ref
            .read(authNotifierProvider.notifier)
            .updateUsername(controller.text);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('[OK] USERNAME BERHASIL DIUBAH')),
          );
        }
      } on AuthException catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('[ERROR] ${e.message}')));
        }
      }
    }
    controller.dispose();
    focusNode.dispose();
  }

  Future<void> _showChangePasswordDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final oldFocus = FocusNode();
    final newFocus = FocusNode();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceContainer,
        shape: const RoundedRectangleBorder(),
        title: const Text(
          'CHANGE_PASSWORD',
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: AppTheme.onSurface,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldCtrl,
              focusNode: oldFocus,
              autofocus: true,
              obscureText: true,
              onTap: () {
                oldFocus.requestFocus();
              },
              style: const TextStyle(
                fontFamily: 'JetBrainsMono',
                fontSize: 14,
                color: AppTheme.primaryContainer,
              ),
              decoration: const InputDecoration(
                hintText: 'OLD_PASSWORD',
                hintStyle: TextStyle(color: AppTheme.outlineVariant),
                prefixText: '> ',
                prefixStyle: TextStyle(color: AppTheme.primaryContainer),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newCtrl,
              focusNode: newFocus,
              obscureText: true,
              onTap: () {
                newFocus.requestFocus();
              },
              style: const TextStyle(
                fontFamily: 'JetBrainsMono',
                fontSize: 14,
                color: AppTheme.primaryContainer,
              ),
              decoration: const InputDecoration(
                hintText: 'NEW_PASSWORD (min 8)',
                hintStyle: TextStyle(color: AppTheme.outlineVariant),
                prefixText: '> ',
                prefixStyle: TextStyle(color: AppTheme.primaryContainer),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'ABORT',
              style: TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 12,
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
              'CONFIRM',
              style: TextStyle(fontFamily: 'SpaceMono', fontSize: 12),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      try {
        await ref
            .read(authNotifierProvider.notifier)
            .updatePassword(oldCtrl.text, newCtrl.text);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('[OK] PASSWORD BERHASIL DIUBAH')),
          );
        }
      } on AuthException catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('[ERROR] ${e.message}')));
        }
      }
    }
    oldCtrl.dispose();
    newCtrl.dispose();
    oldFocus.dispose();
    newFocus.dispose();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGuest = user?.isGuest ?? true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!isGuest) ...[
          OutlinedButton(
            onPressed: () => _showChangeUsernameDialog(context, ref),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryContainer,
              side: const BorderSide(
                color: AppTheme.primaryContainer,
                width: 1,
              ),
              shape: const RoundedRectangleBorder(),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text(
              'CHANGE_USERNAME',
              style: TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 11,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => _showChangePasswordDialog(context, ref),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryContainer,
              side: const BorderSide(
                color: AppTheme.primaryContainer,
                width: 1,
              ),
              shape: const RoundedRectangleBorder(),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text(
              'CHANGE_PASSWORD',
              style: TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 11,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (isGuest) ...[
          OutlinedButton(
            onPressed: () => context.go('/auth'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryContainer,
              side: const BorderSide(
                color: AppTheme.primaryContainer,
                width: 1,
              ),
              shape: const RoundedRectangleBorder(),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text(
              'UPGRADE GUEST TO REGISTERED',
              style: TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 11,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

// ── Danger Zone ───────────────────────────────────────────────────────────────

class _DangerZone extends ConsumerWidget {
  const _DangerZone();

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceContainer,
        shape: const RoundedRectangleBorder(),
        title: const Text(
          'CONFIRM_SIGN_OUT',
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppTheme.onSurface,
          ),
        ),
        content: const Text(
          '[WARNING]: Sesi aktif akan dihentikan.\nLanjutkan proses sign out?',
          style: TextStyle(
            fontFamily: 'JetBrainsMono',
            fontSize: 13,
            color: AppTheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'ABORT',
              style: TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 12,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ),
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.error,
              side: const BorderSide(color: AppTheme.error, width: 1),
              shape: const RoundedRectangleBorder(),
            ),
            child: const Text(
              'CONFIRM',
              style: TextStyle(fontFamily: 'SpaceMono', fontSize: 12),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authNotifierProvider.notifier).signOut();
      if (context.mounted) {
        context.go('/auth');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OutlinedButton(
      onPressed: () => _confirmSignOut(context, ref),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.error,
        side: const BorderSide(color: AppTheme.error, width: 1),
        shape: const RoundedRectangleBorder(),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: const Text(
        'SIGN_OUT',
        style: TextStyle(
          fontFamily: 'SpaceMono',
          fontSize: 12,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}
