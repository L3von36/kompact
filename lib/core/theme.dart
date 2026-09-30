import 'package:flutter/material.dart';

import '../core/models.dart';

/// Kompact design system — compact, dense, high-signal UI.
///
/// Compact-design rules encoded here:
///  * 4px micro-grid, tight type scale (body 13, caption 11)
///  * hairline borders instead of heavy elevation
///  * `VisualDensity.compact` by default
///  * one accent hue carries color hierarchy; everything else stays neutral
abstract final class K {
  // ---- type ----
  static const String fontFamily = 'Inter';

  // ---- spacing (4px grid) ----
  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 24;

  // ---- radii ----
  static const double r = 10; // cards
  static const double rS = 7; // chips, inputs

  // ---- control heights (compact) ----
  static const double controlH = 34;
  static const double inputH = 38;

  // ---- accent options ----
  static const List<(String, Color)> accents = [
    ('Indigo', Color(0xFF6E7BFF)),
    ('Mint', Color(0xFF35D0A0)),
    ('Sky', Color(0xFF4FB8FF)),
    ('Coral', Color(0xFFFF7A59)),
    ('Violet', Color(0xFFB07CFF)),
    ('Amber', Color(0xFFF2B94B)),
  ];

  static Color accent(int index) => accents[index % accents.length].$2;

  // ---- semantic ----
  static const Color success = Color(0xFF3DDC97);
  static const Color warning = Color(0xFFFFB454);
  static const Color danger = Color(0xFFFF6B6B);

  static Color priorityColor(Priority p) => switch (p) {
        Priority.high => danger,
        Priority.medium => warning,
        Priority.low => Color(0xFF4FB8FF),
      };

  // ---- category dots (stable per name) ----
  static const List<Color> categoryColors = [
    Color(0xFF6E7BFF),
    Color(0xFF35D0A0),
    Color(0xFF4FB8FF),
    Color(0xFFFF7A59),
    Color(0xFFB07CFF),
    Color(0xFFF2B94B),
    Color(0xFFFF8FB1),
    Color(0xFF7FD8F2),
  ];

  static Color categoryColor(String name) {
    var h = 0;
    for (final c in name.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    return categoryColors[h % categoryColors.length];
  }

  // ---- note tints (index-based) ----
  static const List<Color> noteTints = [
    Color(0xFF6E7BFF),
    Color(0xFF35D0A0),
    Color(0xFFF2B94B),
    Color(0xFFFF7A59),
    Color(0xFF4FB8FF),
    Color(0xFFB07CFF),
  ];
}

/// Builds the light/dark [ThemeData] for Kompact.
class AppTheme {
  static const String fontFamily = 'Inter';

  static ThemeData dark(int accentIndex, DensityMode density) {
    final accent = K.accent(accentIndex);
    final scheme = ColorScheme.dark(
      primary: accent,
      onPrimary: Colors.white,
      secondary: accent,
      surface: const Color(0xFF12151B),
      surfaceContainerHighest: const Color(0xFF191D24),
      onSurface: const Color(0xFFE8EAF0),
      onSurfaceVariant: const Color(0xFF9AA3B2),
      outline: Colors.white.withValues(alpha: 0.08),
      error: K.danger,
    );
    return _base(scheme, accent, density, isDark: true);
  }

  static ThemeData light(int accentIndex, DensityMode density) {
    final accent = _readableAccent(accentIndex);
    final scheme = ColorScheme.light(
      primary: accent,
      onPrimary: Colors.white,
      secondary: accent,
      surface: Colors.white,
      surfaceContainerHighest: const Color(0xFFEEF1F6),
      onSurface: const Color(0xFF171B22),
      onSurfaceVariant: const Color(0xFF5B6472),
      outline: Colors.black.withValues(alpha: 0.08),
      error: K.danger,
    );
    return _base(scheme, accent, density, isDark: false);
  }

  /// Some accents are too light for white text / too pale on white surfaces.
  static Color _readableAccent(int index) {
    final c = K.accent(index);
    if (c == const Color(0xFFF2B94B)) return const Color(0xFFB07E0C); // amber
    return c;
  }

  static ThemeData _base(
    ColorScheme scheme,
    Color accent,
    DensityMode density, {
    required bool isDark,
  }) {
    final visualDensity = density == DensityMode.compact
        ? VisualDensity.compact
        : VisualDensity.standard;

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      visualDensity: visualDensity,
      fontFamily: fontFamily,
      splashFactory: InkSparkle.splashFactory,
      dividerColor: scheme.outline,
    );

