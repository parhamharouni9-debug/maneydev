import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme_controller.dart';

/// Curated, backend-compatible category colors for dark and light surfaces.
/// Existing stored hex values remain valid even when they are not in this list.
const categoryColorChoices = <String>[
  '#ff6b35', // orange
  '#ef4444', // red
  '#fb7185', // coral / rose
  '#f59e0b', // amber
  '#facc15', // yellow
  '#84cc16', // lime
  '#22c55e', // green
  '#34d399', // mint
  '#22d3ee', // cyan
  '#38bdf8', // sky
  '#3b82f6', // blue
  '#6366f1', // indigo
  '#8b5cf6', // violet
  '#a855f7', // purple
  '#ec4899', // pink
  '#94a3b8', // slate
];

/// A full color palette for one theme (dark or light).
class Palette {
  final Color bg;
  final Color bgGlow; // subtle radial accent behind hero content
  final Color cardBg;
  final Color cardBgAlt;
  final Color text;
  final Color muted;
  final Color primary; // cyan in dark, deep teal in light
  final Color secondary; // magenta
  final Color success; // green
  final Color warning; // amber
  final Color divider;
  final List<Color> categoryPalette;

  const Palette({
    required this.bg,
    required this.bgGlow,
    required this.cardBg,
    required this.cardBgAlt,
    required this.text,
    required this.muted,
    required this.primary,
    required this.secondary,
    required this.success,
    required this.warning,
    required this.divider,
    required this.categoryPalette,
  });

  // PoolMan approved reference design — dark: warm, premium, soft.
  // Exact hex values from the design brief (not reinterpreted).
  static const dark = Palette(
    bg: Color(0xFF0F1115),
    bgGlow: Color(0xFF1A1D22),
    cardBg: Color(0xFF1A1D22),
    cardBgAlt: Color(0xFF2A2F36),
    text: Color(0xFFF1F5F9),
    muted: Color(0xFF8B93A0),
    primary: Color(0xFFFF6B35),
    secondary: Color(0xFFEF4444),
    success: Color(0xFF22C55E),
    warning: Color(0xFFF5B93D),
    divider: Color(0x1FF1F5F9),
    categoryPalette: [
      Color(0xFFFF6B35),
      Color(0xFFEF4444),
      Color(0xFFFB7185),
      Color(0xFFF59E0B),
      Color(0xFFFACC15),
      Color(0xFF84CC16),
      Color(0xFF22C55E),
      Color(0xFF34D399),
      Color(0xFF22D3EE),
      Color(0xFF38BDF8),
      Color(0xFF3B82F6),
      Color(0xFF6366F1),
      Color(0xFF8B5CF6),
      Color(0xFFA855F7),
      Color(0xFFEC4899),
      Color(0xFF94A3B8),
    ],
  );

  // PoolMan approved reference design — light: warm/soft, never pure white.
  static const light = Palette(
    bg: Color(0xFFF5F2EE),
    bgGlow: Color(0xFFEDE8E2),
    cardBg: Color(0xFFEDE8E2),
    cardBgAlt: Color(0xFFDAD6CF),
    text: Color(0xFF334155),
    muted: Color(0xFF6B7280),
    primary: Color(0xFFFF6B35),
    secondary: Color(0xFFDC2626),
    success: Color(0xFF16A34A),
    warning: Color(0xFFB9740A),
    divider: Color(0x14334155),
    categoryPalette: [
      Color(0xFFFF6B35),
      Color(0xFFDC2626),
      Color(0xFFE11D48),
      Color(0xFFD97706),
      Color(0xFFCA8A04),
      Color(0xFF65A30D),
      Color(0xFF16A34A),
      Color(0xFF059669),
      Color(0xFF0891B2),
      Color(0xFF0284C7),
      Color(0xFF2563EB),
      Color(0xFF4F46E5),
      Color(0xFF7C5CF0),
      Color(0xFF9333EA),
      Color(0xFFDB2777),
      Color(0xFF64748B),
    ],
  );
}

/// Backward-compatible static accessors so every screen can keep writing
/// `AppColors.bg`, `AppColors.cyan`, etc. — but now these resolve live
/// against whichever palette [ThemeController] currently has active, so
/// the whole app repaints correctly when the person flips the sun/moon
/// toggle. (Widgets referencing these can no longer be `const`, which is
/// why the const keyword was stripped from the UI files.)
class AppColors {
  static Palette get _p =>
      ThemeController.instance.isDark ? Palette.dark : Palette.light;

