import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Gives the bear a deliberate "peeking over the form" composition.
/// The Rive artwork itself ends at the bottom of its artboard. A narrow glass
/// ledge hides that edge so the bear appears to lean over the form.
class AuthMascotStage extends StatelessWidget {
  final Widget mascot;

  const AuthMascotStage({super.key, required this.mascot});

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.primary;
    return Center(
      child: SizedBox(
        width: 264,
        height: 198,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Positioned(
              bottom: 8,
              child: Container(
                width: 174,
                height: 68,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.18),
                      blurRadius: 54,
                      spreadRadius: 15,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: -44,
              child: SizedBox(width: 240, height: 240, child: mascot),
            ),
            Positioned(
              bottom: 0,
              child: Container(
                width: 242,
                height: 22,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [
                      AppColors.cardBgAlt.withValues(alpha: 0.58),
                      AppColors.cardBgAlt.withValues(alpha: 0.92),
                      AppColors.cardBgAlt.withValues(alpha: 0.58),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
