import 'package:flutter/material.dart';

import '../../data/models/product_models.dart';
import 'money_text.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;

  const ProductCard({super.key, required this.product, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final outOfStock = product.isOutOfStock;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: outOfStock ? null : onTap,
        splashColor: cs.primary.withValues(alpha: 0.08),
        highlightColor: cs.primary.withValues(alpha: 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Image / placeholder area ──
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Placeholder background — soft green tint
                  Container(
                    color: cs.primaryContainer,
                    child: product.imageUrl != null
                        ? Image.network(
                            product.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _placeholder(cs),
                          )
                        : _placeholder(cs),
                  ),
                  // Out-of-stock overlay
                  if (outOfStock)
                    Container(color: Colors.black.withValues(alpha: 0.35)),
                ],
              ),
            ),

            // ── Info area ──
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: MoneyText(
                          product.sellingPrice,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (product.isLowStock || outOfStock)
                        _StockBadge(outOfStock: outOfStock),
                    ],
                  ),
                  if (product.stockLabel != null) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 11,
                          color: outOfStock
                              ? cs.error
                              : cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${product.stockLabel!} in stock',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: outOfStock
                                ? cs.error
                                : product.isLowStock
                                    ? cs.tertiary
                                    : cs.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(ColorScheme cs) {
    return Center(
      child: Icon(
        Icons.inventory_2_outlined,
        size: 36,
        color: cs.primary.withValues(alpha: 0.4),
      ),
    );
  }
}

class _StockBadge extends StatelessWidget {
  final bool outOfStock;
  const _StockBadge({required this.outOfStock});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = outOfStock ? cs.error : cs.tertiary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        outOfStock ? 'Out' : 'Low',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
