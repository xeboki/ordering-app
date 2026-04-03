import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Xeboki geometric X mark — 4 rounded pill arms with brand gradient.
///
/// [size]      Width & height in logical pixels.
/// [glowValue] 0.0 = no glow (sidebar/static use).
///             0.0 → 1.0 animated = pulsing glow (splash screen use).
class XebokiLogoMark extends StatelessWidget {
  final double size;
  final double glowValue;

  const XebokiLogoMark({super.key, required this.size, this.glowValue = 0.0});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _XMarkPainter(glowValue: glowValue)),
      );
}

// ── Painter ──────────────────────────────────────────────────────────────────

class _XMarkPainter extends CustomPainter {
  final double glowValue;

  const _XMarkPainter({this.glowValue = 0.0});

  static const _gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF818CF8), Color(0xFF4F6AF6), Color(0xFF6D28D9)],
    stops: [0.0, 0.45, 1.0],
  );

  void _drawArms(Canvas canvas, Size size, Paint paint) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final s  = size.width / 100.0;

    final arm = RRect.fromRectAndRadius(
      Rect.fromLTWH(cx - 7.0 * s, cy - 8.0 * s - 28.0 * s, 14.0 * s, 28.0 * s),
      Radius.circular(7.0 * s),
    );

    for (var i = 0; i < 4; i++) {
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate((45.0 + i * 90.0) * math.pi / 180.0);
      canvas.translate(-cx, -cy);
      canvas.drawRRect(arm, paint);
      canvas.restore();
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Shape-following glow (only when glowValue > 0)
    if (glowValue > 0) {
      final sigma = 5.0 + glowValue * 7.0;
      final alpha = ((0.30 + glowValue * 0.25) * 255).round();
      canvas.save();
      canvas.translate(0, 4.0);
      _drawArms(
        canvas, size,
        Paint()
          ..color = Color.fromARGB(alpha, 79, 106, 246)
          ..style = PaintingStyle.fill
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, sigma),
      );
      canvas.restore();
    }

    // Sharp gradient arms
    _drawArms(
      canvas, size,
      Paint()
        ..shader = _gradient.createShader(
            Rect.fromLTWH(0, 0, size.width, size.height))
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_XMarkPainter old) => old.glowValue != glowValue;
}
