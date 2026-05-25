import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:nullbyte/core/theme/app_theme.dart';

/// Particle effect sederhana saat node di-scan.
/// Lingkaran kecil yang expand dan fade out, lalu auto-remove.
class ScanParticleComponent extends PositionComponent {
  static const double _maxRadius = 30.0;
  static const double _duration = 0.8; // seconds

  double _elapsed = 0.0;
  bool _done = false;

  ScanParticleComponent({required Vector2 nodeCenter})
    : super(position: nodeCenter, anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    if (_elapsed >= _duration && !_done) {
      _done = true;
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    if (_done) return;

    final progress = (_elapsed / _duration).clamp(0.0, 1.0);
    final radius = _maxRadius * progress;
    final opacity = (1.0 - progress).clamp(0.0, 1.0);

    final paint = Paint()
      ..color = AppTheme.primaryContainer.withValues(alpha: opacity * 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(Offset.zero, radius, paint);

    // Inner ring yang lebih kecil
    if (progress < 0.7) {
      final innerPaint = Paint()
        ..color = AppTheme.primaryContainer.withValues(alpha: opacity * 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawCircle(Offset.zero, radius * 0.6, innerPaint);
    }
  }
}