  static Color get bg => _p.bg;
  static Color get bgGlow => _p.bgGlow;
  static Color get cardBg => _p.cardBg;
  static Color get cardBgAlt => _p.cardBgAlt;
  static Color get text => _p.text;
  static Color get muted => _p.muted;
  static Color get cyan => _p.primary;
  static Color get magenta => _p.secondary;
  static Color get primary => _p.primary;
  static Color get secondary => _p.secondary;
  static Color get green => _p.success;
  static Color get success => _p.success;
  static Color get amber => _p.warning;
  static Color get warning => _p.warning;
  static Color get divider => _p.divider;
  static List<Color> get categoryPalette => _p.categoryPalette;
}

class AppTheme {
  static ThemeData _build(Palette p, Brightness brightness) {
    final base = ThemeData(brightness: brightness, useMaterial3: true);
    final vazirTextTheme = GoogleFonts.vazirmatnTextTheme(base.textTheme)
        .apply(
          bodyColor: p.text,
          displayColor: p.text,
        )
        .copyWith(
          // Explicit hierarchy — balance figures, section titles, body and
          // captions all read at clearly different weights/sizes instead of
          // defaulting to Material's generic scale.
          displayLarge: GoogleFonts.vazirmatn(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: p.text,
              height: 1.2),
          headlineSmall: GoogleFonts.vazirmatn(
              fontSize: 19, fontWeight: FontWeight.w800, color: p.text),
          titleMedium: GoogleFonts.vazirmatn(
              fontSize: 15, fontWeight: FontWeight.w700, color: p.text),
          bodyMedium: GoogleFonts.vazirmatn(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: p.text,
              height: 1.6),
          bodySmall: GoogleFonts.vazirmatn(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: p.muted,
              height: 1.6),
          labelSmall: GoogleFonts.vazirmatn(
              fontSize: 11, fontWeight: FontWeight.w500, color: p.muted),
          labelLarge: GoogleFonts.vazirmatn(
              fontSize: 15, fontWeight: FontWeight.w700, color: p.text),
        );
    return base.copyWith(
      scaffoldBackgroundColor: p.bg,
      textTheme: vazirTextTheme,
      colorScheme: base.colorScheme.copyWith(
        brightness: brightness,
        primary: p.primary,
        secondary: p.secondary,
        surface: p.cardBg,
        error: p.secondary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: p.bg,
        foregroundColor: p.text,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.vazirmatn(
          color: p.text,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: base.cardTheme.copyWith(
        color: p.cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: p.primary.withValues(alpha: 0.08)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.cardBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: p.primary.withValues(alpha: 0.18)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: p.primary.withValues(alpha: 0.18)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: p.primary, width: 1.4),
        ),
        labelStyle: TextStyle(color: p.muted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          // A touch deeper/muted than the raw brand orange for large
          // filled buttons — the same accent, just less overwhelming
          // across a big solid area than the pure saturated hex.
          backgroundColor:
              Color.alphaBlend(Colors.black.withValues(alpha: 0.08), p.primary),
          foregroundColor: p.bg,
          textStyle: GoogleFonts.vazirmatn(
              fontSize: 15.5, fontWeight: FontWeight.w700),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(vertical: 18),
          minimumSize: const Size.fromHeight(52),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: p.cardBg,
        selectedItemColor: p.primary,
        unselectedItemColor: p.muted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerColor: p.divider,
    );
  }

  static ThemeData get dark => _build(Palette.dark, Brightness.dark);
  static ThemeData get light => _build(Palette.light, Brightness.light);

  static Color categoryColor(String? hex) {
    if (hex == null) return AppColors.cyan;
    final clean = hex.replaceAll('#', '');
    if (clean.length != 6) return AppColors.cyan;
    return Color(int.parse('FF$clean', radix: 16));
  }

  /// Subtle radial glow used behind hero cards (balance ring, headers)
  /// to give the flat cards real depth instead of a plain fill.
  static BoxDecoration glowBackdrop() {
    final p = ThemeController.instance.isDark ? Palette.dark : Palette.light;
    return BoxDecoration(
      gradient: RadialGradient(
        center: const Alignment(0, -0.6),
        radius: 1.2,
        colors: [p.bgGlow.withValues(alpha: 0.55), p.bg],
      ),
    );
  }
}
