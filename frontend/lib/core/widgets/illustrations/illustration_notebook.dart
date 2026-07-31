import 'package:flutter/material.dart';

/// Ilustración de "cuaderno -> celular" para el onboarding, replicando
/// exactamente el SVG `IllustrationNotebook` del prototipo original
/// (viewBox 0 0 240 200).
class IllustrationNotebook extends StatelessWidget {
  const IllustrationNotebook({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite ? constraints.maxWidth : 240.0;
        final clamped = width > 240 ? 240.0 : width;
        return SizedBox(
          width: clamped,
          height: clamped * (200 / 240),
          child: CustomPaint(painter: _NotebookPainter()),
        );
      },
    );
  }
}

class _NotebookPainter extends CustomPainter {
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

    // Libreta (izquierda)
    rrect(30, 20, 80, 110, 8, const Color(0xFFE2E8F0));
    rrect(38, 28, 64, 6, 3, const Color(0xFFCBD5E1));
    rrect(38, 42, 48, 4, 2, const Color(0xFFCBD5E1));
    rrect(38, 54, 56, 4, 2, const Color(0xFFCBD5E1));
    rrect(38, 66, 40, 4, 2, const Color(0xFFCBD5E1));
    rrect(38, 78, 52, 4, 2, const Color(0xFFCBD5E1));
    rrect(38, 90, 44, 4, 2, const Color(0xFFCBD5E1));
    rrect(26, 20, 8, 110, 4, const Color(0xFF94A3B8));

    // Flecha punteada
    final dashPaint = Paint()
      ..color = const Color(0xFF2563EB)
      ..strokeWidth = sw(3)
      ..strokeCap = StrokeCap.round;
    _drawDashedLine(canvas, p(95, 75), p(130, 75), dashPaint, sw(6), sw(4));

    // Teléfono (derecha)
    rrect(130, 20, 80, 140, 14, const Color(0xFF1E40AF));
    rrect(138, 30, 64, 10, 5, const Color(0xFF3B82F6));
    rrect(144, 48, 36, 3, 1.5, const Color(0x9993C5FD));
    rrect(144, 56, 52, 3, 1.5, const Color(0x9993C5FD));
    rrect(144, 64, 44, 3, 1.5, const Color(0x9993C5FD));
    rrect(144, 78, 52, 24, 6, const Color(0xFF2563EB));
    rrect(152, 86, 36, 3, 1.5, const Color(0xCCFFFFFF));
    rrect(152, 93, 24, 3, 1.5, const Color(0x80FFFFFF));

    // Check circle
    canvas.drawCircle(p(170, 135), sw(6), Paint()..color = const Color(0xFF22C55E));
    final checkPath = Path()
      ..moveTo(167 * sx, 135 * sy)
      ..lineTo(169.5 * sx, 137.5 * sy)
      ..lineTo(173 * sx, 133 * sy);
    canvas.drawPath(
      checkPath,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw(1.5)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Puntos de conexión
    canvas.drawCircle(p(95, 75), sw(4), Paint()..color = const Color(0xFF2563EB));
    canvas.drawCircle(p(130, 75), sw(4), Paint()..color = const Color(0xFF2563EB));
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint, double dash, double gap) {
    final total = (end - start).distance;
    final direction = (end - start) / total;
    double covered = 0;
    while (covered < total) {
      final segEnd = covered + dash < total ? covered + dash : total;
      canvas.drawLine(start + direction * covered, start + direction * segEnd, paint);
      covered += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
