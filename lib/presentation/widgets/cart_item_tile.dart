import 'package:flutter/material.dart';

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
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onTapDiscount,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    line.product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  MoneyText(
                    line.product.sellingPrice,
                    style: theme.textTheme.bodySmall,
                  ),
                  if (line.hasDiscount)
                    Text(
                      line.isPercentDiscount
                          ? '-${line.discount.toStringAsFixed(0)}%'
                          : '-${line.lineDiscount.toStringAsFixed(0)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => onQtyChanged(line.quantity - 1),
                icon: const Icon(Icons.remove_circle_outline),
              ),
              SizedBox(
                width: 28,
                child: Text(
                  line.quantity.toStringAsFixed(
                    line.quantity == line.quantity.floor() ? 0 : 2,
                  ),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleSmall,
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => onQtyChanged(line.quantity + 1),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          const SizedBox(width: 6),
          MoneyText(
            line.lineTotal,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onRemove,
            icon: Icon(Icons.close, color: theme.colorScheme.error),
          ),
        ],
      ),
    );
  }
}
