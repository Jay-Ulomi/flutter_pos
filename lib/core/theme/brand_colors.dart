import 'package:flutter/material.dart';

/// Unified brand palette for the NexPOS product.
///
/// Mirrors the React landing page CSS variables exactly:
///   --primary:       #468432
///   --primary-light: #9AD872
///   --orange:        #FFA02E
///   --yellow:        #FFEF91
///   --bg:            #FFFFFF
///   --bg-2:          #F5F5F2
///   --border:        #E0E0DB
class BrandColors {
  BrandColors._();

  // ── Primary — Forest Green ───────────────────────────────────────────────
  // Matches --primary (#468432) on the landing page.
  static const Color primary      = Color(0xFF468432); // --primary
  static const Color primaryLight = Color(0xFF9AD872); // --primary-light
  static const Color primaryDark  = Color(0xFF2D6020); // darker shade (used in stats section)
  static const Color onPrimary    = Color(0xFFFFFFFF);
  static const Color primaryContainer    = Color(0xFFEEF5E9); // very light green tint
  static const Color onPrimaryContainer  = Color(0xFF2D6020);

  // ── Secondary — Orange (CTA / highlights) ───────────────────────────────
  // Matches --orange (#FFA02E) — used for all CTAs on the landing page.
  static const Color secondary      = Color(0xFFFFA02E); // --orange
  static const Color secondaryLight = Color(0xFFFFF3E0); // --orange-light
  static const Color onSecondary    = Color(0xFFFFFFFF);

  // ── Tertiary — Yellow (accent) ───────────────────────────────────────────
  // Matches --yellow (#FFEF91) — used for star ratings and highlights.
  static const Color tertiary      = Color(0xFFFFEF91); // --yellow
  static const Color onTertiary    = Color(0xFF111111); // dark text on yellow

  // ── Semantic status ──────────────────────────────────────────────────────
  static const Color success = Color(0xFF468432); // brand primary green
  static const Color warning = Color(0xFFFFA02E); // brand orange
  static const Color error   = Color(0xFFDC2626); // red-600 — universal error
  static const Color info    = Color(0xFF2563EB); // blue-600 — universal info

  // ── Connectivity / sync status (POS-specific) ───────────────────────────
  static const Color online     = Color(0xFF9AD872); // --primary-light
  static const Color syncing    = Color(0xFFFFA02E); // --orange
  static const Color offline    = Color(0xFF8A8A8A); // --text-muted (neutral, not error)
  static const Color syncFailed = Color(0xFFDC2626); // red-600

  // ── Neutrals — matched to landing page CSS variables ────────────────────
  static const Color surfaceLight    = Color(0xFFFFFFFF); // --bg
  static const Color backgroundLight = Color(0xFFF5F5F2); // --bg-2
  static const Color surfaceAlt      = Color(0xFFEEEEEB); // --surface
  static const Color surfaceDark     = Color(0xFF111827);
  static const Color backgroundDark  = Color(0xFF0B1220);
  static const Color onSurfaceLight  = Color(0xFF111111); // --text
  static const Color onSurfaceDark   = Color(0xFFE2E8F0);
  static const Color divider         = Color(0xFFE0E0DB); // --border
  static const Color dividerStrong   = Color(0xFFC4C4BF); // --border-strong
  static const Color dividerDark     = Color(0xFF1F2937);

  // ── Text scale ───────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF111111); // --text
  static const Color textDim     = Color(0xFF525252); // --text-dim
  static const Color textMuted   = Color(0xFF8A8A8A); // --text-muted

  // ── POS-specific accents ────────────────────────────────────────────────
  static const Color cartBadge  = Color(0xFFDC2626); // red for item count
  static const Color receiptBg  = Color(0xFFF5F5F2); // --bg-2 for printable receipt
  static const Color lowStock   = Color(0xFFFFA02E); // --orange warning
  static const Color outOfStock = Color(0xFFDC2626); // red alert
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
    success:    Color(0xFF9AD872), // --primary-light — brighter on dark bg
    warning:    Color(0xFFFFBF5E), // lighter orange for dark bg
    info:       Color(0xFF60A5FA),
    online:     Color(0xFF9AD872),
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
