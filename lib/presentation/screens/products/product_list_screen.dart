import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/product_models.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/product/product_bloc.dart';
import '../../blocs/product/product_event.dart';
import '../../blocs/product/product_state.dart';
import '../../widgets/aduinola/app_page.dart';
import '../../widgets/aduinola/ui.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/money_text.dart';
import 'add_product_screen.dart';

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
      final barcode = await Navigator.of(
        context,
      ).push<String>(MaterialPageRoute(builder: (_) => const _ScannerPage()));
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

    final canAdd = context.select<AuthBloc, bool>(
      (b) => b.state.can(AddProductScreen.permission),
    );
    return AppPage(
      title: '',
      titleWidget: Text(context.tr('inv.title')),
      actions: [
        IconButton(
          icon: const Icon(Icons.qr_code_scanner),
          tooltip: 'Scan barcode',
          onPressed: _openScanner,
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh',
          onPressed: () =>
              context.read<ProductBloc>().add(const ProductSyncRequested()),
        ),
      ],
      floatingActionButton: canAdd
          ? FloatingActionButton.extended(
              heroTag: 'add-product',
              shape: const StadiumBorder(),
              onPressed: () => context.push('/products/new'),
              icon: const Icon(Icons.add_rounded),
              label: Text(context.tr('inv.add_product')),
            )
          : null,
      padBody: false,
      body: Column(
        children: [
          Padding(
            padding: AppPage.insets(context, top: 12, bottom: 8),
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
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w400,
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
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w400,
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
                  // Same flat list-with-divider style as TransactionTile.
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    itemCount: state.products.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, i) =>
                        _ProductTile(product: state.products[i]),
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

/// One row of the list: same shape as [TransactionTile] \u2014 a category label,
/// the product's name, then its SKU \u2026 price + a low/out-of-stock pill.
class _ProductTile extends StatelessWidget {
  final Product product;
  const _ProductTile({required this.product});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    // Category is already the label line above; don't repeat it here.
    final subtitle = product.sku ?? '';

    // No edit screen to open yet, so this isn't wrapped in an InkWell —
    // nothing to tap through to (Transactions/Parties rows navigate).
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (product.categoryName != null)
                  Text(product.categoryName!, style: theme.textTheme.labelSmall?.copyWith(color: colors.primary)),
                const SizedBox(height: 2),
                Text(product.name, style: theme.textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                if (subtitle.isNotEmpty) Text(subtitle, style: theme.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              MoneyText(product.sellingPrice, style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              if (product.isOutOfStock)
                const StatusPill('Out of stock', tone: PillTone.unpaid)
              else if (product.isLowStock)
                const StatusPill('Low stock', tone: PillTone.partial)
              else if (product.stockQuantity != null)
                Text(
                  '${Formatters.quantity(product.stockQuantity!)} in stock',
                  style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
