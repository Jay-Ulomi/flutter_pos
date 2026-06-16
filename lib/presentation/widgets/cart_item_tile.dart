import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/brand_colors.dart';
import '../blocs/cart/cart_state.dart';
import 'money_text.dart';

class CartItemTile extends StatelessWidget {
  final CartLine line;
  final ValueChanged<double> onQtyChanged;
  final ValueChanged<double> onPriceChanged;
  final VoidCallback onRemove;
  final VoidCallback? onTapDiscount;

  const CartItemTile({
    super.key,
    required this.line,
    required this.onQtyChanged,
    required this.onPriceChanged,
    required this.onRemove,
    this.onTapDiscount,
  });

  String _qtyText(double q) =>
      q == q.floorToDouble() ? q.toInt().toString() : q.toStringAsFixed(2);

  Future<void> _showQtyDialog(BuildContext context) async {
    final result = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NumberInputSheet(
        title: 'Edit Quantity',
        initialValue: _qtyText(line.quantity),
      ),
    );
    if (result == null || !context.mounted) return;
    if (result <= 0) {
      onRemove();
    } else {
      onQtyChanged(result);
    }
  }

  Future<void> _showPriceDialog(BuildContext context) async {
    final result = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NumberInputSheet(
        title: 'Override Price',
        subtitle: line.product.name,
        initialValue: line.effectivePrice.toStringAsFixed(0),
        prefix: 'TZS ',
      ),
    );
    if (result != null && context.mounted) onPriceChanged(result);
  }

  @override
  Widget build(BuildContext context) {
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
                onTap: onRemove,
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

          // ── Unit price (tappable) + discount ──
          Row(
            children: [
              GestureDetector(
                onTap: () => _showPriceDialog(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
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
                      MoneyText(
                        line.effectivePrice,
                        style: TextStyle(
                          fontSize: 11,
                          color: line.hasPriceOverride
                              ? const Color(0xFF92400E)
                              : const Color(0xFF6B7280),
                          fontWeight: line.hasPriceOverride
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(
                        Icons.edit,
                        size: 9,
                        color: line.hasPriceOverride
                            ? const Color(0xFF92400E)
                            : const Color(0xFF9CA3AF),
                      ),
                    ],
                  ),
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
              if (onTapDiscount != null) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: onTapDiscount,
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

          // ── Qty controls + line total ──
          Row(
            children: [
              _QtyButton(
                icon: Icons.remove,
                onTap: () => onQtyChanged(line.quantity - 1),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showQtyDialog(context),
                child: Container(
                  constraints: const BoxConstraints(minWidth: 44),
                  height: 30,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6EE),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _qtyText(line.quantity),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: BrandColors.primary,
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Icon(Icons.edit,
                          size: 9, color: BrandColors.primary),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _QtyButton(
                icon: Icons.add,
                onTap: () => onQtyChanged(line.quantity + 1),
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
// Reusable numeric input bottom sheet — owns its own controller lifecycle
// ---------------------------------------------------------------------------

class _NumberInputSheet extends StatefulWidget {
  final String title;
  final String? subtitle;
  final String initialValue;
  final String? prefix;

  const _NumberInputSheet({
    required this.title,
    this.subtitle,
    required this.initialValue,
    this.prefix,
  });

  @override
  State<_NumberInputSheet> createState() => _NumberInputSheetState();
}

class _NumberInputSheetState extends State<_NumberInputSheet> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialValue);
    // Select all text so user can immediately type a new value
    _ctrl.selection =
        TextSelection(baseOffset: 0, extentOffset: _ctrl.text.length);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final d = double.tryParse(_ctrl.text.trim());
    if (d != null && d >= 0) Navigator.of(context).pop(d);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 12 + bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 12),
            width: 32,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFD1D5DB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title + subtitle on one row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    if (widget.subtitle != null)
                      Text(
                        widget.subtitle!,
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF9CA3AF)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(Icons.close,
                    size: 18, color: Color(0xFF9CA3AF)),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Number input
          TextField(
            controller: _ctrl,
            autofocus: true,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
            decoration: InputDecoration(
              prefixText: widget.prefix,
              prefixStyle: const TextStyle(
                fontSize: 13,
                color: Color(0xFF9CA3AF),
                fontWeight: FontWeight.w500,
              ),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: BrandColors.primary, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onSubmitted: (_) => _submit(),
          ),

          const SizedBox(height: 12),

          // Apply button only — close icon handles cancel
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                backgroundColor: BrandColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Apply',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700)),
            ),
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
