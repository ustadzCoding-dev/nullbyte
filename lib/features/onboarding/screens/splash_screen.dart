import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nullbyte/core/router/app_router.dart';
import 'package:nullbyte/core/theme/app_theme.dart';
import 'package:nullbyte/features/save/providers/hive_repository_provider.dart';
import 'package:nullbyte/shared/widgets/scanline_overlay.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  static const _disclaimerKey = 'disclaimerAccepted';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
    _bootstrapAndNavigate();
  }

  Future<void> _bootstrapAndNavigate() async {
    final repo = ref.read(hiveRepositoryProvider);
    final accepted =
        await repo.loadSettingsAsync(_disclaimerKey) as bool? ?? false;
    AppRouter.disclaimerNotifier.setAccepted(accepted);

    await Future<void>.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;
    context.go('/mission');
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScanlineOverlay(
      child: Scaffold(
        backgroundColor: AppTheme.surface,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo / Title dengan animasi
              FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    children: [
                      // Neon green glow effect
                      Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryContainer.withValues(
                                alpha: 0.4,
                              ),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Text(
                          'NULLBYTE',
                          style: Theme.of(context).textTheme.displayLarge!
                              .copyWith(
                                color: AppTheme.primaryContainer,
                                letterSpacing: 0.15,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Subtitle
                      Text(
                        'PENETRATION TESTING SIMULATOR',
                        style: Theme.of(context).textTheme.labelLarge!.copyWith(
                          color: AppTheme.onSurfaceVariant,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 80),
              // Loading indicator dengan styling terminal
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.primaryContainer,
                        ),
                        strokeWidth: 2,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'INITIALIZING SYSTEM...',
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: AppTheme.onSurfaceVariant,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
