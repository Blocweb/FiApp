import 'package:flutter/material.dart';
import 'package:fiapp/core/theme/app_animations.dart';

/// Envuelve a un widget para darle la animación de "presionado" que tenía
/// la clase CSS `.pressed` del prototipo original:
/// ```css
/// .pressed { transition: transform 0.1s ease, opacity 0.1s ease; }
/// .pressed:active { transform: scale(0.97); opacity: 0.85; }
/// ```
class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool enabled;

  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.enabled = true,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!widget.enabled) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.enabled ? widget.onTap : null,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: AppAnimations.pressed,
        curve: AppAnimations.pressedCurve,
        child: AnimatedOpacity(
          opacity: _pressed ? 0.85 : 1.0,
          duration: AppAnimations.pressed,
          curve: AppAnimations.pressedCurve,
          child: widget.child,
        ),
      ),
    );
  }
}
