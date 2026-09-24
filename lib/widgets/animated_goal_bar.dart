import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A progress bar that animates smoothly to its new value (instead of
/// snapping) and grows a soft neon glow as it fills — used for the
/// monthly savings goal so hitting a new percentage actually *feels*
/// like something happened.
class AnimatedGoalBar extends StatelessWidget {
  final double value; // 0..1
  final Color color;
  final double height;

  const AnimatedGoalBar({
    super.key,
    required this.value,
    required this.color,
    this.height = 12,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: clamped),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, _) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(height / 2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.06 + animatedValue * 0.10),
                blurRadius: 6,
                spreadRadius: 0,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(height / 2),
            child: LinearProgressIndicator(
              value: animatedValue == 0 ? 0.001 : animatedValue,
              minHeight: height,
              backgroundColor: AppColors.bg,
              color: color,
            ),
          ),
        );
      },
    );
  }
}
