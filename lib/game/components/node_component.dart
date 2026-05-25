import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:nullbyte/core/theme/app_theme.dart';
import 'package:nullbyte/shared/models/network_topology.dart';
import 'package:nullbyte/shared/models/node_state.dart';

/// Flame component yang merepresentasikan satu node di NetworkMap.
/// Render icon Material sesuai tipe node, dengan warna per NodeState.
class NodeComponent extends PositionComponent with TapCallbacks {
  static const double nodeSize = 56.0;
  static const double _pulseMin = 1.0;
  static const double _pulseMax = 1.15;
  static const double _pulseSpeed = 2.0;

  final NetworkNode data;
  NodeState state;
  void Function(NodeComponent)? onTapped;

  double _pulseTimer = 0.0;
  double _pulseScale = 1.0;

  NodeComponent({
    required this.data,
    this.state = NodeState.undiscovered,
    this.onTapped,
  }) : super(size: Vector2.all(nodeSize), anchor: Anchor.center);

  // ── Icon mapping per node type ─────────────────────────────────────────────

  /// Codepoint Material Icons sesuai tipe node.
  static int _iconCodepoint(String type) {
    switch (type.toLowerCase()) {
      case 'router':
        return Icons.router.codePoint;
      case 'server':
        return Icons.dns.codePoint;
      case 'workstation':
        return Icons.computer.codePoint;
      case 'firewall':
        return Icons.security.codePoint;
      default:
        return Icons.device_hub.codePoint;
    }
  }

  // ── Colors per state ───────────────────────────────────────────────────────

  Color get _borderColor {
    switch (state) {
      case NodeState.undiscovered:
        return AppTheme.outlineVariant.withValues(alpha: 0.5);
      case NodeState.discovered:
        return AppTheme.secondaryContainer; // Amber for discovered target
      case NodeState.scanning:
        return AppTheme.tertiaryContainer; // Cyan for active scanning
      case NodeState.exploited:
        return AppTheme.primaryContainer; // Glowing Neon Green for compromised/exploited
      case NodeState.secured:
        return AppTheme.secondaryContainer;
    }
  }

  Color get _bgColor {
    switch (state) {
      case NodeState.undiscovered:
        return AppTheme.surfaceContainerHigh.withValues(alpha: 0.5);
      case NodeState.discovered:
        return AppTheme.surfaceContainerLow;
      case NodeState.scanning:
        return AppTheme.surfaceContainerLow;
      case NodeState.exploited:
        return AppTheme.primaryContainer.withValues(alpha: 0.15);
      case NodeState.secured:
        return AppTheme.secondaryContainer.withValues(alpha: 0.15);
    }
  }

  Color get _iconColor {
    switch (state) {
      case NodeState.undiscovered:
        return AppTheme.outlineVariant.withValues(alpha: 0.5);
      case NodeState.discovered:
        return AppTheme.secondaryContainer; // Amber for discovered target
      case NodeState.scanning:
        return AppTheme.tertiaryContainer;
      case NodeState.exploited:
        return AppTheme.primaryContainer; // Glowing Neon Green
      case NodeState.secured:
        return AppTheme.secondaryContainer;
    }
  }

  // ── Update & Render ────────────────────────────────────────────────────────

  @override
  void update(double dt) {
    super.update(dt);
    if (state == NodeState.scanning) {
      _pulseTimer += dt * _pulseSpeed * 2 * pi;
      _pulseScale =
          _pulseMin + (_pulseMax - _pulseMin) * (0.5 + 0.5 * sin(_pulseTimer));
    } else {
      _pulseScale = 1.0;
      _pulseTimer = 0.0;
    }
  }

  @override
  void render(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);
    final radius = (nodeSize / 2) * _pulseScale;

    // ── Background circle ──────────────────────────────────────────────────
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = _bgColor
        ..style = PaintingStyle.fill,
    );

    // ── Border ────────────────────────────────────────────────────────────
    final borderWidth =
        state == NodeState.discovered ||
            state == NodeState.exploited ||
            state == NodeState.secured
        ? 2.5
        : 1.5;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = _borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth,
    );

    // ── Pulse ring saat scanning ───────────────────────────────────────────
    if (state == NodeState.scanning) {
      canvas.drawCircle(
        center,
        radius + 6,
        Paint()
          ..color = AppTheme.tertiaryContainer.withValues(alpha: 0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    }

    // ── Glow ring saat exploited ───────────────────────────────────────────
    if (state == NodeState.exploited) {
      canvas.drawCircle(
        center,
        radius + 4,
        Paint()
          ..color = AppTheme.primaryContainer.withValues(alpha: 0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );
    }

    // ── Icon ───────────────────────────────────────────────────────────────
    if (state == NodeState.undiscovered) {
      // Tanda "?" untuk undiscovered
      _drawText(
        canvas,
        '?',
        center,
        color: AppTheme.outlineVariant.withValues(alpha: 0.6),
        fontSize: 18,
      );
    } else {
      _drawIcon(canvas, center, _iconCodepoint(data.type), _iconColor, 22);
    }

    // ── Label di bawah node ────────────────────────────────────────────────
    if (state != NodeState.undiscovered) {
      _drawText(
        canvas,
        _shortLabel(data.label),
        Offset(center.dx, center.dy + radius + 8),
        color: _iconColor.withValues(alpha: 0.85),
        fontSize: 8,
      );
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _drawIcon(
    Canvas canvas,
    Offset center,
    int codepoint,
    Color color,
    double size,
  ) {
    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(codepoint),
        style: TextStyle(
          fontFamily: 'MaterialIcons',
          fontSize: size,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset center, {
    required Color color,
    required double fontSize,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontFamily: 'SpaceMono',
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  String _shortLabel(String label) =>
      label.length > 10 ? '${label.substring(0, 9)}…' : label;

  void updateState(NodeState newState) => state = newState;

  @override
  void onTapDown(TapDownEvent event) => onTapped?.call(this);
}
