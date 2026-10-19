import 'package:flutter/material.dart';

/// Aduinola brand palette (POS • Inventory • Accounting).
///
/// Sampled from the brand files (poslogo.png wordmark, poslogoapp.png icon):
///   deep green  #0E5023  wordmark  — primary (buttons, active tab, headings)
///   icon green  #3E7E22  emblem    — secondary green / accents
///   orange      #EC880C  "A" leg   — secondary actions (e.g. Purchase)
///   gold        #FCB408  sales bars — highlights
/// Surfaces follow the redesign: white rounded cards on a soft green-grey
/// gradient, pill-shaped inputs and buttons.
class BrandColors {
  BrandColors._();

  // ── Primary — Aduinola deep green ────────────────────────────────────────
  static const Color primary      = Color(0xFF0E5023);
  static const Color primaryMid   = Color(0xFF3E7E22); // emblem green
  static const Color primaryLight = Color(0xFF8CC26A);
  static const Color primaryDark  = Color(0xFF08381A);
  static const Color onPrimary    = Color(0xFFFFFFFF);
  static const Color primaryContainer   = Color(0xFFE2EEDC);
  static const Color onPrimaryContainer = Color(0xFF08381A);

  // ── Secondary — Aduinola orange (secondary actions) ─────────────────────
  static const Color secondary      = Color(0xFFEC880C);
  static const Color secondaryLight = Color(0xFFFDEFD9);
  static const Color onSecondary    = Color(0xFFFFFFFF);

  // ── Tertiary — gold (highlights) ─────────────────────────────────────────
  static const Color tertiary   = Color(0xFFFCB408);
  static const Color onTertiary = Color(0xFF2A1E00);

  // ── Semantic status ──────────────────────────────────────────────────────
  static const Color success = Color(0xFF2E8B3E);
  static const Color warning = Color(0xFFEC880C);
  static const Color error   = Color(0xFFD93A2B);
  static const Color info    = Color(0xFF2563EB);

  // ── Status pills ("Paid", "Unpaid", ...) ─────────────────────────────────
  static const Color paidBg      = Color(0xFFDDF1DE);
  static const Color paidFg      = Color(0xFF237A33);
  static const Color unpaidBg    = Color(0xFFFDE3E0);
  static const Color unpaidFg    = Color(0xFFC0392B);
  static const Color partialBg   = Color(0xFFFDEFD9);
  static const Color partialFg   = Color(0xFFB8650A);
  static const Color neutralBg   = Color(0xFFEAEFE8);
  static const Color neutralFg   = Color(0xFF4E5E52);

  // ── Connectivity / sync status (POS-specific) ───────────────────────────
  static const Color online     = Color(0xFF3E7E22);
  static const Color syncing    = Color(0xFFEC880C);
  static const Color offline    = Color(0xFF8A968D);
  static const Color syncFailed = Color(0xFFD93A2B);

  // ── Neutrals — soft green-grey ───────────────────────────────────────────
  static const Color surfaceLight    = Color(0xFFFFFFFF);
  static const Color backgroundLight = Color(0xFFEEF3EC);
  static const Color surfaceAlt      = Color(0xFFF4F7F2);
  static const Color surfaceDark     = Color(0xFF14211A);
  static const Color backgroundDark  = Color(0xFF0B1510);
  static const Color onSurfaceLight  = Color(0xFF14261A);
  static const Color onSurfaceDark   = Color(0xFFE4ECE5);
  static const Color divider         = Color(0xFFDCE4D8);
  static const Color dividerStrong   = Color(0xFFC3CEC0);
  static const Color dividerDark     = Color(0xFF243329);

  // ── Background gradient (top → bottom) ───────────────────────────────────
  static const Color gradientTop       = Color(0xFFDCE9D8);
  static const Color gradientBottom    = Color(0xFFF5F8F3);
  static const Color gradientTopDark   = Color(0xFF10201A);
  static const Color gradientBottomDark= Color(0xFF0B1510);

  // ── Text scale ───────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF14261A);
  static const Color textDim     = Color(0xFF4E5E52);
  static const Color textMuted   = Color(0xFF8A968D);

