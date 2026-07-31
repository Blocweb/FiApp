import 'package:flutter/material.dart';
import 'package:fiapp/core/theme/app_colors.dart';

/// Ícono del logo de FiApp: una libreta con un check verde superpuesto,
/// replicando el SVG de 52x52 usado en Splash y Login.
class AppLogoIcon extends StatelessWidget {
  final double size;

  const AppLogoIcon({super.key, this.size = 52});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.2),
        child: Image.asset(
          'assets/images/logo.png',
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return CustomPaint(painter: _LogoPainter());
          },
        ),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 52;
    final sy = size.height / 52;
    Offset p(double x, double y) => Offset(x * sx, y * sy);
    double sw(double v) => v * sx;

    void rrect(double x, double y, double w, double h, double r, Color color) {
      final rect = Rect.fromLTWH(x * sx, y * sy, w * sx, h * sy);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(r * sx)),
        Paint()..color = color,
      );
    }

    // Cuerpo de la libreta
    rrect(6, 8, 28, 36, 6, const Color(0xE6FFFFFF));
    rrect(10, 14, 20, 3, 1.5, AppColors.blue);
    rrect(10, 21, 14, 2.5, 1.25, AppColors.blue.withValues(alpha: 0.5));
    rrect(10, 27, 16, 2.5, 1.25, AppColors.blue.withValues(alpha: 0.5));

    // Círculo de check
    canvas.drawCircle(p(38, 34), sw(10), Paint()..color = AppColors.green);
    final checkPath = Path()
      ..moveTo(33 * sx, 34 * sy)
      ..lineTo(36.5 * sx, 37.5 * sy)
      ..lineTo(43 * sx, 31 * sy);
    canvas.drawPath(
      checkPath,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw(2)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
