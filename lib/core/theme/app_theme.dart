import 'package:flutter/material.dart';
import 'brand_colors.dart';

/// Material 3 theme driven by the NexPOS brand.
///
/// Palette mirrors the React landing page exactly:
///   Primary  #468432  (forest green)
///   Light    #9AD872  (lime green)
///   Orange   #FFA02E  (CTA / secondary)
///   Yellow   #FFEF91  (accent / tertiary)
///   Bg       #FFFFFF / #F5F5F2 / #EEEEEB
///   Border   #E0E0DB / #C4C4BF
///   Text     #111111 / #525252 / #8A8A8A
class AppTheme {
  AppTheme._();

  // ── Shape tokens ─────────────────────────────────────────────────────────
  static const _radiusSm = 8.0;
  static const _radiusMd = 12.0;
  static const _radiusLg = 16.0;

  static ThemeData get lightTheme => _build(Brightness.light);
  static ThemeData get darkTheme  => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isLight = brightness == Brightness.light;

    final colorScheme = ColorScheme(
      brightness: brightness,

      // ── Primary — Forest Green ──
      primary:             BrandColors.primary,
      onPrimary:           BrandColors.onPrimary,
      primaryContainer:    BrandColors.primaryContainer,
      onPrimaryContainer:  BrandColors.onPrimaryContainer,

      // ── Secondary — Orange (CTA) ──
      secondary:           BrandColors.secondary,
      onSecondary:         BrandColors.onSecondary,
      secondaryContainer:  isLight
          ? BrandColors.secondaryLight          // #FFF3E0
          : const Color(0xFF7C3D00),
      onSecondaryContainer: isLight
          ? const Color(0xFF7C3D00)
          : BrandColors.secondaryLight,

      // ── Tertiary — Yellow (accent) ──
      tertiary:            BrandColors.tertiary,
      onTertiary:          BrandColors.onTertiary,
      tertiaryContainer:   isLight
          ? const Color(0xFFFFFDE8)             // --yellow-light
          : const Color(0xFF5C4800),
      onTertiaryContainer: isLight
          ? const Color(0xFF5C4800)
          : const Color(0xFFFFFDE8),

      // ── Error ──
      error:               BrandColors.error,
      onError:             Colors.white,
      errorContainer:      isLight
          ? const Color(0xFFFEE2E2)
          : const Color(0xFF7F1D1D),
      onErrorContainer:    isLight
          ? const Color(0xFF7F1D1D)
          : const Color(0xFFFEE2E2),

      // ── Surfaces — landing page neutrals ──
      surface:             isLight ? BrandColors.surfaceLight  : BrandColors.surfaceDark,
      onSurface:           isLight ? BrandColors.onSurfaceLight : BrandColors.onSurfaceDark,

      // Container hierarchy: white → #F5F5F2 → #EEEEEB → #E0E0DB → #C4C4BF
      surfaceContainerLowest:  isLight ? const Color(0xFFFFFFFF) : const Color(0xFF0A0F1A),
      surfaceContainerLow:     isLight ? BrandColors.backgroundLight : const Color(0xFF111827),
      surfaceContainer:        isLight ? BrandColors.surfaceAlt      : const Color(0xFF1F2937),
      surfaceContainerHigh:    isLight ? BrandColors.divider         : const Color(0xFF374151),
      surfaceContainerHighest: isLight ? BrandColors.dividerStrong   : const Color(0xFF4B5563),

      onSurfaceVariant:    isLight ? BrandColors.textDim   : BrandColors.textMuted,
      outline:             isLight ? BrandColors.dividerStrong : const Color(0xFF334155),
      outlineVariant:      isLight ? BrandColors.divider       : BrandColors.dividerDark,

      shadow:          Colors.black,
      scrim:           Colors.black54,
      inverseSurface:  isLight ? BrandColors.surfaceDark  : BrandColors.surfaceLight,
      onInverseSurface: isLight ? BrandColors.onSurfaceDark : BrandColors.onSurfaceLight,
      inversePrimary:  isLight ? BrandColors.primaryLight  : BrandColors.primaryDark,
      surfaceTint:     BrandColors.primary,
    );

    final base = ThemeData(
      brightness: brightness,
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isLight
          ? BrandColors.backgroundLight   // #F5F5F2
          : BrandColors.backgroundDark,
      fontFamily: 'Inter',

      // ── App bar ──
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: isLight ? colorScheme.primary : colorScheme.surface,
        foregroundColor: isLight ? colorScheme.onPrimary : colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: isLight ? colorScheme.onPrimary : colorScheme.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
        ),
        iconTheme: IconThemeData(
          color: isLight ? colorScheme.onPrimary : colorScheme.onSurface,
        ),
      ),

      // ── Cards ──
      cardTheme: CardThemeData(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        color: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusMd),
          side: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
      ),

      // ── Buttons ──
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radiusSm),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radiusSm),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radiusSm),
          ),
          side: BorderSide(color: colorScheme.outline, width: 1),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radiusSm),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      // ── Inputs ──
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusSm),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusSm),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusSm),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusSm),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusSm),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        hintStyle: TextStyle(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
      ),

      // ── Navigation bar ──
      navigationBarTheme: NavigationBarThemeData(
        elevation: 2,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: colorScheme.primaryContainer,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected)
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurfaceVariant,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurfaceVariant,
          );
        }),
      ),

      // ── Navigation rail ──
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colorScheme.surfaceContainerLow,
        selectedIconTheme: IconThemeData(color: colorScheme.primary, size: 24),
        unselectedIconTheme: IconThemeData(
          color: BrandColors.textMuted,  // #8A8A8A — clearly muted vs active
          size: 24,
        ),
        selectedLabelTextStyle: TextStyle(
          color: colorScheme.primary,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: BrandColors.textMuted,  // #8A8A8A
          fontWeight: FontWeight.w400,
          fontSize: 12,
        ),
        indicatorColor: colorScheme.primary.withValues(alpha: 0.18),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // ── Chips ──
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainer,
        selectedColor: colorScheme.primaryContainer,
        labelStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),

      // ── Dialogs / bottom sheets ──
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusLg),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(_radiusLg)),
        ),
      ),

      // ── SnackBars ──
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: TextStyle(color: colorScheme.onInverseSurface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusSm),
        ),
        insetPadding: const EdgeInsets.all(16),
      ),

      // ── Divider ──
      dividerTheme: DividerThemeData(
        space: 1,
        thickness: 1,
        color: colorScheme.outlineVariant,
      ),

      // ── FAB ──
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusMd),
        ),
      ),

      // ── List tiles ──
      listTileTheme: ListTileThemeData(
        iconColor: colorScheme.onSurfaceVariant,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusSm),
        ),
      ),
    );

    return base.copyWith(
      extensions: <ThemeExtension<dynamic>>[
        isLight ? BrandTheme.light : BrandTheme.dark,
      ],
    );
  }
}
