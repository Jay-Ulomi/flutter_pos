import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/models/product_models.dart';
import '../../blocs/product/product_bloc.dart';
import '../../blocs/product/product_event.dart';
import '../../blocs/product/product_state.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/responsive_shell.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<ProductBloc>().add(const ProductLoadRequested());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openScanner() async {
    if (Platform.isMacOS) {
      _openMacBarcodeDialog();
    } else {
      final barcode = await Navigator.of(context).push<String>(
        MaterialPageRoute(builder: (_) => const _ScannerPage()),
      );
      if (barcode != null && mounted) {
        _searchCtrl.text = barcode;
        context.read<ProductBloc>().add(ProductSearchChanged(barcode));
      }
    }
  }

  void _openMacBarcodeDialog() async {
    final ctrl = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter Barcode'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Scan or type barcode',
            prefixIcon: Icon(Icons.qr_code_scanner),
          ),
          onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
            child: const Text('Search'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (code != null && code.isNotEmpty && mounted) {
      _searchCtrl.text = code;
      context.read<ProductBloc>().add(ProductSearchChanged(code));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return ResponsiveShell(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Scan barcode',
            onPressed: _openScanner,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                context.read<ProductBloc>().add(const ProductSyncRequested()),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search products or scan barcode',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  tooltip: 'Scan barcode',
                  onPressed: _openScanner,
                ),
              ),
              onChanged: (v) =>
                  context.read<ProductBloc>().add(ProductSearchChanged(v)),
            ),
          ),
          // Category filter
          BlocSelector<
            ProductBloc,
            ProductState,
            ({List<Category> categories, String? selectedId})
          >(
            selector: (state) => (
              categories: state.categories,
              selectedId: state.selectedCategoryId,
            ),
            builder: (context, data) {
              if (data.categories.isEmpty) return const SizedBox.shrink();
              return SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: data.categories.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final cs = Theme.of(context).colorScheme;
                    if (i == 0) {
                      final selected = data.selectedId == null;
                      return FilterChip(
                        label: const Text('All'),
                        selected: selected,
                        selectedColor: cs.primary,
                        checkmarkColor: cs.onPrimary,
                        labelStyle: TextStyle(
                          color: selected ? cs.onPrimary : cs.onSurfaceVariant,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                        ),
                        side: BorderSide(
                          color: selected ? cs.primary : cs.outlineVariant,
                        ),
                        onSelected: (_) => context.read<ProductBloc>().add(
                          const ProductCategoryChanged(null),
                        ),
                        visualDensity: VisualDensity.compact,
                      );
                    }
                    final cat = data.categories[i - 1];
                    final selected = data.selectedId == cat.id;
                    return FilterChip(
                      label: Text(cat.name),
                      selected: selected,
                      selectedColor: cs.primary,
                      checkmarkColor: cs.onPrimary,
                      labelStyle: TextStyle(
                        color: selected ? cs.onPrimary : cs.onSurfaceVariant,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      ),
                      side: BorderSide(
                        color: selected ? cs.primary : cs.outlineVariant,
                      ),
                      onSelected: (_) => context.read<ProductBloc>().add(
                        ProductCategoryChanged(cat.id),
                      ),
                      visualDensity: VisualDensity.compact,
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          // Product count
          BlocSelector<ProductBloc, ProductState, int>(
            selector: (state) => state.products.length,
            builder: (context, count) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      '$count products',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Expanded(
            child: BlocBuilder<ProductBloc, ProductState>(
              builder: (context, state) {
                if (state.status == ProductStatus.loading) {
                  return const LoadingIndicator();
                }
                if (state.status == ProductStatus.error) {
                  return ErrorView(
                    message: state.errorMessage ?? 'Failed to load',
                    onRetry: () => context.read<ProductBloc>().add(
                      const ProductLoadRequested(),
                    ),
                  );
                }
                if (state.products.isEmpty) {
                  return const EmptyState(
                    title: 'No products',
                    icon: Icons.inventory_2_outlined,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => context.read<ProductBloc>().add(
                    const ProductSyncRequested(),
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: state.products.length,
                    itemBuilder: (_, i) =>
                        _ProductCard(product: state.products[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Camera scanner (Android / iOS / other non-macOS)
// ---------------------------------------------------------------------------

class _ScannerPage extends StatefulWidget {
  const _ScannerPage();

  @override
  State<_ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<_ScannerPage> {
  final MobileScannerController _controller = MobileScannerController();
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Barcode')),
      body: MobileScanner(
        controller: _controller,
        onDetect: (capture) {
          if (_handled) return;
          final code = capture.barcodes.firstOrNull?.rawValue;
          if (code != null && code.isNotEmpty) {
            _handled = true;
            Navigator.of(context).pop(code);
          }
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _ProductCard extends StatelessWidget {
  final Product product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Product icon/image
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: product.imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        product.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Icon(
                          Icons.inventory_2_outlined,
                          color: colors.primary.withValues(alpha: 0.5),
                        ),
                      ),
                    )
                  : Icon(
                      Icons.inventory_2_outlined,
                      color: colors.primary.withValues(alpha: 0.5),
                    ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (product.sku != null)
                        Flexible(
                          child: Text(
                            product.sku!,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      if (product.sku != null && product.categoryName != null)
                        Text(
                          ' \u00B7 ',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      if (product.categoryName != null)
                        Flexible(
                          child: Text(
                            product.categoryName!,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            // Price & stock
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Formatters.currency(product.sellingPrice),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                if (product.isOutOfStock)
                  _badge('Out of stock', colors.error, colors)
                else if (product.isLowStock)
                  _badge('Low stock', colors.secondary, colors)
                else if (product.stockQuantity != null)
                  Text(
                    '${Formatters.quantity(product.stockQuantity!)} in stock',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String label, Color color, ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
