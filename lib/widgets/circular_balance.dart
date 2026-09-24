import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/persian_numbers.dart';

/// A large circular gauge showing the month's balance in the center and a
/// progress ring around it representing how much of this month's income
/// has already been spent. Styled like a motorcycle tachometer face —
/// radial tick marks around the rim, a glowing needle-sweep ring — since
/// that's a look with real personal meaning here, not a generic dial.
class CircularBalance extends StatelessWidget {
  final num balance;
  final num income;
  final num expense;
  final double size;

  const CircularBalance({
    super.key,
    required this.balance,
    required this.income,
    required this.expense,
    this.size = 220,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = income > 0 ? (expense / income).clamp(0.0, 1.0) : 0.0;
    final overBudget = income > 0 && expense > income;
    final ringColor = overBudget
        ? AppColors.secondary
        : (ratio > 0.75 ? AppColors.warning : AppColors.primary);
    final positive = balance >= 0;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Soft glow behind the ring for depth.
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: ringColor.withValues(alpha: 0.38),
                  blurRadius: 46,
                  spreadRadius: 4,
                ),
              ],
            ),
          ),
          // Tachometer-style tick marks around the rim.
          SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: _GaugeTicksPainter(
                color: AppColors.muted.withValues(alpha: 0.5),
                activeColor: ringColor,
                activeRatio: ratio,
              ),
            ),
          ),
          // Track.
          SizedBox(
            width: size * 0.82,
            height: size * 0.82,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: 8,
              strokeCap: StrokeCap.round,
              color: AppColors.cardBgAlt,
            ),
          ),
          // Progress.
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: ratio),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => SizedBox(
              width: size * 0.82,
              height: size * 0.82,
              child: CircularProgressIndicator(
                value: value == 0 ? 0.001 : value,
                strokeWidth: 8,
                strokeCap: StrokeCap.round,
                color: ringColor,
                backgroundColor: Colors.transparent,
              ),
            ),
          ),
          // Center content.
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('موجودی این ماه',
                  style: TextStyle(color: AppColors.muted, fontSize: 12.5)),
              const SizedBox(height: 6),
              Text(
                PersianNumbers.formatAmount(balance),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: size * 0.125,
                  fontWeight: FontWeight.w800,
                  color: positive ? AppColors.text : AppColors.secondary,
                ),
              ),
              Text('تومان',
                  style: TextStyle(color: AppColors.muted, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Draws small radial lines around the rim like a tachometer face —
/// evenly spaced minor ticks, with every 5th tick longer and brighter.
/// Ticks that fall within the current spend ratio light up in the
/// gauge's active color.
class _GaugeTicksPainter extends CustomPainter {
  final Color color;
  final Color activeColor;
  final double activeRatio;
  static const int tickCount = 40;

  _GaugeTicksPainter({
    required this.color,
    required this.activeColor,
    required this.activeRatio,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2;
    final activeTicks = (tickCount * activeRatio).round();

    for (int i = 0; i < tickCount; i++) {
      final angle = (i / tickCount) * 2 * math.pi - math.pi / 2;
      final isMajor = i % 5 == 0;
      final tickLength = isMajor ? 10.0 : 5.0;
      final innerRadius = outerRadius - tickLength;

      final p1 =
          center + Offset(math.cos(angle), math.sin(angle)) * innerRadius;
      final p2 =
          center + Offset(math.cos(angle), math.sin(angle)) * outerRadius;

      final isActive = i < activeTicks;
      final paint = Paint()
        ..color = isActive ? activeColor : color
        ..strokeWidth = isMajor ? 2.4 : 1.4
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(p1, p2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GaugeTicksPainter oldDelegate) =>
      oldDelegate.activeRatio != activeRatio ||
      oldDelegate.activeColor != activeColor ||
      oldDelegate.color != color;
}
