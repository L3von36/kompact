import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ── Kompact Design System ──────────────────────────────────────────────────
/// Compact design language: maximum information density in minimal space.
/// Dense type scale (10–22px), 2/4/6/8/12/16 spacing ladder, hairline borders,
/// flat surfaces, semantic status colors for fleet operations.

class K {
  // Spacing ladder (2px base unit).
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 6;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
  static const double xxl = 20;
  static const double xxxl = 28;

  // Radius.
  static const double rSm = 4;
  static const double rMd = 6;
  static const double rLg = 10;

  // Typography scale — dense.
  static const double micro = 9; // uppercase chips
  static const double caption = 10;
  static const double label = 11;
  static const double body = 12;
  static const double subtitle = 13;
  static const double title = 14;
  static const double headline = 17;
  static const double display = 22;

  // Component metrics.
  static const double tableRow = 32;
  static const double tableRowMobile = 40;
  static const double railWidth = 190;
  static const double railWidthCollapsed = 56;

  // Motion.
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration med = Duration(milliseconds: 250);
}

/// Light + dark palettes of the Kompact design system.
class KPallette {
  final Color bg;
  final Color surface;
  final Color surfaceAlt;
  final Color surfaceSunken;
  final Color border;
  final Color borderStrong;
  final Color text;
  final Color textSecondary;
  final Color textTertiary;
  final Color primary;
  final Color primaryFg;
  final Color primarySoft;
  final Color accent;
  final Color accentSoft;

  // Fleet semantics.
  final Color good;
  final Color goodSoft;
  final Color satisfactory;
  final Color satisfactorySoft;
  final Color urgent;
  final Color urgentSoft;
  final Color critical;
  final Color criticalSoft;
  final Color info;
  final Color infoSoft;

  const KPallette({
    required this.bg,
    required this.surface,
    required this.surfaceAlt,
    required this.surfaceSunken,
    required this.border,
    required this.borderStrong,
    required this.text,
    required this.textSecondary,
    required this.textTertiary,
    required this.primary,
    required this.primaryFg,
    required this.primarySoft,
    required this.accent,
    required this.accentSoft,
    required this.good,
    required this.goodSoft,
    required this.satisfactory,
    required this.satisfactorySoft,
    required this.urgent,
    required this.urgentSoft,
    required this.critical,
    required this.criticalSoft,
    required this.info,
    required this.infoSoft,
  });

  static const light = KPallette(
    bg: Color(0xFFF4F6F9),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF0F3F7),
    surfaceSunken: Color(0xFFE9EDF3),
    border: Color(0xFFE1E6ED),
    borderStrong: Color(0xFFC9D2DE),
    text: Color(0xFF101828),
    textSecondary: Color(0xFF4A5568),
    textTertiary: Color(0xFF8794A7),
    primary: Color(0xFF2563EB),
    primaryFg: Color(0xFFFFFFFF),
    primarySoft: Color(0xFFE3ECFD),
    accent: Color(0xFFEA580C),
    accentSoft: Color(0xFFFDEBDD),
    good: Color(0xFF15803D),
    goodSoft: Color(0xFFE4F4E9),
    satisfactory: Color(0xFF0E7490),
    satisfactorySoft: Color(0xFFE0F2F7),
    urgent: Color(0xFFB45309),
    urgentSoft: Color(0xFFFCEFDB),
    critical: Color(0xFFB91C1C),
    criticalSoft: Color(0xFFFBE5E5),
    info: Color(0xFF1D4ED8),
    infoSoft: Color(0xFFE5EDFC),
  );

  static const dark = KPallette(
    bg: Color(0xFF0B0F16),
    surface: Color(0xFF111722),
    surfaceAlt: Color(0xFF182031),
    surfaceSunken: Color(0xFF0D1320),
    border: Color(0xFF222C40),
    borderStrong: Color(0xFF33415C),
    text: Color(0xFFE7ECF4),
    textSecondary: Color(0xFF9AA7BB),
    textTertiary: Color(0xFF64748B),
    primary: Color(0xFF3B82F6),
    primaryFg: Color(0xFFFFFFFF),
    primarySoft: Color(0xFF16233D),
    accent: Color(0xFFF97316),
    accentSoft: Color(0xFF33210F),
    good: Color(0xFF4ADE80),
    goodSoft: Color(0xFF0E2A1B),
    satisfactory: Color(0xFF38BDF8),
    satisfactorySoft: Color(0xFF0C2431),
    urgent: Color(0xFFFBBF24),
    urgentSoft: Color(0xFF332408),
    critical: Color(0xFFF87171),
    criticalSoft: Color(0xFF3A1214),
    info: Color(0xFF60A5FA),
    infoSoft: Color(0xFF14213B),
  );
}