    return base.copyWith(
      textTheme: _textTheme(base.textTheme, isDark),
      scaffoldBackgroundColor: isDark ? const Color(0xFF0A0C10) : const Color(0xFFF3F5F9),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? const Color(0xFF0A0C10) : const Color(0xFFF3F5F9),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 15,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: scheme.onSurface,
        ),
        iconTheme: IconThemeData(color: scheme.onSurface, size: 20),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(K.r),
          side: BorderSide(color: scheme.outline),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outline,
        thickness: 1,
        space: 1,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: isDark ? const Color(0xFF0A0C10) : const Color(0xFFF3F5F9),
        selectedIconTheme: IconThemeData(color: accent, size: 20),
        unselectedIconTheme: IconThemeData(color: scheme.onSurfaceVariant, size: 20),
        selectedLabelTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: accent,
        ),
        unselectedLabelTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 10.5,
          fontWeight: FontWeight.w500,
          color: scheme.onSurfaceVariant,
        ),
        indicatorColor: accent.withValues(alpha: 0.14),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? const Color(0xFF0E1116) : Colors.white,
        indicatorColor: accent.withValues(alpha: 0.14),
        height: 62,
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 21,
            color: states.contains(WidgetState.selected)
                ? accent
                : scheme.onSurfaceVariant,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontFamily: fontFamily,
            fontSize: 10.5,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? accent
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF191D24) : const Color(0xFFEEF1F6),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant.withValues(alpha: 0.7)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(K.rS),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(K.rS),
          borderSide: BorderSide(color: accent, width: 1.4),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, K.controlH),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(K.rS)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, K.controlH),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          side: BorderSide(color: scheme.outline),
          foregroundColor: scheme.onSurface,
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(K.rS)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 34),
          foregroundColor: accent,
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: scheme.onSurfaceVariant,
          minimumSize: const Size(34, 34),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          iconSize: 19,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        side: BorderSide(color: scheme.onSurfaceVariant.withValues(alpha: 0.5), width: 1.5),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? const Color(0xFF22272F) : const Color(0xFF20242C),
        contentTextStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 13,
          color: Colors.white,
        ),
        actionTextColor: accent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(K.rS)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: isDark ? const Color(0xFF1B2028) : Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(K.r),
          side: BorderSide(color: scheme.outline),
        ),
        position: PopupMenuPosition.under,
        textStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(K.r + 4),
          side: BorderSide(color: scheme.outline),
        ),
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: scheme.onSurface,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : scheme.onSurfaceVariant,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? accent : scheme.outline,
        ),
      ),
      tooltipTheme: TooltipThemeData(
        textStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 11,
          color: isDark ? Colors.white : Colors.white,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF22272F) : const Color(0xFF20242C),
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }

  /// Compact type scale on top of the platform default.
  static TextTheme _textTheme(TextTheme base, bool isDark) {
    final c = isDark ? const Color(0xFFE8EAF0) : const Color(0xFF171B22);
    final med = isDark ? const Color(0xFF9AA3B2) : const Color(0xFF5B6472);
    return base
        .apply(
          fontFamily: fontFamily,
          bodyColor: c,
          displayColor: c,
        )
        .copyWith(
          displaySmall: TextStyle(
            fontFamily: 'InterDisplay',
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.8,
            height: 1.1,
            color: c,
          ),
          titleLarge: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -0.3, color: c),
          titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: -0.2, color: c),
          titleSmall: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, letterSpacing: -0.1, color: c),
          bodyLarge: TextStyle(fontSize: 13.5, height: 1.45, color: c),
          bodyMedium: TextStyle(fontSize: 13, height: 1.4, color: c),
          bodySmall: TextStyle(fontSize: 11.5, height: 1.35, color: med),
          labelLarge: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c),
          labelMedium: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: med),
          labelSmall: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: med,
          ),
        );
  }
}

/// Uppercase micro-label used across section headers and chips.
TextStyle microLabel(BuildContext context, {Color? color}) => TextStyle(
      fontFamily: K.fontFamily,
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.8,
      color: color ?? Theme.of(context).colorScheme.onSurfaceVariant,
    );
