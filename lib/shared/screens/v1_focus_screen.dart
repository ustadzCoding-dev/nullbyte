import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nullbyte/core/theme/app_theme.dart';
import 'package:nullbyte/shared/widgets/scanline_overlay.dart';

class V1FocusScreen extends StatelessWidget {
  final String title;
  final String summary;
  final String recommendation;

  const V1FocusScreen({
    super.key,
    required this.title,
    required this.summary,
    required this.recommendation,
  });

  @override
  Widget build(BuildContext context) {
    return ScanlineOverlay(
      child: Scaffold(
        backgroundColor: AppTheme.surface,
        appBar: AppBar(
          backgroundColor: AppTheme.surfaceContainerHigh,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.onSurface),
            onPressed: () => context.go('/mission'),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: AppTheme.onSurface,
            ),
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                color: AppTheme.surfaceContainerLow,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'V1_FOCUS_MODE',
                      style: TextStyle(
                        fontFamily: 'SpaceMono',
                        fontSize: 11,
                        color: AppTheme.primaryContainer,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      summary,
                      style: const TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontSize: 13,
                        color: AppTheme.onSurface,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      color: AppTheme.surfaceContainerHigh,
                      child: Text(
                        recommendation,
                        style: const TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: 12,
                          color: AppTheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
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
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                        ),
                        child: const Text(
                          'BACK TO MISSION',
                          style: TextStyle(
                            fontFamily: 'SpaceGrotesk',
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
