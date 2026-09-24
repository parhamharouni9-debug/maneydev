import 'package:flutter/material.dart';
import '../theme/theme_controller.dart';

/// Wrap a screen's returned Scaffold with this so it repaints the instant
/// the sun/moon toggle flips — without it, a screen that's already pushed
/// on the Navigator stack (Settings, Categories, ...) wouldn't otherwise
/// know the palette changed, since AppColors is a plain static getter and
/// not an InheritedWidget the framework tracks automatically.
///
/// [builder] is called fresh on every theme change (not just once and
/// cached) so every AppColors.* read inside re-evaluates against the new
/// palette — passing a pre-built `child` widget here would defeat the
/// purpose, since Flutter skips rebuilding a subtree it recognizes as an
/// unchanged widget instance.
class ThemeRebuilder extends StatelessWidget {
  final WidgetBuilder builder;
  const ThemeRebuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeController.instance,
      builder: (context, _) => builder(context),
    );
  }
}
