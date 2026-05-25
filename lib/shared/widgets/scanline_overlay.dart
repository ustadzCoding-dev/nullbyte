import 'package:flutter/material.dart';

/// Wraps [child] dengan CRT scanline overlay semi-transparan.
/// Overlay tidak memblokir interaksi (IgnorePointer).
class ScanlineOverlay extends StatelessWidget {
  const ScanlineOverlay({super.key, required this.child, this.opacity = 0.15});

  final Widget child;

  /// Opacity garis scanline. Default 0.15 sesuai design spec.
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: Opacity(
              opacity: opacity,
              child: const CustomPaint(painter: ScanlinePainter()),
            ),
          ),
        ),
      ],
    );
  }
}

/// CustomPainter yang menggambar horizontal lines semi-transparan
/// untuk efek CRT / terminal grit.
class ScanlinePainter extends CustomPainter {
  const ScanlinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Gambar garis horizontal setiap 2px (1px line, 1px gap)
    for (double y = 0; y < size.height; y += 2) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(ScanlinePainter oldDelegate) => false;
}
