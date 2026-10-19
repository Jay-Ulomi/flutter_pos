import 'package:flutter/material.dart';
import 'brand_colors.dart';

/// Material 3 theme for the Aduinola redesign.
///
/// Look: white rounded cards on a soft green-grey gradient ([AppDecor.background]),
/// fully rounded (pill) inputs and buttons, round icon buttons, a deep-green
/// primary with orange secondary actions, and the Outfit typeface (bundled, so it
/// works offline).
class AppTheme {
  AppTheme._();

  // ── Shape tokens ─────────────────────────────────────────────────────────
  static const double radiusSm = 12.0;
  static const double radiusMd = 18.0;
  static const double radiusLg = 24.0;
  static const double radiusPill = 999.0;
  static const double controlHeight = 52.0;

  static const String fontFamily = 'Outfit';

  static ThemeData get lightTheme => _build(Brightness.light);
  static ThemeData get darkTheme => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isLight = brightness == Brightness.light;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: isLight ? BrandColors.primary : BrandColors.primaryLight,
      onPrimary: isLight ? BrandColors.onPrimary : BrandColors.primaryDark,
      primaryContainer: isLight ? BrandColors.primaryContainer : const Color(0xFF1D3A24),
      onPrimaryContainer: isLight ? BrandColors.onPrimaryContainer : BrandColors.primaryContainer,
      secondary: BrandColors.secondary,
      onSecondary: BrandColors.onSecondary,
      secondaryContainer: isLight ? BrandColors.secondaryLight : const Color(0xFF5A3305),
      onSecondaryContainer: isLight ? const Color(0xFF6B3A04) : BrandColors.secondaryLight,
      tertiary: BrandColors.tertiary,
      onTertiary: BrandColors.onTertiary,
      tertiaryContainer: isLight ? const Color(0xFFFFF4D1) : const Color(0xFF4A3800),
      onTertiaryContainer: isLight ? const Color(0xFF4A3800) : const Color(0xFFFFF4D1),
      error: BrandColors.error,
      onError: Colors.white,
      errorContainer: isLight ? const Color(0xFFFDE3E0) : const Color(0xFF6E1E16),
      onErrorContainer: isLight ? const Color(0xFF6E1E16) : const Color(0xFFFDE3E0),
      surface: isLight ? BrandColors.surfaceLight : BrandColors.surfaceDark,
      onSurface: isLight ? BrandColors.onSurfaceLight : BrandColors.onSurfaceDark,
      surfaceContainerLowest: isLight ? Colors.white : const Color(0xFF09120D),
      surfaceContainerLow: isLight ? BrandColors.surfaceAlt : const Color(0xFF18271E),
      surfaceContainer: isLight ? const Color(0xFFEDF2EB) : const Color(0xFF1E2F25),
      surfaceContainerHigh: isLight ? BrandColors.divider : const Color(0xFF26392D),
      surfaceContainerHighest: isLight ? BrandColors.dividerStrong : const Color(0xFF314636),
      onSurfaceVariant: isLight ? BrandColors.textDim : const Color(0xFFA9B8AD),
      outline: isLight ? BrandColors.dividerStrong : const Color(0xFF3B5142),
      outlineVariant: isLight ? BrandColors.divider : BrandColors.dividerDark,
      shadow: Colors.black,
      scrim: Colors.black54,
      inverseSurface: isLight ? BrandColors.surfaceDark : BrandColors.surfaceLight,
      onInverseSurface: isLight ? BrandColors.onSurfaceDark : BrandColors.onSurfaceLight,
      inversePrimary: isLight ? BrandColors.primaryLight : BrandColors.primary,
      surfaceTint: Colors.transparent,
    );

    const pill = StadiumBorder();
    final textTheme = _textTheme(colorScheme);

    final base = ThemeData(
      brightness: brightness,
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: fontFamily,
      textTheme: textTheme,
      scaffoldBackgroundColor:
          isLight ? BrandColors.backgroundLight : BrandColors.backgroundDark,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,

      // ── App bar: light, centred title like the design ──
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w500),
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        actionsIconTheme: IconThemeData(color: colorScheme.onSurface),
      ),

      // ── Cards ──
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        color: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.6)),
        ),
      ),

      // ── Buttons: pills ──
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, controlHeight),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: pill,
          textStyle: const TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          minimumSize: const Size(64, controlHeight),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: pill,
          textStyle: const TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, controlHeight),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: pill,
          backgroundColor: colorScheme.surface,
          foregroundColor: colorScheme.onSurface,
          side: BorderSide(color: colorScheme.outlineVariant),
          textStyle: const TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: pill,
          textStyle: const TextStyle(fontFamily: fontFamily, fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(shape: const CircleBorder()),
      ),

      // ── Inputs: white pills ──
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: _pillBorder(colorScheme.outlineVariant),
        enabledBorder: _pillBorder(colorScheme.outlineVariant),
        focusedBorder: _pillBorder(colorScheme.primary, width: 1.6),
        errorBorder: _pillBorder(colorScheme.error),
        focusedErrorBorder: _pillBorder(colorScheme.error, width: 1.6),
        disabledBorder: _pillBorder(colorScheme.outlineVariant.withValues(alpha: 0.5)),
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        floatingLabelStyle: TextStyle(color: colorScheme.primary),
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
        prefixIconColor: colorScheme.onSurfaceVariant,
        suffixIconColor: colorScheme.onSurfaceVariant,
      ),

      // ── Chips: pills ──
      chipTheme: ChipThemeData(
        shape: pill,
        side: BorderSide.none,
        backgroundColor: isLight ? const Color(0xFFE6EEE3) : const Color(0xFF1E2F25),
        selectedColor: colorScheme.primary,
        labelStyle: TextStyle(fontFamily: fontFamily, color: colorScheme.onSurface, fontSize: 14),
        secondaryLabelStyle: TextStyle(fontFamily: fontFamily, color: colorScheme.onPrimary, fontSize: 14),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        showCheckmark: false,
      ),

      // ── Bottom navigation (fallback when NavigationBar is used directly) ──
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 72,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: colorScheme.primary,
        indicatorShape: pill,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(color: selected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontFamily: fontFamily,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primary,
        indicatorShape: pill,
        selectedIconTheme: IconThemeData(color: colorScheme.onPrimary),
        unselectedIconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
        selectedLabelTextStyle: TextStyle(fontFamily: fontFamily, color: colorScheme.primary, fontWeight: FontWeight.w600),
        unselectedLabelTextStyle: TextStyle(fontFamily: fontFamily, color: colorScheme.onSurfaceVariant),
      ),

      // ── Sheets & dialogs ──
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusLg)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLg)),
        titleTextStyle: textTheme.titleLarge,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: TextStyle(fontFamily: fontFamily, color: colorScheme.onInverseSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
        insetPadding: const EdgeInsets.all(16),
      ),

      dividerTheme: DividerThemeData(space: 1, thickness: 1, color: colorScheme.outlineVariant),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 2,
        shape: const CircleBorder(),
        extendedTextStyle: const TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w500),
      ),

      listTileTheme: ListTileThemeData(
        iconColor: colorScheme.onSurfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? colorScheme.primary : null,
        ),
      ),

      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          shape: pill,
          selectedBackgroundColor: colorScheme.primary,
          selectedForegroundColor: colorScheme.onPrimary,
        ),
      ),
    );

    return base.copyWith(
      extensions: <ThemeExtension<dynamic>>[
        isLight ? BrandTheme.light : BrandTheme.dark,
        isLight ? AppDecor.light : AppDecor.dark,
      ],
    );
  }

  static OutlineInputBorder _pillBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusPill),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  static TextTheme _textTheme(ColorScheme cs) {
    TextStyle s(double size, FontWeight w, {double? height}) => TextStyle(
          fontFamily: fontFamily,
          fontSize: size,
          fontWeight: w,
          height: height,
          color: cs.onSurface,
        );
    return TextTheme(
      displaySmall: s(34, FontWeight.w600),
      headlineLarge: s(30, FontWeight.w600),
      headlineMedium: s(26, FontWeight.w600),
      headlineSmall: s(22, FontWeight.w600),
      titleLarge: s(20, FontWeight.w500),
      titleMedium: s(17, FontWeight.w500),
      titleSmall: s(15, FontWeight.w500),
      bodyLarge: s(16, FontWeight.w400),
      bodyMedium: s(14, FontWeight.w400),
      bodySmall: s(12, FontWeight.w400).copyWith(color: cs.onSurfaceVariant),
      labelLarge: s(15, FontWeight.w500),
      labelMedium: s(13, FontWeight.w500),
      labelSmall: s(11, FontWeight.w500),
    );
  }
}