/// Inherited palette accessor: `context.pal`.
extension KPalletteX on BuildContext {
  KPallette get pal =>
      Theme.of(this).brightness == Brightness.dark ? KPallette.dark : KPallette.light;
}

/// Builds the Material theme on top of the Kompact tokens.
class AppTheme {
  static const _family = 'Inter';

  static ThemeData light([int accentIndex = 0, bool dense = true]) =>
      _build(KPallette.light, Brightness.light, accentIndex, dense);

  static ThemeData dark([int accentIndex = 0, bool dense = true]) =>
      _build(KPallette.dark, Brightness.dark, accentIndex, dense);

  static ThemeData _build(KPallette p, Brightness b, int accentIndex, bool dense) {
    final density = dense ? VisualDensity.compact : VisualDensity.standard;
    final scheme = ColorScheme.fromSeed(
      seedColor: accentIndex == 1 ? const Color(0xFF4F46E5) : accentIndex == 2 ? const Color(0xFF0D9488) : p.primary,
      brightness: b,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: scheme,
      visualDensity: density,
      splashFactory: dense ? NoSplash.splashFactory : null,
      fontFamily: _family,
      dividerColor: p.border,
      scaffoldBackgroundColor: p.bg,
      canvasColor: p.bg,
      cardColor: p.surface,
    );

    return base.copyWith(
      textTheme: _textTheme(b, p),
      textButtonTheme: _textBtn(p),
      filledButtonTheme: _filledBtn(p),
      outlinedButtonTheme: _outlinedBtn(p),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          visualDensity: density,
          minimumSize: const Size(34, 34),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(K.rSm)),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        textStyle: TextStyle(fontSize: K.label, color: p.text, fontFamily: _family),
        decoration: BoxDecoration(color: p.surfaceAlt, borderRadius: BorderRadius.circular(K.rSm), border: Border.all(color: p.border)),
        waitDuration: const Duration(milliseconds: 400),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: b == Brightness.dark ? const Color(0xFF1E293B) : const Color(0xFF101828),
        contentTextStyle: TextStyle(fontSize: K.body, color: Colors.white, fontFamily: _family),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(K.rMd)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(K.rLg), side: BorderSide(color: p.border)),
        titleTextStyle: TextStyle(fontSize: K.headline, fontWeight: FontWeight.w700, color: p.text, fontFamily: _family),
        contentTextStyle: TextStyle(fontSize: K.body, color: p.textSecondary, fontFamily: _family),
      ),
      dividerTheme: DividerThemeData(color: p.border, thickness: 1, space: 1),
      tabBarTheme: TabBarThemeData(
        labelColor: p.primary,
        unselectedLabelColor: p.textSecondary,
        indicatorColor: p.primary,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: TextStyle(fontSize: K.body, fontWeight: FontWeight.w600, fontFamily: _family),
        unselectedLabelStyle: TextStyle(fontSize: K.body, fontWeight: FontWeight.w500, fontFamily: _family),
        dividerColor: p.border,
        splashFactory: NoSplash.splashFactory,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(K.rMd), side: BorderSide(color: p.border)),
        textStyle: TextStyle(fontSize: K.body, color: p.text, fontFamily: _family),
        menuPadding: const EdgeInsets.symmetric(vertical: K.xs),
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: p.surfaceAlt,
        hintStyle: TextStyle(fontSize: K.body, color: p.textTertiary, fontFamily: _family),
        contentPadding: const EdgeInsets.symmetric(horizontal: K.sm, vertical: K.xs + 2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(K.rSm),
          borderSide: BorderSide(color: p.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(K.rSm),
          borderSide: BorderSide(color: p.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(K.rSm),
          borderSide: BorderSide(color: p.primary, width: 1.5),
        ),
      ),
      switchTheme: SwitchThemeData(
        trackOutlineColor: WidgetStateProperty.resolveWith((s) => Colors.transparent),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      sliderTheme: const SliderThemeData(
        trackHeight: 3,
        showValueIndicator: ShowValueIndicator.onDrag,
      ),
      checkboxTheme: CheckboxThemeData(
        visualDensity: density,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
        side: BorderSide(color: p.borderStrong, width: 1.5),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.primary,
        linearTrackColor: p.surfaceSunken,
        circularTrackColor: p.surfaceSunken,
      ),
    );
  }

  static TextTheme _textTheme(Brightness b, KPallette p) {
    final c1 = p.text;
    final c2 = p.textSecondary;
    final c3 = p.textTertiary;
    return TextTheme(
      displaySmall: TextStyle(fontSize: K.display, height: 1.15, fontWeight: FontWeight.w800, color: c1, letterSpacing: -0.5, fontFamily: _family),
      headlineSmall: TextStyle(fontSize: K.headline, height: 1.2, fontWeight: FontWeight.w700, color: c1, letterSpacing: -0.3, fontFamily: _family),
      titleMedium: TextStyle(fontSize: K.title, height: 1.3, fontWeight: FontWeight.w700, color: c1, fontFamily: _family),
      titleSmall: TextStyle(fontSize: K.subtitle, height: 1.3, fontWeight: FontWeight.w600, color: c1, fontFamily: _family),
      bodyMedium: TextStyle(fontSize: K.body, height: 1.4, fontWeight: FontWeight.w400, color: c2, fontFamily: _family),
      bodySmall: TextStyle(fontSize: K.label, height: 1.35, fontWeight: FontWeight.w400, color: c2, fontFamily: _family),
      labelLarge: TextStyle(fontSize: K.body, height: 1.2, fontWeight: FontWeight.w600, color: c1, fontFamily: _family),
      labelMedium: TextStyle(fontSize: K.label, height: 1.2, fontWeight: FontWeight.w600, color: c2, fontFamily: _family),
      labelSmall: TextStyle(
        fontSize: K.caption,
        height: 1.2,
        fontWeight: FontWeight.w500,
        color: c3,
        fontFamily: _family,
        letterSpacing: 0.1,
      ),
    );
  }

  static TextButtonThemeData _textBtn(KPallette p) => TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.primary,
          textStyle: TextStyle(fontSize: K.body, fontWeight: FontWeight.w600, fontFamily: _family),
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(K.rSm)),
        ),
      );

  static FilledButtonThemeData _filledBtn(KPallette p) => FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: p.primaryFg,
          textStyle: TextStyle(fontSize: K.body, fontWeight: FontWeight.w600, fontFamily: _family),
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: const EdgeInsets.symmetric(horizontal: K.lg, vertical: K.sm + 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(K.rSm)),
        ),
      );

  static OutlinedButtonThemeData _outlinedBtn(KPallette p) => OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.text,
          side: BorderSide(color: p.borderStrong),
          textStyle: TextStyle(fontSize: K.body, fontWeight: FontWeight.w600, fontFamily: _family),
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: const EdgeInsets.symmetric(horizontal: K.lg, vertical: K.sm + 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(K.rSm)),
        ),
      );
}

/// Locks status-bar styling to the theme brightness.
void applySystemChrome(Brightness b) {
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: b == Brightness.dark ? Brightness.light : Brightness.dark,
      statusBarBrightness: b,
    ),
  );
}
