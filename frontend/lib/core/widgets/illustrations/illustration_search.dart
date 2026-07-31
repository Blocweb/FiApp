import 'package:flutter/material.dart';

/// Ilustración de "búsqueda" para el onboarding, replicando el SVG
/// `IllustrationSearch` original (viewBox 0 0 240 200).
class IllustrationSearch extends StatelessWidget {
  const IllustrationSearch({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite ? constraints.maxWidth : 240.0;
        final clamped = width > 240 ? 240.0 : width;
        return SizedBox(
          width: clamped,
          height: clamped * (200 / 240),
          child: CustomPaint(painter: _SearchPainter()),
        );
      },
    );
  }
}

class _SearchPainter extends CustomPainter {
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

    // Documento de fondo
    rrect(40, 40, 160, 120, 12, const Color(0xFFEFF6FF));
    rrect(52, 56, 136, 10, 5, const Color(0xFFBFDBFE));
    rrect(52, 74, 100, 8, 4, const Color(0xFFDBEAFE));
    rrect(52, 90, 120, 8, 4, const Color(0xFFDBEAFE));
    rrect(52, 106, 80, 8, 4, const Color(0xFFDBEAFE));
    rrect(52, 122, 110, 8, 4, const Color(0xFFDBEAFE));

    // Lupa
    canvas.drawCircle(
      p(155, 95),
      sw(35),
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      p(155, 95),
      sw(35),
      Paint()
        ..color = const Color(0xFF2563EB)
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw(4),
    );
    canvas.drawCircle(p(155, 95), sw(24), Paint()..color = const Color(0xFFEFF6FF));
    rrect(143, 92, 24, 6, 3, const Color(0x662563EB));
    rrect(143, 100, 16, 4, 2, const Color(0x4D2563EB));

    canvas.drawLine(
      p(179, 119),
      p(196, 140),
      Paint()
        ..color = const Color(0xFF2563EB)
        ..strokeWidth = sw(5)
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawCircle(p(155, 95), sw(8), Paint()..color = const Color(0x262563EB));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
