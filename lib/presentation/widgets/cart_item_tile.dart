import 'package:flutter/material.dart';

import '../../core/theme/brand_colors.dart';
import '../blocs/cart/cart_state.dart';
import 'money_text.dart';

class CartItemTile extends StatelessWidget {
  final CartLine line;
  final ValueChanged<double> onQtyChanged;
  final VoidCallback onRemove;
  final VoidCallback? onTapDiscount;

  const CartItemTile({
    super.key,
    required this.line,
    required this.onQtyChanged,
    required this.onRemove,
    this.onTapDiscount,
  });

  @override
  Widget build(BuildContext context) {
    final qtyLabel = line.quantity == line.quantity.floorToDouble()
        ? line.quantity.toInt().toString()
        : line.quantity.toStringAsFixed(2);

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
          // ── Name row ──
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

          // ── Unit price + discount ──
          Row(
            children: [
              MoneyText(
                line.product.sellingPrice,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF9CA3AF),
                ),
              ),
              if (line.hasDiscount) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
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
              // Minus
              _QtyButton(
                icon: Icons.remove,
                onTap: () => onQtyChanged(line.quantity - 1),
              ),
              const SizedBox(width: 8),
              // Qty label
              Container(
                constraints: const BoxConstraints(minWidth: 36),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                alignment: Alignment.center,
                child: Text(
                  qtyLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Plus
              _QtyButton(
                icon: Icons.add,
                onTap: () => onQtyChanged(line.quantity + 1),
              ),
              const Spacer(),
              // Line total
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