  // ── POS-specific accents ────────────────────────────────────────────────
  static const Color cartBadge  = Color(0xFFD93A2B);
  static const Color receiptBg  = Color(0xFFF4F7F2);
  static const Color lowStock   = Color(0xFFEC880C);
  static const Color outOfStock = Color(0xFFD93A2B);
}

/// Custom theme extension exposing brand colors via Theme.of(context).
/// Usage:
/// ```dart
/// final brand = Theme.of(context).extension<BrandTheme>()!;
/// return Container(color: brand.success);
/// ```
class BrandTheme extends ThemeExtension<BrandTheme> {
  final Color success;
  final Color warning;
  final Color info;
  final Color online;
  final Color syncing;
  final Color offline;
  final Color syncFailed;
  final Color cartBadge;
  final Color receiptBg;
  final Color lowStock;
  final Color outOfStock;

  const BrandTheme({
    required this.success,
    required this.warning,
    required this.info,
    required this.online,
    required this.syncing,
    required this.offline,
    required this.syncFailed,
    required this.cartBadge,
    required this.receiptBg,
    required this.lowStock,
    required this.outOfStock,
  });

  static const light = BrandTheme(
    success:   BrandColors.success,
    warning:   BrandColors.warning,
    info:      BrandColors.info,
    online:    BrandColors.online,
    syncing:   BrandColors.syncing,
    offline:   BrandColors.offline,
    syncFailed: BrandColors.syncFailed,
    cartBadge:  BrandColors.cartBadge,
    receiptBg:  BrandColors.receiptBg,
    lowStock:   BrandColors.lowStock,
    outOfStock: BrandColors.outOfStock,
  );

  static const dark = BrandTheme(
    success:    Color(0xFF8CC26A),
    warning:    Color(0xFFF5A84A),
    info:       Color(0xFF60A5FA),
    online:     Color(0xFF8CC26A),
    syncing:    Color(0xFFFFBF5E),
    offline:    Color(0xFF8A8A8A),
    syncFailed: Color(0xFFEF4444),
    cartBadge:  Color(0xFFEF4444),
    receiptBg:  Color(0xFF1F2937),
    lowStock:   Color(0xFFFFBF5E),
    outOfStock: Color(0xFFEF4444),
  );

  @override
  BrandTheme copyWith({
    Color? success,
    Color? warning,
    Color? info,
    Color? online,
    Color? syncing,
    Color? offline,
    Color? syncFailed,
    Color? cartBadge,
    Color? receiptBg,
    Color? lowStock,
    Color? outOfStock,
  }) {
    return BrandTheme(
      success:    success    ?? this.success,
      warning:    warning    ?? this.warning,
      info:       info       ?? this.info,
      online:     online     ?? this.online,
      syncing:    syncing    ?? this.syncing,
      offline:    offline    ?? this.offline,
      syncFailed: syncFailed ?? this.syncFailed,
      cartBadge:  cartBadge  ?? this.cartBadge,
      receiptBg:  receiptBg  ?? this.receiptBg,
      lowStock:   lowStock   ?? this.lowStock,
      outOfStock: outOfStock ?? this.outOfStock,
    );
  }

  @override
  BrandTheme lerp(ThemeExtension<BrandTheme>? other, double t) {
    if (other is! BrandTheme) return this;
    return BrandTheme(
      success:    Color.lerp(success,    other.success,    t)!,
      warning:    Color.lerp(warning,    other.warning,    t)!,
      info:       Color.lerp(info,       other.info,       t)!,
      online:     Color.lerp(online,     other.online,     t)!,
      syncing:    Color.lerp(syncing,    other.syncing,    t)!,
      offline:    Color.lerp(offline,    other.offline,    t)!,
      syncFailed: Color.lerp(syncFailed, other.syncFailed, t)!,
      cartBadge:  Color.lerp(cartBadge,  other.cartBadge,  t)!,
      receiptBg:  Color.lerp(receiptBg,  other.receiptBg,  t)!,
      lowStock:   Color.lerp(lowStock,   other.lowStock,   t)!,
      outOfStock: Color.lerp(outOfStock, other.outOfStock, t)!,
    );
  }
}