/// Redesign decoration tokens: background gradient and status pill colours.
class AppDecor extends ThemeExtension<AppDecor> {
  const AppDecor({
    required this.background,
    required this.paidBg,
    required this.paidFg,
    required this.unpaidBg,
    required this.unpaidFg,
    required this.partialBg,
    required this.partialFg,
    required this.neutralBg,
    required this.neutralFg,
  });

  final Gradient background;
  final Color paidBg;
  final Color paidFg;
  final Color unpaidBg;
  final Color unpaidFg;
  final Color partialBg;
  final Color partialFg;
  final Color neutralBg;
  final Color neutralFg;

  static const light = AppDecor(
    background: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [BrandColors.gradientTop, BrandColors.gradientBottom],
    ),
    paidBg: BrandColors.paidBg,
    paidFg: BrandColors.paidFg,
    unpaidBg: BrandColors.unpaidBg,
    unpaidFg: BrandColors.unpaidFg,
    partialBg: BrandColors.partialBg,
    partialFg: BrandColors.partialFg,
    neutralBg: BrandColors.neutralBg,
    neutralFg: BrandColors.neutralFg,
  );

  static const dark = AppDecor(
    background: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [BrandColors.gradientTopDark, BrandColors.gradientBottomDark],
    ),
    paidBg: Color(0xFF173A20),
    paidFg: Color(0xFF8CC26A),
    unpaidBg: Color(0xFF3F1712),
    unpaidFg: Color(0xFFF08A7E),
    partialBg: Color(0xFF3F2A0B),
    partialFg: Color(0xFFF5A84A),
    neutralBg: Color(0xFF1E2F25),
    neutralFg: Color(0xFFA9B8AD),
  );

  @override
  AppDecor copyWith({Gradient? background}) => AppDecor(
        background: background ?? this.background,
        paidBg: paidBg,
        paidFg: paidFg,
        unpaidBg: unpaidBg,
        unpaidFg: unpaidFg,
        partialBg: partialBg,
        partialFg: partialFg,
        neutralBg: neutralBg,
        neutralFg: neutralFg,
      );

  @override
  AppDecor lerp(ThemeExtension<AppDecor>? other, double t) {
    if (other is! AppDecor) return this;
    return AppDecor(
      background: Gradient.lerp(background, other.background, t) ?? background,
      paidBg: Color.lerp(paidBg, other.paidBg, t)!,
      paidFg: Color.lerp(paidFg, other.paidFg, t)!,
      unpaidBg: Color.lerp(unpaidBg, other.unpaidBg, t)!,
      unpaidFg: Color.lerp(unpaidFg, other.unpaidFg, t)!,
      partialBg: Color.lerp(partialBg, other.partialBg, t)!,
      partialFg: Color.lerp(partialFg, other.partialFg, t)!,
      neutralBg: Color.lerp(neutralBg, other.neutralBg, t)!,
      neutralFg: Color.lerp(neutralFg, other.neutralFg, t)!,
    );
  }
}

extension AppDecorContext on BuildContext {
  AppDecor get decor => Theme.of(this).extension<AppDecor>() ?? AppDecor.light;
}
