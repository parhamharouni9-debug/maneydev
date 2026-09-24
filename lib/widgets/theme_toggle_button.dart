import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';

/// The sun/moon switch: tap to flip between dark and light themes.
/// Shows a sun in light mode (tap to go dark) and a moon in dark mode
/// (tap to go light), with a quick rotate+fade transition between icons.
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController.instance.isDark;
    return IconButton(
      tooltip: isDark ? 'تم روشن' : 'تم تاریک',
      onPressed: () => ThemeController.instance.toggle(),
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, anim) => RotationTransition(
          turns: anim,
          child: FadeTransition(opacity: anim, child: child),
        ),
        child: Icon(
          isDark ? Icons.dark_mode_rounded : Icons.wb_sunny_rounded,
          key: ValueKey(isDark),
          color: isDark ? AppColors.cyan : AppColors.warning,
        ),
      ),
    );
  }
}
