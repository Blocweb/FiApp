import 'package:flutter/material.dart';

/// Ilustración de "monedas + check" para el onboarding, replicando el SVG
/// `IllustrationCoins` original (viewBox 0 0 240 200).
class IllustrationCoins extends StatelessWidget {
  const IllustrationCoins({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite ? constraints.maxWidth : 240.0;
        final clamped = width > 240 ? 240.0 : width;
        return SizedBox(
          width: clamped,
          height: clamped * (200 / 240),
          child: CustomPaint(painter: _CoinsPainter()),
        );
      },
    );
  }
}

class _CoinsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 240;
    final sy = size.height / 200;
    Offset p(double x, double y) => Offset(x * sx, y * sy);
    double sw(double v) => v * sx;

    void rrect(double x, double y, double w, double h, double r, Color color) {
      final rect = Rect.fromLTWH(x * sx, y * sy, w * sx, h * sy);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(r * sx)),
        Paint()..color = color,
      );
    }

    void dollarText(Offset center, double fontSize, Color color) {
      final tp = TextPainter(
        text: TextSpan(
          text: r'$',
          style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
    }

    // Sombra base
    final shadowRect = Rect.fromCenter(
      center: p(120, 170),
      width: 140 * sx,
      height: 24 * sy,
    );
    canvas.drawOval(shadowRect, Paint()..color = const Color(0x99E2E8F0));

    // Moneda naranja grande
    canvas.drawCircle(p(80, 100), sw(30), Paint()..color = const Color(0xFFF59E0B));
    canvas.drawCircle(p(80, 100), sw(24), Paint()..color = const Color(0xFFFCD34D));
    dollarText(p(80, 101), sw(18), const Color(0xFF92400E));

    // Moneda verde
    canvas.drawCircle(p(140, 80), sw(24), Paint()..color = const Color(0xFF22C55E));
    canvas.drawCircle(p(140, 80), sw(18), Paint()..color = const Color(0xFF4ADE80));
    dollarText(p(140, 81), sw(14), const Color(0xFF14532D));

    // Moneda azul
    canvas.drawCircle(p(170, 115), sw(20), Paint()..color = const Color(0xFF2563EB));
    canvas.drawCircle(p(170, 115), sw(14), Paint()..color = const Color(0xFF60A5FA));
    dollarText(p(170, 116), sw(12), const Color(0xFF1E3A8A));

    // Caja check
    rrect(95, 135, 50, 28, 8, const Color(0xFF2563EB));
    final checkPath = Path()
      ..moveTo(108 * sx, 149 * sy)
      ..lineTo(113 * sx, 154 * sy)
      ..lineTo(132 * sx, 137 * sy);
    canvas.drawPath(
      checkPath,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw(2.5)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
