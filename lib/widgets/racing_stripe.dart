import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A thin diagonal racing-stripe divider — the one recurring signature
/// element tying every screen back to the "Pulse" motorsport look.
/// Used sparingly (once per screen, near the hero content) rather than
/// as generic decoration everywhere.
class RacingStripe extends StatelessWidget {
  final double height;
  final EdgeInsetsGeometry margin;

  const RacingStripe({
    super.key,
    this.height = 3,
    this.margin = const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(height / 2),
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0),
            AppColors.primary.withValues(alpha: 0.65),
            AppColors.primary.withValues(alpha: 0),
          ],
          stops: const [0, 0.5, 1],
        ),
      ),
    );
  }
}
