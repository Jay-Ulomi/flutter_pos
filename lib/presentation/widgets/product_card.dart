import 'package:flutter/material.dart';

import '../../core/theme/brand_colors.dart';
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
    final brand = theme.extension<BrandTheme>() ?? BrandTheme.light;
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
                          color: outOfStock ? cs.error : cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            '${product.stockLabel!} in stock',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: outOfStock
                                  ? cs.error
                                  : product.isLowStock
                                  ? brand.lowStock
                                  : cs.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
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

/// Compact row layout for the same product data as [ProductCard], used by
/// the mobile POS list view.
class ProductListTile extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;

  const ProductListTile({super.key, required this.product, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final brand = theme.extension<BrandTheme>() ?? BrandTheme.light;
    final outOfStock = product.isOutOfStock;

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: outOfStock ? null : onTap,
        splashColor: cs.primary.withValues(alpha: 0.08),
        highlightColor: cs.primary.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              // ── Thumbnail ──
              Stack(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: product.imageUrl != null
                        ? Image.network(
                            product.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _placeholder(cs),
                          )
                        : _placeholder(cs),
                  ),
                  if (outOfStock)
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),

              // ── Info ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        MoneyText(
                          product.sellingPrice,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (product.stockLabel != null) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 11,
                            color: outOfStock ? cs.error : cs.onSurfaceVariant,
                          ),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              '${product.stockLabel!} in stock',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: outOfStock
                                    ? cs.error
                                    : product.isLowStock
                                    ? brand.lowStock
                                    : cs.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              if (product.isLowStock || outOfStock) ...[
                const SizedBox(width: 8),
                _StockBadge(outOfStock: outOfStock),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder(ColorScheme cs) {
    return Center(
      child: Icon(
        Icons.inventory_2_outlined,
        size: 22,
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final brand = theme.extension<BrandTheme>() ?? BrandTheme.light;
    final color = outOfStock ? cs.error : brand.lowStock;
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
