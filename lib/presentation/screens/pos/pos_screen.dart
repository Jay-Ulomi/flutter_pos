import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/theme/brand_colors.dart';
import '../../../data/models/product_models.dart';
import '../../blocs/cart/cart_bloc.dart';
import '../../blocs/cart/cart_event.dart';
import '../../blocs/cart/cart_state.dart';
import '../../blocs/customer_group/customer_group_bloc.dart';
import '../../blocs/held_sales/held_sales_cubit.dart';
import '../../blocs/product/product_bloc.dart';
import '../../blocs/product/product_event.dart';
import '../../blocs/product/product_state.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/business/business_bloc.dart';
import '../laundry/laundry_orders_screen.dart';
import '../../widgets/cart_item_tile.dart';
import '../../widgets/customer_picker_sheet.dart';
import '../../widgets/custom_item_dialog.dart';
import '../../widgets/discount_dialog.dart';
import '../../widgets/checkout_panel.dart';
import '../../widgets/receipt_panel.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/held_sales_sheet.dart';
import '../../widgets/variant_picker_sheet.dart';
import 'customer_display_screen.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/money_text.dart';
import '../../widgets/product_card.dart';
import '../../widgets/responsive_shell.dart';

// ---------------------------------------------------------------------------
// Keyboard shortcut intents
// ---------------------------------------------------------------------------

class _OpenCustomerPickerIntent extends Intent {
  const _OpenCustomerPickerIntent();
}

class _CheckoutIntent extends Intent {
  const _CheckoutIntent();
}

class _ClearCartIntent extends Intent {
  const _ClearCartIntent();
}

class _CloseModalIntent extends Intent {
  const _CloseModalIntent();
}

