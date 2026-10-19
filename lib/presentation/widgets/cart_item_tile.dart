import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/brand_colors.dart';
import '../blocs/cart/cart_state.dart';
import 'money_text.dart';

class CartItemTile extends StatefulWidget {
  final CartLine line;
  final ValueChanged<double> onQtyChanged;
  final ValueChanged<double> onPriceChanged;
  final VoidCallback onRemove;
  final VoidCallback? onTapDiscount;

  /// Called with a tier name (or null for the normal price) when the product
  /// has named price tiers; the selector is hidden when this is null.
  final ValueChanged<String?>? onTierChanged;

  /// When false, the unit price is shown read-only (user lacks override_price).
  final bool canEditPrice;

  const CartItemTile({
    super.key,
    required this.line,
    required this.onQtyChanged,
    required this.onPriceChanged,
    required this.onRemove,
    this.onTapDiscount,
    this.onTierChanged,
    this.canEditPrice = true,
  });

  @override
  State<CartItemTile> createState() => _CartItemTileState();
}

class _CartItemTileState extends State<CartItemTile> {
  late final TextEditingController _priceCtrl;
  late final TextEditingController _qtyCtrl;
  final _priceFocus = FocusNode();
  final _qtyFocus = FocusNode();

  static String _qtyText(double q) =>
      q == q.floorToDouble() ? q.toInt().toString() : q.toStringAsFixed(2);

  static String _priceText(double p) => p.toStringAsFixed(0);

  @override
  void initState() {
    super.initState();
    _priceCtrl = TextEditingController(
      text: _priceText(widget.line.effectivePrice),
    );
    _qtyCtrl = TextEditingController(text: _qtyText(widget.line.quantity));
    // On focus, clear the field so the user types a fresh value (the current
    // value stays visible as a gray hint). This avoids the dark select-all
    // highlight. On blur, restore the committed value if left blank/invalid.
    _priceFocus.addListener(
      () => _onFocusChange(
        _priceFocus,
        _priceCtrl,
        () => _priceText(widget.line.effectivePrice),
      ),
    );
    _qtyFocus.addListener(
      () => _onFocusChange(
        _qtyFocus,
        _qtyCtrl,
        () => _qtyText(widget.line.quantity),
      ),
    );
  }

  void _onFocusChange(
    FocusNode node,
    TextEditingController ctrl,
    String Function() current,
  ) {
    if (node.hasFocus) {
      ctrl.clear();
    } else {
      // Left the field: if what's there isn't a usable number, snap back.
      final parsed = double.tryParse(ctrl.text.trim());
      if (parsed == null) ctrl.text = current();
    }
  }

