import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A friendly empty state for transaction/summary screens: a softly
/// pulsing icon badge plus a warm Persian message. Built with pure
/// Flutter animations (no external Lottie/SVG asset) so it never breaks
/// on a fresh clone that doesn't have extra asset files bundled.
class EmptyState extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const EmptyState({
    super.key,
    this.icon = Icons.receipt_long_rounded,
    this.title = 'هنوز تراکنشی ثبت نکردی!',
    this.subtitle = 'با زدن دکمه + اولین خرج یا درآمدت رو ثبت کن',
  });

  @override
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final scale = 1.0 + (_controller.value * 0.08);
                final glow = 0.15 + (_controller.value * 0.20);
                return Transform.translate(
                  offset: Offset(0, -6 * _controller.value),
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.cyan.withValues(alpha: glow),
                            AppColors.cyan.withValues(alpha: 0.02),
                          ],
                        ),
                      ),
                      child: Icon(widget.icon, size: 42, color: AppColors.cyan),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 22),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text),
            ),
            const SizedBox(height: 8),
            Text(
              widget.subtitle,
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontSize: 13, color: AppColors.muted, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}
