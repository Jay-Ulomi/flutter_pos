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

  /// When false, the unit price is shown read-only (user lacks override_price).
  final bool canEditPrice;

  const CartItemTile({
    super.key,
    required this.line,
    required this.onQtyChanged,
    required this.onPriceChanged,
    required this.onRemove,
    this.onTapDiscount,
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
    _priceCtrl = TextEditingController(text: _priceText(widget.line.effectivePrice));
    _qtyCtrl = TextEditingController(text: _qtyText(widget.line.quantity));
    // On focus, clear the field so the user types a fresh value (the current
    // value stays visible as a gray hint). This avoids the dark select-all
    // highlight. On blur, restore the committed value if left blank/invalid.
    _priceFocus.addListener(() => _onFocusChange(
        _priceFocus, _priceCtrl, () => _priceText(widget.line.effectivePrice)));
    _qtyFocus.addListener(() => _onFocusChange(
        _qtyFocus, _qtyCtrl, () => _qtyText(widget.line.quantity)));
  }

  void _onFocusChange(
      FocusNode node, TextEditingController ctrl, String Function() current) {
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
    // Re-sync the fields when the line changes externally (e.g. +/- buttons),
    // but never while the field is focused (it's cleared for fresh input) and
    // only when the numeric value actually differs — so we don't stomp the
    // cursor while the user is typing.
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
    // Ignore empty / 0 while typing — removal is handled by the minus button.
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
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
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
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: widget.onRemove,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    size: 14,
                    color: Color(0xFFDC2626),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          // ── Unit price (inline editable) + discount ──
          Row(
            children: [
              Container(
                height: 26,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: line.hasPriceOverride
                      ? const Color(0xFFFEF3C7)
                      : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: line.hasPriceOverride
                        ? const Color(0xFFFCD34D)
                        : const Color(0xFFE5E7EB),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'TZS',
                      style: TextStyle(
                        fontSize: 10,
                        color: line.hasPriceOverride
                            ? const Color(0xFF92400E)
                            : const Color(0xFF9CA3AF),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 3),
                    if (!widget.canEditPrice)
                      // Read-only: user lacks the price-override permission.
                      Text(
                        _priceText(line.effectivePrice),
                        style: TextStyle(
                          fontSize: 12,
                          color: line.hasPriceOverride
                              ? const Color(0xFF92400E)
                              : const Color(0xFF374151),
                          fontWeight: line.hasPriceOverride
                              ? FontWeight.w700
                              : FontWeight.w600,
                        ),
                      )
                    else
                      SizedBox(
                        width: 72,
                        child: TextSelectionTheme(
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
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9.]')),
                            ],
                            style: TextStyle(
                              fontSize: 12,
                              color: line.hasPriceOverride
                                  ? const Color(0xFF92400E)
                                  : const Color(0xFF374151),
                              fontWeight: line.hasPriceOverride
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              isCollapsed: true,
                              // Disable the global theme's dark fill so the light
                              // container shows through (no dark box in dark mode).
                              filled: false,
                              fillColor: Colors.transparent,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 4),
                              border: InputBorder.none,
                              hintText: _priceText(line.effectivePrice),
                              hintStyle: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF9CA3AF),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            onTap: () {
                              // First tap on the committed value: clear it (shown
                              // as gray hint) so there's no dark select-all box.
                              // Subsequent taps while editing keep the input.
                              if (_priceCtrl.text ==
                                  _priceText(widget.line.effectivePrice)) {
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
              if (line.hasDiscount) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    line.isPercentDiscount
                        ? '-${line.discount.toStringAsFixed(0)}%'
                        : '-${line.lineDiscount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF16A34A),
                    ),
                  ),
                ),
              ],
              if (widget.onTapDiscount != null) ...[
                const SizedBox(width: 6),
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
            ],
          ),

          const SizedBox(height: 10),

          // ── Qty controls (inline editable) + line total ──
          Row(
            children: [
              _QtyButton(
                icon: Icons.remove,
                onTap: () => widget.onQtyChanged(line.quantity - 1),
              ),
              const SizedBox(width: 8),
              Container(
                width: 52,
                height: 30,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6EE),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                alignment: Alignment.center,
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
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: BrandColors.primary,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      isCollapsed: true,
                      filled: false,
                      fillColor: Colors.transparent,
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      border: InputBorder.none,
                      hintText: _qtyText(line.quantity),
                      hintStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF9CA3AF),
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
              const SizedBox(width: 8),
              _QtyButton(
                icon: Icons.add,
                onTap: () => widget.onQtyChanged(line.quantity + 1),
              ),
              const Spacer(),
              MoneyText(
                line.lineTotal,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Icon(icon, size: 14, color: const Color(0xFF374151)),
      ),
    );
  }
}