  @override
  void didUpdateWidget(covariant CartItemTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-sync the fields when the line changes externally (e.g. cart synced
    // from another device), but never while the field is focused (it's
    // cleared for fresh input) and only when the numeric value actually
    // differs — so we don't stomp the cursor while the user is typing.
    if (!_priceFocus.hasFocus &&
        double.tryParse(_priceCtrl.text) != widget.line.effectivePrice) {
      _priceCtrl.text = _priceText(widget.line.effectivePrice);
    }
    if (!_qtyFocus.hasFocus &&
        double.tryParse(_qtyCtrl.text) != widget.line.quantity) {
      _qtyCtrl.text = _qtyText(widget.line.quantity);
    }
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    _qtyCtrl.dispose();
    _priceFocus.dispose();
    _qtyFocus.dispose();
    super.dispose();
  }

  void _commitPrice(String value) {
    final p = double.tryParse(value.trim());
    if (p != null && p >= 0 && p != widget.line.effectivePrice) {
      widget.onPriceChanged(p);
    }
  }

  void _commitQty(String value) {
    final q = double.tryParse(value.trim());
    // Ignore empty / 0 while typing — removal is handled by the delete button.
    if (q != null && q > 0 && q != widget.line.quantity) {
      widget.onQtyChanged(q);
    }
  }

  @override
  Widget build(BuildContext context) {
    final line = widget.line;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Name + delete ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  line.product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Semantics(
                button: true,
                label: 'Remove ${line.product.name}',
                child: GestureDetector(
                  onTap: widget.onRemove,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      size: 16,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ),
            ],
          ),

          if (widget.onTierChanged != null &&
              line.product.tierPrices.keys.any((k) => k != 'NORMAL')) ...[
            const SizedBox(height: 6),
            DropdownButton<String>(
              key: const Key('tier-selector'),
              isDense: true,
              value: line.priceTier ?? 'NORMAL',
              items: [
                for (final tier in {'NORMAL', ...line.product.tierPrices.keys})
                  DropdownMenuItem(
                    value: tier,
                    child: Text(
                      '$tier · ${line.product.priceForTier(tier == 'NORMAL' ? null : tier).toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
              ],
              onChanged: (tier) => widget.onTierChanged!(tier == 'NORMAL' ? null : tier),
            ),
          ],

          const SizedBox(height: 10),

          // ── Qty × Unit price = Line total (all inline editable) ──
          Row(
            children: [
              // Quantity box
              Container(
                width: 56,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                ),
                child: TextSelectionTheme(
                  data: TextSelectionThemeData(
                    selectionColor: BrandColors.primary.withValues(alpha: 0.22),
                    cursorColor: BrandColors.primary,
                    selectionHandleColor: BrandColors.primary,
                  ),
                  child: TextField(
                    controller: _qtyCtrl,
                    focusNode: _qtyFocus,
                    cursorColor: BrandColors.primary,
                    keyboardAppearance: Brightness.light,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      isCollapsed: true,
                      filled: false,
                      fillColor: Colors.transparent,
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      // The global InputDecorationTheme sets non-null
                      // enabledBorder/focusedBorder, which take precedence
                      // over `border` — so those must be overridden too, or
                      // the theme's outline paints inside this box's own
                      // Container border (a visible double border).
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      hintText: _qtyText(line.quantity),
                      hintStyle: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    onTap: () {
                      // First tap clears the committed value (shown as gray
                      // hint) so there's no dark select-all box.
                      if (_qtyCtrl.text == _qtyText(widget.line.quantity)) {
                        _qtyCtrl.clear();
                      }
                    },
                    onChanged: _commitQty,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '×',
                style: TextStyle(
                  fontSize: 15,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 10),

              // Unit price box
              Expanded(
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: line.hasPriceOverride
                          ? const Color(0xFFFCD34D)
                          : Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'TZS',
                        style: TextStyle(
                          fontSize: 11,
                          color: line.hasPriceOverride
                              ? const Color(0xFF92400E)
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: !widget.canEditPrice
                            // Read-only: user lacks the price-override permission.
                            ? Text(
                                _priceText(line.effectivePrice),
                                style: TextStyle(
                                  fontSize: 15,
                                  color: line.hasPriceOverride
                                      ? const Color(0xFF92400E)
                                      : Theme.of(context).colorScheme.onSurface,
                                  fontWeight: FontWeight.w700,
                                ),
                              )
                            : TextSelectionTheme(
                                data: const TextSelectionThemeData(
                                  selectionColor: Color(0x66FCD34D),
                                  cursorColor: Color(0xFF92400E),
                                  selectionHandleColor: Color(0xFF92400E),
                                ),
                                child: TextField(
                                  controller: _priceCtrl,
                                  focusNode: _priceFocus,
                                  cursorColor: const Color(0xFF92400E),
                                  keyboardAppearance: Brightness.light,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'[0-9.]'),
                                    ),
                                  ],
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: line.hasPriceOverride
                                        ? const Color(0xFF92400E)
                                        : Theme.of(context).colorScheme.onSurface,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    isCollapsed: true,
                                    // Disable the global theme's dark fill so the
                                    // light container shows through (no dark box
                                    // in dark mode).
                                    filled: false,
                                    fillColor: Colors.transparent,
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    // See the qty box's comment above — the
                                    // theme's enabledBorder/focusedBorder
                                    // must be overridden too, not just border.
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    disabledBorder: InputBorder.none,
                                    hintText: _priceText(line.effectivePrice),
                                    hintStyle: TextStyle(
                                      fontSize: 15,
                                      color: Theme.of(context).colorScheme.onSurface,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  onTap: () {
                                    // First tap on the committed value: clear it
                                    // (shown as gray hint) so there's no dark
                                    // select-all box. Subsequent taps while
                                    // editing keep the input.
                                    if (_priceCtrl.text ==
                                        _priceText(
                                          widget.line.effectivePrice,
                                        )) {
                                      _priceCtrl.clear();
                                    }
                                  },
                                  onChanged: _commitPrice,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '=',
                style: TextStyle(
                  fontSize: 15,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 10),
              MoneyText(
                line.lineTotal,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),

          // ── Discount badge + link ──
          if (line.hasDiscount || widget.onTapDiscount != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                if (line.hasDiscount) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      line.isPercentDiscount
                          ? '-${line.discount.toStringAsFixed(0)}%'
                          : '-${line.lineDiscount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2E8B3E),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                if (widget.onTapDiscount != null)
                  GestureDetector(
                    onTap: widget.onTapDiscount,
                    child: const Text(
                      'Discount',
                      style: TextStyle(
                        fontSize: 10,
                        color: BrandColors.primary,
                        decoration: TextDecoration.underline,
                        decorationColor: BrandColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ],

          // ── Insufficient-stock warning ──
          if (line.exceedsStock) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 13,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 4),
                Text(
                  'Only ${_stockText(line.product.stockQuantity)} in stock',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

String _stockText(double? stock) {
  if (stock == null) return '0';
  return stock == stock.floorToDouble()
      ? stock.toInt().toString()
      : stock.toStringAsFixed(2);
}
