import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:nullbyte/core/theme/app_theme.dart';
import 'package:nullbyte/game/components/node_component.dart';

enum NodeConnectionState { inactive, active }

/// Garis koneksi antar node dengan style dashed + arrow tip.
class ConnectionComponent extends PositionComponent {
  final NodeComponent source;
  final NodeComponent target;
  NodeConnectionState connectionState;

  // Animasi dash offset untuk efek "data flowing"
  double _dashOffset = 0.0;

  ConnectionComponent({
    required this.source,
    required this.target,
    this.connectionState = NodeConnectionState.inactive,
  }) : super(priority: -1);

  @override
  void update(double dt) {
    super.update(dt);
    if (connectionState == NodeConnectionState.active) {
      _dashOffset = (_dashOffset + dt * 30) % 20;
    }
  }

  @override
  void render(Canvas canvas) {
    // Hitung titik tepi lingkaran node (bukan center)
    final srcCenter = source.position;
    final tgtCenter = target.position;

    final dx = tgtCenter.x - srcCenter.x;
    final dy = tgtCenter.y - srcCenter.y;
    final dist = sqrt(dx * dx + dy * dy);
    if (dist < 1) return;

    final nx = dx / dist;
    final ny = dy / dist;
    final r = NodeComponent.nodeSize / 2;

    // Start/end di tepi lingkaran, bukan di center
    final start = Offset(srcCenter.x + nx * r, srcCenter.y + ny * r);
    final end = Offset(tgtCenter.x - nx * r, tgtCenter.y - ny * r);

    if (connectionState == NodeConnectionState.active) {
      _drawActiveLine(canvas, start, end, nx, ny);
    } else {
      _drawInactiveLine(canvas, start, end);
    }
  }

  void _drawInactiveLine(Canvas canvas, Offset start, Offset end) {
    // Garis putus-putus tipis untuk inactive
    final paint = Paint()
      ..color = AppTheme.outlineVariant.withValues(alpha: 0.4)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    _drawDashedLine(canvas, start, end, paint, dashLen: 6, gapLen: 4);
  }

  void _drawActiveLine(
    Canvas canvas,
    Offset start,
    Offset end,
    double nx,
    double ny,
  ) {
    // Glow layer
    final glowPaint = Paint()
      ..color = AppTheme.primaryContainer.withValues(alpha: 0.08)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(start, end, glowPaint);

    // Garis utama solid
    final linePaint = Paint()
      ..color = AppTheme.primaryContainer.withValues(alpha: 0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(start, end, linePaint);

    // Animated dash overlay (data flow effect)
    final dashPaint = Paint()
      ..color = AppTheme.primaryContainer.withValues(alpha: 0.9)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    _drawDashedLine(
      canvas,
      start,
      end,
      dashPaint,
      dashLen: 8,
      gapLen: 12,
      offset: _dashOffset,
    );

    // Arrow tip di ujung
    _drawArrow(canvas, end, nx, ny);
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint, {
    double dashLen = 8,
    double gapLen = 6,
    double offset = 0,
  }) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final dist = sqrt(dx * dx + dy * dy);
    if (dist < 1) return;

    final nx = dx / dist;
    final ny = dy / dist;
    final period = dashLen + gapLen;

    double pos = offset % period;
    // Jika offset membuat kita mulai di gap, skip ke dash berikutnya
    if (pos > dashLen) pos = pos - period;

    while (pos < dist) {
      final dashStart = pos.clamp(0.0, dist);
      final dashEnd = (pos + dashLen).clamp(0.0, dist);

      if (dashStart < dashEnd) {
        canvas.drawLine(
          Offset(start.dx + nx * dashStart, start.dy + ny * dashStart),
          Offset(start.dx + nx * dashEnd, start.dy + ny * dashEnd),
          paint,
        );
      }
      pos += period;
    }
  }

  void _drawArrow(Canvas canvas, Offset tip, double nx, double ny) {
    const arrowLen = 8.0;
    const arrowAngle = 0.45; // ~25 degrees

    final ax1 =
        tip.dx - arrowLen * (nx * cos(arrowAngle) - ny * sin(arrowAngle));
    final ay1 =
        tip.dy - arrowLen * (ny * cos(arrowAngle) + nx * sin(arrowAngle));
    final ax2 =
        tip.dx - arrowLen * (nx * cos(arrowAngle) + ny * sin(arrowAngle));
    final ay2 =
        tip.dy - arrowLen * (ny * cos(arrowAngle) - nx * sin(arrowAngle));

    final arrowPaint = Paint()
      ..color = AppTheme.primaryContainer.withValues(alpha: 0.8)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(tip, Offset(ax1, ay1), arrowPaint);
    canvas.drawLine(tip, Offset(ax2, ay2), arrowPaint);
  }
}
