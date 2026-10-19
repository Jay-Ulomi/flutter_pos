import 'package:flutter/material.dart';

import '../../../core/theme/brand_colors.dart';
import '../../../data/models/product_models.dart';
import '../money_text.dart';

/// Home-grid product card: image (or a tinted initial), name, price and a
/// quantity stepper once the product is in the cart.
class SaleProductTile extends StatelessWidget {
  const SaleProductTile({
    super.key,
    required this.product,
    required this.quantity,
    required this.onAdd,
    this.onRemove,
  });

  final Product product;

  /// Quantity in the cart (0 = not in the cart).
  final double quantity;
  final VoidCallback onAdd;

  /// Null when the cart line can't be stepped down here (serial/lot items).
  final VoidCallback? onRemove;

  static const _tints = [
    Color(0xFFE2EEDC),
    Color(0xFFFDEFD9),
    Color(0xFFFFF4D1),
    Color(0xFFE4EEF6),
    Color(0xFFF6E4EA),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final outOfStock = product.isOutOfStock;
    final inCart = quantity > 0;
    final tint = _tints[product.name.hashCode.abs() % _tints.length];

    Widget placeholder() => Container(
          color: theme.brightness == Brightness.light ? tint : cs.surfaceContainerHigh,
          alignment: Alignment.center,
          child: Text(
            product.name.isEmpty ? '?' : product.name.characters.first.toUpperCase(),
            style: theme.textTheme.headlineMedium?.copyWith(
              color: cs.primary.withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
        );

    return Material(
      color: cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: inCart ? cs.primary : cs.outlineVariant, width: inCart ? 1.6 : 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('product-${product.id}'),
        onTap: outOfStock ? null : onAdd,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      product.imageUrl != null && product.imageUrl!.isNotEmpty
                          ? Image.network(
                              product.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => placeholder(),
                            )
                          : placeholder(),
                      if (outOfStock)
                        Container(
                          color: Colors.black.withValues(alpha: 0.4),
                          alignment: Alignment.center,
                          child: const Text('Out of stock',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        )
                      else if (product.isLowStock)
                        Positioned(
                          left: 6,
                          top: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: BrandColors.lowStock,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: const Text('Low',
                                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      if (inCart)
                        Positioned(
                          right: 6,
                          top: 6,
                          child: CircleAvatar(
                            radius: 11,
                            backgroundColor: cs.primary,
                            child: Icon(Icons.check_rounded, size: 14, color: cs.onPrimary),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: MoneyText(
                        product.sellingPrice,
                        sensitive: false,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  if (inCart && onRemove != null) ...[
                    _StepButton(icon: Icons.remove_rounded, onTap: onRemove!, filled: false,
                        semantics: 'Remove one ${product.name}'),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        quantity == quantity.roundToDouble() ? '${quantity.toInt()}' : quantity.toStringAsFixed(1),
                        key: ValueKey('qty-${product.id}'),
                        style: theme.textTheme.labelLarge,
                      ),
                    ),
                  ],
                  _StepButton(
                    icon: Icons.add_rounded,
                    onTap: outOfStock ? null : onAdd,
                    filled: true,
                    semantics: 'Add ${product.name}',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap, required this.filled, required this.semantics});
  final IconData icon;
  final VoidCallback? onTap;
  final bool filled;
  final String semantics;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: semantics,
      child: Material(
        color: filled ? cs.primary : cs.surfaceContainerLow,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 26,
            height: 26,
            child: Icon(icon, size: 16, color: filled ? cs.onPrimary : cs.onSurface),
          ),
        ),
      ),
    );
  }
}
