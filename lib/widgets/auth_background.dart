import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Moving pools of light behind the frosted authentication form.
class AuthBackground extends StatefulWidget {
  final Widget child;
  const AuthBackground({super.key, required this.child});

  @override
  State<AuthBackground> createState() => _AuthBackgroundState();
}

class _AuthBackgroundState extends State<AuthBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      _controller.value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.bg,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _AuthLightPainter(
                    animation: _controller,
                    primary: AppColors.primary,
                    isDark: AppColors.bg.computeLuminance() < 0.5,
                  ),
                ),
              ),
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}

/// Repaints only the light layer; typing and the form do not rebuild per frame.
/// Radial shaders provide soft falloff without full-screen blur filters.
class _AuthLightPainter extends CustomPainter {
  final Animation<double> animation;
  final Color primary;
  final bool isDark;

  _AuthLightPainter({
    required this.animation,
    required this.primary,
    required this.isDark,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final phase = animation.value * math.pi * 2;
    final radius = math.min(size.width * 0.72, size.height * 0.48);
    final strength = isDark ? 1.0 : 0.75;

    void glow(Offset center, double extent, Color color, double opacity) {
      final bounds = Rect.fromCircle(center: center, radius: extent);
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: opacity * strength),
            color.withValues(alpha: opacity * strength * 0.42),
            color.withValues(alpha: 0),
          ],
          stops: const [0, 0.42, 1],
        ).createShader(bounds);
      canvas.drawCircle(center, extent, paint);
    }

    glow(
      Offset(size.width * (0.5 + 0.34 * math.sin(phase)),
          size.height * (0.42 + 0.22 * math.cos(phase))),
      radius,
      primary,
      0.40 + 0.05 * math.sin(phase),
    );
    glow(
      Offset(size.width * (0.5 + 0.36 * math.sin(phase + math.pi)),
          size.height * (0.52 + 0.24 * math.cos(phase + math.pi))),
      radius * 0.85,
      const Color(0xFF38BDF8),
      0.24,
    );
    glow(
      Offset(size.width * (0.5 + 0.26 * math.cos(phase + 1.2)),
          size.height * (0.64 + 0.15 * math.sin(phase + 1.2))),
      radius * 0.7,
      primary,
      0.20,
    );
  }

  @override
  bool shouldRepaint(covariant _AuthLightPainter oldDelegate) =>
      oldDelegate.animation != animation ||
      oldDelegate.primary != primary ||
      oldDelegate.isDark != isDark;
}