// ---------------------------------------------------------------------------
// PosScreen
// ---------------------------------------------------------------------------

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final _searchCtrl = TextEditingController();
  bool _showCheckout = false;
  bool _showReceipt = false;

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

  // ---- barcode / scanner ----

  void _openScanner() async {
    if (Platform.isMacOS) {
      _openMacBarcodeDialog();
    } else {
      final barcode = await Navigator.of(
        context,
      ).push<String>(MaterialPageRoute(builder: (_) => const _ScannerPage()));
      if (barcode != null && mounted) {
        context.read<ProductBloc>().add(ProductBarcodeScanned(barcode));
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
      context.read<ProductBloc>().add(ProductBarcodeScanned(code));
    }
  }

  // ---- customer picker ----

  Future<void> _pickCustomer() async {
    final cartBloc = context.read<CartBloc>();
    final groupBloc = context.read<CustomerGroupBloc>();
    final picked = await showCustomerPickerSheet(context);
    if (picked == null) return;
    if (picked.isWalkIn) {
      cartBloc.add(const CartCustomerCleared());
      cartBloc.add(const CartDiscountApplied(0));
    } else {
      final c = picked.customer!;
      cartBloc.add(
        CartCustomerSelected(customerId: c.id, customerName: c.name),
      );
      // Auto-apply customer group discount
      if (c.customerGroupId != null) {
        final groups = groupBloc.state.groups;
        for (final g in groups) {
          if (g.id == c.customerGroupId &&
              g.discountPercent != null &&
              g.discountPercent! > 0) {
            final cart = cartBloc.state;
            final discountAmount = cart.subtotal * (g.discountPercent! / 100);
            cartBloc.add(CartDiscountApplied(discountAmount));
            break;
          }
        }
      }
    }
  }

  Future<void> _addProductToCart(BuildContext context, Product product) async {
    // Step 1 — variant selection (if product has variants).
    Product effectiveProduct = product;
    if (product.hasVariants) {
      final variant = await showVariantPickerSheet(context, product);
      if (variant == null || !context.mounted) return;
      effectiveProduct = Product(
        id: product.id,
        name: '${product.name} · ${variant.name}',
        description: product.description,
        sku: variant.sku ?? product.sku,
        barcode: variant.barcode ?? product.barcode,
        sellingPrice: variant.sellingPrice ?? product.sellingPrice,
        costPrice: variant.costPrice ?? product.costPrice,
        categoryId: product.categoryId,
        categoryName: product.categoryName,
        unit: product.unit,
        stockQuantity: product.stockQuantity,
        minStockLevel: product.minStockLevel,
        trackInventory: product.trackInventory,
        isActive: product.isActive,
        imageUrl: product.imageUrl,
        taxRate: product.taxRate,
        tierPrices: product.tierPrices,
        trackingType: product.trackingType,
      );
    }

    // Step 2 — serial/lot number prompt (if required).
    String? serialNumber;
    String? lotNumber;
    if (effectiveProduct.requiresSerial || effectiveProduct.requiresLot) {
      final code = await _promptTrackingCode(
        context,
        isSerial: effectiveProduct.requiresSerial,
        productName: effectiveProduct.name,
      );
      if (code == null || !context.mounted) return;
      if (effectiveProduct.requiresSerial) {
        serialNumber = code;
      } else {
        lotNumber = code;
      }
    }

    if (context.mounted) {
      context.read<CartBloc>().add(CartItemAdded(
        effectiveProduct,
        serialNumber: serialNumber,
        lotNumber: lotNumber,
      ));
    }
  }

  Future<String?> _promptTrackingCode(
    BuildContext context, {
    required bool isSerial,
    required String productName,
  }) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isSerial ? 'Enter Serial Number' : 'Enter Lot Number'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(productName,
                style: const TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: isSerial ? 'e.g. SN001234' : 'e.g. LOT-2024-01',
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (v) {
                if (v.trim().isNotEmpty) Navigator.of(ctx).pop(v.trim().toUpperCase());
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final v = ctrl.text.trim().toUpperCase();
              if (v.isNotEmpty) Navigator.of(ctx).pop(v);
            },
            child: const Text('Add to Cart'),
          ),
        ],
      ),
    );
  }

  // ---- keyboard action handlers ----

  void _handleClearCart() {
    context.read<CartBloc>().add(const CartCleared());
  }

  void _handleCheckout() {
    final cart = context.read<CartBloc>().state;
    if (cart.isEmpty) return;
    final isWide = MediaQuery.sizeOf(context).width >= 900;
    if (isWide) {
      setState(() => _showCheckout = true);
    } else {
      context.push('/checkout');
    }
  }

  void _handleCloseModal() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthBloc>().state;
    final business = context.watch<BusinessBloc>().state.selected;
    final businessType = business?.type ?? auth.selectedBusinessType ?? '';
    if (businessType.trim().toUpperCase() == 'LAUNDRY') {
      return const LaundryOrdersScreen();
    }

    final theme = Theme.of(context);
    final isWide = MediaQuery.sizeOf(context).width >= 900;
    final isMobile = MediaQuery.sizeOf(context).width < 720;

    final appBar = AppBar(
      title: const Text('POS'),
      actions: [
        IconButton(
          icon: const Icon(Icons.tv_outlined),
          tooltip: 'Customer Display',
          onPressed: () {
            final cartBloc = context.read<CartBloc>();
            Navigator.of(context).push(
              MaterialPageRoute(
                fullscreenDialog: true,
                builder: (_) => BlocProvider<CartBloc>.value(
                  value: cartBloc,
                  child: const CustomerDisplayScreen(),
                ),
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () =>
              context.read<ProductBloc>().add(const ProductSyncRequested()),
        ),
      ],
    );

    final fab = isMobile
        ? null
        : FloatingActionButton(
            onPressed: _openScanner,
            tooltip:
                Platform.isMacOS ? 'Enter Barcode (manual)' : 'Scan Barcode',
            child: const Icon(Icons.qr_code_scanner),
          );

    final body = MultiBlocListener(
      listeners: [
        BlocListener<ProductBloc, ProductState>(
          listenWhen: (p, c) => p.scannedProduct != c.scannedProduct,
          listener: (context, state) {
            final sp = state.scannedProduct;
            if (sp != null) {
              context.read<CartBloc>().add(CartItemAdded(sp));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${sp.name} added to cart')),
              );
            }
          },
        ),
        BlocListener<ProductBloc, ProductState>(
          listenWhen: (p, c) => p.errorMessage != c.errorMessage,
          listener: (context, state) {
            if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
            }
          },
        ),
      ],
      child: isWide
          ? Row(
              children: [
                Expanded(flex: 3, child: _productsPane(theme)),
                const VerticalDivider(width: 1),
                Expanded(
                  flex: 2,
                  child: _showReceipt
                      ? ReceiptPanel(
                          onNewSale: () => setState(() {
                            _showReceipt = false;
                            _showCheckout = false;
                          }),
                        )
                      : _showCheckout
                      ? CheckoutPanel(
                          onBack: () => setState(() => _showCheckout = false),
                          onSaleCompleted: () => setState(() {
                            _showReceipt = true;
                            _showCheckout = false;
                          }),
                        )
                      : _cartPane(),
                ),
              ],
            )
          : _mobileLayout(theme),
    );

    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.f2): _OpenCustomerPickerIntent(),
        SingleActivator(LogicalKeyboardKey.f4): _CheckoutIntent(),
        SingleActivator(LogicalKeyboardKey.f8): _ClearCartIntent(),
        SingleActivator(LogicalKeyboardKey.escape): _CloseModalIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _OpenCustomerPickerIntent: CallbackAction<_OpenCustomerPickerIntent>(
            onInvoke: (_) => _pickCustomer(),
          ),
          _CheckoutIntent: CallbackAction<_CheckoutIntent>(
            onInvoke: (_) => _handleCheckout(),
          ),
          _ClearCartIntent: CallbackAction<_ClearCartIntent>(
            onInvoke: (_) => _handleClearCart(),
          ),
          _CloseModalIntent: CallbackAction<_CloseModalIntent>(
            onInvoke: (_) => _handleCloseModal(),
          ),
        },
        child: Focus(
          autofocus: true,
          child: ResponsiveShell(
            appBar: appBar,
            floatingActionButton: fab,
            child: body,
          ),
        ),
      ),
    );
  }

  // ---- mobile layout: products + sticky bottom cart bar ----

  Widget _mobileLayout(ThemeData theme) {
    return Stack(
      children: [
        // Products grid fills entire area
        Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: TextField(
                        controller: _searchCtrl,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Search products...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.qr_code_scanner, size: 20),
                            onPressed: _openScanner,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerLow,
                        ),
                        onChanged: (v) =>
                            context.read<ProductBloc>().add(ProductSearchChanged(v)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 44,
                    width: 44,
                    child: IconButton.filled(
                      tooltip: 'Add custom item',
                      onPressed: () async {
                        final cartBloc = context.read<CartBloc>();
                        final result = await showCustomItemDialog(context);
                        if (result != null) {
                          cartBloc.add(
                            CartCustomItemAdded(
                              name: result.name,
                              price: result.price,
                              quantity: result.quantity,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.add, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            // Category chips
            _categoryChips(),
            // Products grid — padded at bottom so items aren't hidden behind cart bar
            Expanded(
              child: BlocBuilder<ProductBloc, ProductState>(
                builder: (context, state) {
                  if (state.status == ProductStatus.loading) {
                    return const LoadingIndicator();
                  }
                  if (state.status == ProductStatus.error) {
                    return ErrorView(
                      message: state.errorMessage ?? 'Failed to load products',
                      onRetry: () => context.read<ProductBloc>().add(
                        const ProductLoadRequested(),
                      ),
                    );
                  }
                  if (state.products.isEmpty) {
                    return const EmptyState(
                      title: 'No products found',
                      icon: Icons.inventory_2_outlined,
                    );
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 88),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 160,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.78,
                    ),
                    itemCount: state.products.length,
                    itemBuilder: (_, i) {
                      final p = state.products[i];
                      return ProductCard(
                        product: p,
                        onTap: () => _addProductToCart(context, p),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
        // Floating cart button
        Positioned(
          right: 16,
          bottom: 16,
          child: _mobileCartFab(),
        ),
      ],
    );
  }

  Widget _mobileCartFab() {
    return BlocBuilder<CartBloc, CartState>(
      builder: (context, cart) {
        if (cart.isEmpty) return const SizedBox.shrink();
        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Circular FAB
            GestureDetector(
              onTap: () => _showCartSheet(context),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: BrandColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: BrandColors.primary.withValues(alpha: 0.45),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.shopping_bag_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
            // Orange item-count badge
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: BrandColors.secondary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${cart.lines.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _categoryChips() {
    return BlocSelector<
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
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: data.categories.length + 1,
            separatorBuilder: (_, _) => const SizedBox(width: 6),
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
                    fontSize: 12,
                  ),
                  side: BorderSide(
                    color: selected ? cs.primary : cs.outlineVariant,
                  ),
                  visualDensity: VisualDensity.compact,
                  onSelected: (_) => context.read<ProductBloc>().add(
                    const ProductCategoryChanged(null),
                  ),
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
                  fontSize: 12,
                ),
                side: BorderSide(
                  color: selected ? cs.primary : cs.outlineVariant,
                ),
                visualDensity: VisualDensity.compact,
                onSelected: (_) => context.read<ProductBloc>().add(
                  ProductCategoryChanged(cat.id),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ---- product pane (desktop only) ----

  Widget _productsPane(ThemeData theme) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Search products or scan barcode',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (v) =>
                      context.read<ProductBloc>().add(ProductSearchChanged(v)),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                tooltip: 'Add custom item',
                onPressed: () async {
                  final cartBloc = context.read<CartBloc>();
                  final result = await showCustomItemDialog(context);
                  if (result != null) {
                    cartBloc.add(
                      CartCustomItemAdded(
                        name: result.name,
                        price: result.price,
                        quantity: result.quantity,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ),
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
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
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
                  );
                },
              ),
            );
          },
        ),
        Expanded(
          child: BlocBuilder<ProductBloc, ProductState>(
            builder: (context, state) {
              if (state.status == ProductStatus.loading) {
                return const LoadingIndicator();
              }
              if (state.status == ProductStatus.error) {
                return ErrorView(
                  message: state.errorMessage ?? 'Failed to load products',
                  onRetry: () => context.read<ProductBloc>().add(
                    const ProductLoadRequested(),
                  ),
                );
              }
              if (state.products.isEmpty) {
                return const EmptyState(
                  title: 'No products found',
                  icon: Icons.inventory_2_outlined,
                );
              }
              return GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 180,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
                itemCount: state.products.length,
                itemBuilder: (_, i) {
                  final p = state.products[i];
                  return ProductCard(
                    product: p,
                    onTap: () => _addProductToCart(context, p),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ---- cart pane (desktop sidebar) ----

  Widget _cartPane() {
    return BlocBuilder<CartBloc, CartState>(
      builder: (context, cart) {
        final theme = Theme.of(context);
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              color: theme.colorScheme.surfaceContainerLow,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shopping_cart_outlined),
                      const SizedBox(width: 8),
                      Text(
                        'Cart (${cart.lines.length})',
                        style: theme.textTheme.titleMedium,
                      ),
                      const Spacer(),
                      BlocBuilder<HeldSalesCubit, List<HeldSale>>(
                        builder: (context, held) {
                          if (held.isEmpty) return const SizedBox.shrink();
                          return TextButton.icon(
                            onPressed: () => showHeldSalesSheet(context),
                            icon: Badge(
                              label: Text('${held.length}'),
                              child: const Icon(Icons.pause_circle_outline),
                            ),
                            label: const Text('Held'),
                          );
                        },
                      ),
                      if (cart.isNotEmpty) ...[
                        TextButton.icon(
                          onPressed: () {
                            context.read<HeldSalesCubit>().hold(cart);
                            context.read<CartBloc>().add(const CartCleared());
                          },
                          icon: const Icon(Icons.back_hand_outlined),
                          label: const Text('Hold'),
                        ),
                        TextButton.icon(
                          onPressed: () =>
                              context.read<CartBloc>().add(const CartCleared()),
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Clear'),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  _customerChip(context, cart),
                ],
              ),
            ),
            Expanded(
              child: cart.isEmpty
                  ? const EmptyState(
                      title: 'Cart is empty',
                      subtitle: 'Tap a product to add',
                      icon: Icons.shopping_cart_outlined,
                    )
                  : ListView.separated(
                      itemCount: cart.lines.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final line = cart.lines[i];
                        return CartItemTile(
                          line: line,
                          onQtyChanged: (q) => context.read<CartBloc>().add(
                            CartItemQtyChanged(line.product.id, q),
                          ),
                          onRemove: () => context.read<CartBloc>().add(
                            CartItemRemoved(line.product.id),
                          ),
                          onTapDiscount: () async {
                            final result = await showDiscountDialog(
                              context,
                              productName: line.product.name,
                              currentDiscount: line.discount,
                              currentIsPercent: line.isPercentDiscount,
                            );
                            if (result != null && context.mounted) {
                              context.read<CartBloc>().add(
                                CartItemDiscountApplied(
                                  line.product.id,
                                  discount: result.value,
                                  isPercent: result.isPercent,
                                ),
                              );
                            }
                          },
                        );
                      },
                    ),
            ),
            const Divider(height: 1),
            _totals(cart),
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                height: 52,
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: cart.isEmpty ? null : _handleCheckout,
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    foregroundColor: Theme.of(context).colorScheme.onSecondary,
                    disabledBackgroundColor:
                        Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                  ),
                  icon: const Icon(Icons.payment),
                  label: Text(
                    Platform.isAndroid || Platform.isIOS
                        ? 'Checkout'
                        : 'Checkout  [F4]',
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _customerChip(BuildContext context, CartState cart) {
    final theme = Theme.of(context);
    final label = cart.hasCustomer
        ? cart.selectedCustomerName ?? 'Customer'
        : 'Walk-in (no customer)';
    return Align(
      alignment: Alignment.centerLeft,
      child: InputChip(
        avatar: Icon(
          cart.hasCustomer ? Icons.person : Icons.person_outline,
          size: 18,
        ),
        label: Text(label),
        onPressed: _pickCustomer,
        onDeleted: cart.hasCustomer
            ? () => context.read<CartBloc>().add(const CartCustomerCleared())
            : null,
        deleteIcon: cart.hasCustomer ? const Icon(Icons.close, size: 16) : null,
        backgroundColor: cart.hasCustomer
            ? theme.colorScheme.primaryContainer
            : null,
      ),
    );
  }

  Widget _totals(CartState cart) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          _totalRow('Subtotal', cart.subtotal),
          _totalRow('Tax', cart.taxAmount),
          if (cart.discount > 0) _totalRow('Discount', -cart.discount),
          const Divider(),
          _totalRow('Total', cart.total, emphasize: true),
        ],
      ),
    );
  }

  Widget _totalRow(String label, double amount, {bool emphasize = false}) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: emphasize
                ? TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: cs.onSurface,
                  )
                : TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
          ),
          MoneyText(
            amount,
            style: emphasize
                ? TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: cs.primary,
                  )
                : TextStyle(color: cs.onSurface, fontSize: 13),
          ),
        ],
      ),
    );
  }

  void _showCartSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(child: _cartPane()),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Camera scanner page (Android / iOS / other non-macOS platforms)
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
