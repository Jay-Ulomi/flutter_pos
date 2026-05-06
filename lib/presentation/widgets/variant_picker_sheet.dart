import 'package:flutter/material.dart';

import '../../data/models/product_models.dart';
import 'money_text.dart';

/// Shows a bottom sheet to pick a variant from a product that has variants.
/// Returns the selected [ProductVariant], or null if dismissed.
Future<ProductVariant?> showVariantPickerSheet(
  BuildContext context,
  Product product,
) {
  return showModalBottomSheet<ProductVariant>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _VariantPickerSheet(product: product),
  );
}

class _VariantPickerSheet extends StatelessWidget {
  final Product product;
  const _VariantPickerSheet({required this.product});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final activeVariants =
        product.variants.where((v) => v.isActive).toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      maxChildSize: 0.9,
      minChildSize: 0.3,
      builder: (_, controller) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: colors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Select a variant',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                controller: controller,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: activeVariants.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final variant = activeVariants[i];
                  final price =
                      variant.sellingPrice ?? product.sellingPrice;
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: colors.outlineVariant),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Navigator.of(context).pop(variant),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    variant.name,
                                    style: theme.textTheme.bodyLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  if (variant.attributes.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        variant.attributes.entries
                                            .map((e) => '${e.key}: ${e.value}')
                                            .join(' · '),
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                              color: colors.onSurfaceVariant,
                                            ),
                                      ),
                                    ),
                                  if (variant.sku != null)
                                    Text(
                                      'SKU: ${variant.sku}',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                            color: colors.onSurfaceVariant,
                                          ),
                                    ),
                                ],
                              ),
                            ),
                            MoneyText(
                              price,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colors.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: colors.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
