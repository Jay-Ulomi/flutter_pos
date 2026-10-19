import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/l10n/app_strings.dart';
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
import '../../widgets/keyboard_done_bar.dart';
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
import '../../widgets/aduinola/sale_product_tile.dart';
import '../../widgets/aduinola/ui.dart';
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
        CartCustomerSelected(
          customerId: c.id,
          customerName: c.name,
          customerBalance: c.currentBalance,
          loyaltyPoints: c.loyaltyPoints,
        ),
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
        taxable: product.taxable,
        tierPrices: product.tierPrices,
        trackingType: product.trackingType,
        variantId: variant.id,
      );
    }

    // Step 2 — serial/lot number prompt (if required). A product can require
    // both, so prompt for each independently.
    String? serialNumber;
    String? lotNumber;
    if (effectiveProduct.requiresSerial) {
      final code = await _promptTrackingCode(
        context,
        isSerial: true,
        productName: effectiveProduct.name,
      );
      if (code == null || !context.mounted) return;
      serialNumber = code;
    }
    if (effectiveProduct.requiresLot) {
      final code = await _promptTrackingCode(
        context,
        isSerial: false,
        productName: effectiveProduct.name,
      );
      if (code == null || !context.mounted) return;
      lotNumber = code;
    }

    if (context.mounted) {
      context.read<CartBloc>().add(
        CartItemAdded(
          effectiveProduct,
          serialNumber: serialNumber,
          lotNumber: lotNumber,
        ),
      );
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
            Text(
              productName,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
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
                if (v.trim().isNotEmpty)
                  Navigator.of(ctx).pop(v.trim().toUpperCase());
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
      _showCheckoutSheet(context);
    }
  }

  void _showCheckoutSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (sheetCtx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.92,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFC3CEC0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: CheckoutPanel(
                  onBack: () => Navigator.of(sheetCtx).pop(),
                  onSaleCompleted: () {
                    Navigator.of(sheetCtx).pop();
                    _showReceiptSheet(context);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showReceiptSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      isDismissible: false,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.70,
        minChildSize: 0.50,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFC3CEC0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ReceiptPanel(
                  onNewSale: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
      title: const BrandWordmark(height: 30),
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
          icon: const Icon(Icons.settings_outlined),
          tooltip: 'Settings',
          onPressed: () => context.push('/settings'),
        ),
      ],
    );

    final fab = isMobile
        ? null
        : FloatingActionButton(
            onPressed: _openScanner,
            tooltip: Platform.isMacOS
                ? 'Enter Barcode (manual)'
                : 'Scan Barcode',
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
        Column(
          children: [
            // Search pill + custom item
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: Row(
                children: [
                  Expanded(
                    child: SearchPill(
                      controller: _searchCtrl,
                      hint: context.tr('home.search_products'),
                      onChanged: (v) => context.read<ProductBloc>().add(
                        ProductSearchChanged(v),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.qr_code_scanner_rounded, color: theme.colorScheme.primary),
                        tooltip: 'Scan barcode',
                        onPressed: _openScanner,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  RoundIconButton(
                    icon: Icons.add_rounded,
                    tooltip: 'Add custom item',
                    filled: true,
                    size: 50,
                    onPressed: _addCustomItem,
                  ),
                ],
              ),
            ),
            _categoryChips(),
            const SizedBox(height: 8),
            Expanded(child: _productGrid(bottomPadding: 96)),
          ],
        ),
        // Cart summary bar: "⌃ 2 items · total   [Next]"
        Positioned(left: 12, right: 12, bottom: 12, child: _cartSummaryBar()),
      ],
    );
  }

  Future<void> _addCustomItem() async {
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
  }

  /// Product grid shared by phone and desktop: tiles with quantity steppers.
  Widget _productGrid({double bottomPadding = 12}) {
    return BlocBuilder<ProductBloc, ProductState>(
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
        return BlocBuilder<CartBloc, CartState>(
          buildWhen: (p, c) => p.lines != c.lines,
          builder: (context, cart) {
            // Quantity per product id; tracked (serial/lot) lines can't be
            // stepped down from the grid.
            final qty = <String, double>{};
            final tracked = <String>{};
            for (final l in cart.lines) {
              qty[l.product.id] = (qty[l.product.id] ?? 0) + l.quantity;
              if (l.serialNumber != null || l.lotNumber != null || l.product.variantId != null) {
                tracked.add(l.product.id);
              }
            }
            return GridView.builder(
              padding: EdgeInsets.fromLTRB(16, 4, 16, bottomPadding),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 210,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.78,
              ),
              itemCount: state.products.length,
              itemBuilder: (_, i) {
                final p = state.products[i];
                final q = qty[p.id] ?? 0;
                return SaleProductTile(
                  product: p,
                  quantity: q,
                  onAdd: () => _addProductToCart(context, p),
                  onRemove: q > 0 && !tracked.contains(p.id)
                      ? () => context.read<CartBloc>().add(CartItemQtyChanged(p.id, q - 1))
                      : null,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _cartSummaryBar() {
    return BlocBuilder<CartBloc, CartState>(
      builder: (context, cart) {
        if (cart.isEmpty) return const SizedBox.shrink();
        final cs = Theme.of(context).colorScheme;
        return Material(
          color: cs.surface,
          elevation: 6,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: cs.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            child: Row(
              children: [
                RoundIconButton(
                  key: const ValueKey('open-cart'),
                  icon: Icons.keyboard_arrow_up_rounded,
                  tooltip: context.tr('home.view_cart'),
                  onPressed: () => _showCartSheet(context),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () => _showCartSheet(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          context.tr('home.items', {'count': cart.itemCount}),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        MoneyText(
                          cart.total,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: cs.primary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                FilledButton(
                  key: const ValueKey('cart-next'),
                  style: FilledButton.styleFrom(minimumSize: const Size(110, 46)),
                  onPressed: _handleCheckout,
                  child: Text(context.tr('common.continue')),
                ),
              ],
            ),
          ),
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
      selector: (state) =>
          (categories: state.categories, selectedId: state.selectedCategoryId),
      builder: (context, data) {
        if (data.categories.isEmpty) return const SizedBox.shrink();
        final all = <Category?>[null, ...data.categories];
        return PillChips<Category?>(
          items: all,
          selected: all.firstWhere((c) => c?.id == data.selectedId, orElse: () => null),
          labelOf: (c) => c?.name ?? context.tr('common.all'),
          onSelected: (c) => context.read<ProductBloc>().add(ProductCategoryChanged(c?.id)),
        );
      },
    );
  }

  // ---- product pane (desktop only) ----

  Widget _productsPane(ThemeData theme) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          child: Row(
            children: [
              Expanded(
                child: SearchPill(
                  controller: _searchCtrl,
                  hint: context.tr('home.search_products'),
                  onChanged: (v) =>
                      context.read<ProductBloc>().add(ProductSearchChanged(v)),
                ),
              ),
              const SizedBox(width: 10),
              RoundIconButton(
                icon: Icons.add_rounded,
                tooltip: 'Add custom item',
                filled: true,
                size: 50,
                onPressed: _addCustomItem,
              ),
            ],
          ),
        ),
        _categoryChips(),
        const SizedBox(height: 8),
        Expanded(child: _productGrid()),
      ],
    );
  }

  // ---- cart pane (desktop sidebar + mobile sheet) ----

  /// The scrollable cart-line-items region. Factored out of [_cartPane] so
  /// the [compact]-vs-not branching (Flexible+shrinkWrap vs Expanded) can
  /// wrap the whole thing without duplicating the ListView.builder body.
  Widget _buildItemsSection({
    required BuildContext context,
    required CartState cart,
    required bool compact,
    required double keyboardHeight,
  }) {
    // Inflate the bottom inset by the Done-bar height so a focused
    // price/qty field scrolls above the bar, not behind it.
    final itemsList = MediaQuery(
      data: MediaQuery.of(context).copyWith(
        viewInsets: MediaQuery.of(context).viewInsets.copyWith(
          bottom:
              keyboardHeight +
              (keyboardHeight > 0 ? KeyboardDoneBar.height : 0),
        ),
      ),
      child: cart.isEmpty
          ? const EmptyState(
              title: 'Cart is empty',
              subtitle: 'Tap a product to add',
              icon: Icons.shopping_bag_outlined,
            )
          : ListView.builder(
              shrinkWrap: compact,
              physics: compact ? const ClampingScrollPhysics() : null,
              padding: const EdgeInsets.symmetric(vertical: 8),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              itemCount: cart.lines.length,
              itemBuilder: (_, i) {
                final line = cart.lines[i];
                final auth = context.read<AuthBloc>().state;
                final canOverridePrice = auth.can('override_price');
                final canDiscount = auth.can('apply_discount');
                return CartItemTile(
                  key: ValueKey(
                    '${line.product.id}_${line.serialNumber}_${line.lotNumber}',
                  ),
                  line: line,
                  canEditPrice: canOverridePrice,
                  onQtyChanged: (q) => context.read<CartBloc>().add(
                    CartItemQtyChanged(line.product.id, q),
                  ),
                  onPriceChanged: (p) => context.read<CartBloc>().add(
                    CartItemPriceChanged(line.product.id, p),
                  ),
                  // Tier prices are server-authorised: no override permission needed.
                  onTierChanged: (tier) => context.read<CartBloc>().add(
                    CartItemTierChanged(line.product.id, tier),
                  ),
                  onRemove: () => context.read<CartBloc>().add(
                    CartItemRemoved(line.product.id),
                  ),
                  // Hidden entirely when the user lacks discount permission.
                  onTapDiscount: !canDiscount
                      ? null
                      : () async {
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
    );

    return compact ? Flexible(child: itemsList) : Expanded(child: itemsList);
  }

  // [compact] is used by the mobile bottom sheet (_showCartSheet): the items
  // list sizes to its own content (via shrinkWrap) instead of force-filling
  // all remaining space, so a short cart doesn't leave a large gap before the
  // totals/checkout button. The desktop side-panel call site leaves this
  // false, keeping checkout pinned to the bottom of the full-height panel.
  Widget _cartPane({bool compact = false}) {
    return GestureDetector(
      // Numeric keyboards have no "done" key — tap anywhere outside a field to
      // dismiss it (child buttons/fields still handle their own taps first).
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: BlocBuilder<CartBloc, CartState>(
        builder: (context, cart) {
          final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;
          return Stack(
            children: [
              Positioned.fill(
                child: Column(
                  children: [
                    // ── Header ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: BrandColors.primary.withValues(
                                alpha: 0.10,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.shopping_bag_outlined,
                              size: 18,
                              color: BrandColors.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Cart',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF14261A),
                            ),
                          ),
                          if (cart.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: BrandColors.primary,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${cart.lines.length}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                          const Spacer(),
                          BlocBuilder<HeldSalesCubit, List<HeldSale>>(
                            builder: (context, held) {
                              if (held.isEmpty) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: GestureDetector(
                                  onTap: () => showHeldSalesSheet(context),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 9,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF3C7),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.pause_circle_outline,
                                          size: 13,
                                          color: Color(0xFFD97706),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Held (${held.length})',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFFD97706),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          if (cart.isNotEmpty) ...[
                            GestureDetector(
                              onTap: () {
                                context.read<HeldSalesCubit>().hold(cart);
                                context.read<CartBloc>().add(
                                  const CartCleared(),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEDF2EB),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.back_hand_outlined,
                                  size: 15,
                                  color: Color(0xFF4E5E52),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => context.read<CartBloc>().add(
                                const CartCleared(),
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEE2E2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.delete_outline,
                                  size: 15,
                                  color: Color(0xFFD93A2B),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // ── Customer row ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                      child: _customerRow(context, cart),
                    ),

                    const Divider(height: 1, color: Color(0xFFDCE4D8)),

                    // ── Items ──
                    // In compact mode (mobile bottom sheet) the list sizes to its
                    // own content via shrinkWrap, so a short cart doesn't leave a
                    // gap before totals/checkout — any leftover space collects
                    // harmlessly below the checkout button instead. The desktop
                    // panel keeps Expanded so checkout stays pinned to the bottom
                    // of the full-height panel regardless of cart size.
                    _buildItemsSection(
                      context: context,
                      cart: cart,
                      compact: compact,
                      keyboardHeight: keyboardHeight,
                    ),

                    if (cart.isNotEmpty) ...[
                      const Divider(height: 1, color: Color(0xFFDCE4D8)),
                      _totalsSection(cart),
                    ],

                    // ── Checkout button ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                      child: SizedBox(
                        height: 52,
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: cart.isEmpty ? null : _handleCheckout,
                          style: FilledButton.styleFrom(
                            backgroundColor: BrandColors.primary,
                            disabledBackgroundColor: const Color(0xFFC3CEC0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Checkout',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              if (cart.isNotEmpty) ...[
                                const SizedBox(width: 10),
                                Container(
                                  width: 1,
                                  height: 16,
                                  color: Colors.white.withValues(alpha: 0.4),
                                ),
                                const SizedBox(width: 10),
                                MoneyText(
                                  cart.total,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // "Done" bar pinned above the soft keyboard — numeric keyboards have
              // no return/done key, so this gives an explicit way to dismiss it.
              if (keyboardHeight > 0)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: keyboardHeight,
                  child: const KeyboardDoneBar(),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _customerRow(BuildContext context, CartState cart) {
    final name = cart.hasCustomer
        ? (cart.selectedCustomerName ?? 'Customer')
        : 'Add customer';
    return GestureDetector(
      onTap: _pickCustomer,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: cart.hasCustomer
              ? const Color(0xFFDCFCE7)
              : const Color(0xFFEDF2EB),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: cart.hasCustomer
                ? const Color(0xFFBBF7D0)
                : const Color(0xFFDCE4D8),
          ),
        ),
        child: Row(
          children: [
            Icon(
              cart.hasCustomer ? Icons.person_rounded : Icons.person_outline,
              size: 16,
              color: cart.hasCustomer
                  ? BrandColors.primary
                  : const Color(0xFF8A968D),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: cart.hasCustomer
                      ? FontWeight.w600
                      : FontWeight.w400,
                  color: cart.hasCustomer
                      ? const Color(0xFF166534)
                      : const Color(0xFF8A968D),
                ),
              ),
            ),
            if (cart.hasCustomer)
              GestureDetector(
                onTap: () =>
                    context.read<CartBloc>().add(const CartCustomerCleared()),
                child: const Icon(
                  Icons.close,
                  size: 15,
                  color: Color(0xFF8A968D),
                ),
              )
            else
              const Icon(
                Icons.chevron_right,
                size: 16,
                color: Color(0xFF8A968D),
              ),
          ],
        ),
      ),
    );
  }

  Widget _totalsSection(CartState cart) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          _totalRow('Subtotal', cart.subtotal),
          const SizedBox(height: 4),
          _totalRow('Tax', cart.taxAmount),
          if (cart.discount > 0) ...[
            const SizedBox(height: 4),
            _totalRow(
              'Discount',
              -cart.discount,
              valueColor: const Color(0xFF2E8B3E),
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1, color: Color(0xFFDCE4D8)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF14261A),
                ),
              ),
              MoneyText(
                cart.total,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: BrandColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _totalRow(String label, double amount, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Color(0xFF4E5E52)),
        ),
        MoneyText(
          amount,
          style: TextStyle(
            fontSize: 13,
            color: valueColor ?? const Color(0xFF2E3D33),
          ),
        ),
      ],
    );
  }

  void _showCartSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.88,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: _CartSheet(
          cartPane: _cartPane(),
          onAddProduct: _addProductToCart,
          onScan: _openScanner,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Cart sheet — search + scan bar over the cart pane
// ---------------------------------------------------------------------------

class _CartSheet extends StatefulWidget {
  final Widget cartPane;
  final Future<void> Function(BuildContext, Product) onAddProduct;
  final VoidCallback onScan;

  const _CartSheet({
    required this.cartPane,
    required this.onAddProduct,
    required this.onScan,
  });

  @override
  State<_CartSheet> createState() => _CartSheetState();
}

class _CartSheetState extends State<_CartSheet> {
  final _searchCtrl = TextEditingController();
  bool _hasQuery = false;
  late final ProductBloc _productBloc;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _productBloc = context.read<ProductBloc>();
  }

  @override
  void dispose() {
    _productBloc.add(const ProductSearchChanged(''));
    _searchCtrl.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchCtrl.clear();
    context.read<ProductBloc>().add(const ProductSearchChanged(''));
    setState(() => _hasQuery = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Drag handle ──
        Container(
          margin: const EdgeInsets.only(top: 10, bottom: 8),
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFFC3CEC0),
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        // ── Search + scan bar ──
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: TextField(
                    controller: _searchCtrl,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search products to add...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _hasQuery
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 16),
                              tooltip: 'Clear search',
                              onPressed: _clearSearch,
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFDCE4D8)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFDCE4D8)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: BrandColors.primary,
                          width: 1.5,
                        ),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF4F7F2),
                    ),
                    onChanged: (v) {
                      context.read<ProductBloc>().add(ProductSearchChanged(v));
                      setState(() => _hasQuery = v.isNotEmpty);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: widget.onScan,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDF2EB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFDCE4D8)),
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner,
                    size: 20,
                    color: Color(0xFF2E3D33),
                  ),
                ),
              ),
            ],
          ),
        ),

        const Divider(height: 1, color: Color(0xFFDCE4D8)),

        Expanded(child: _hasQuery ? _searchArea(context) : widget.cartPane),
      ],
    );
  }

  Widget _searchArea(BuildContext context) {
    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, state) {
        if (state.status == ProductStatus.loading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: BrandColors.primary,
              ),
            ),
          );
        }
        if (state.products.isEmpty) {
          // No matches for the in-sheet search — keep the cart visible below
          // a small notice instead of hiding items/totals/checkout behind a
          // full-screen empty state.
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search_off_rounded,
                      size: 16,
                      color: Color(0xFF8A968D),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No products found for "${_searchCtrl.text}"',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF4E5E52),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFDCE4D8)),
              Expanded(child: widget.cartPane),
            ],
          );
        }
        return _searchResultsList(state);
      },
    );
  }

  Widget _searchResultsList(ProductState state) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: state.products.length,
      itemBuilder: (_, i) {
        final p = state.products[i];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 2,
          ),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEDF2EB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: p.imageUrl != null && p.imageUrl!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      p.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, err, stack) => const Icon(
                        Icons.inventory_2_outlined,
                        size: 18,
                        color: Color(0xFF8A968D),
                      ),
                    ),
                  )
                : const Icon(
                    Icons.inventory_2_outlined,
                    size: 18,
                    color: Color(0xFF8A968D),
                  ),
          ),
          title: Text(
            p.name,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF14261A),
            ),
          ),
          subtitle: Row(
            children: [
              MoneyText(
                p.sellingPrice,
                style: const TextStyle(fontSize: 12, color: Color(0xFF4E5E52)),
              ),
              if (p.stockLabel != null) ...[
                const Text(
                  '  ·  ',
                  style: TextStyle(fontSize: 12, color: Color(0xFFC3CEC0)),
                ),
                Icon(
                  Icons.inventory_2_outlined,
                  size: 11,
                  color: p.isOutOfStock
                      ? const Color(0xFFD93A2B)
                      : const Color(0xFF8A968D),
                ),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    p.stockLabel!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: p.isOutOfStock
                          ? const Color(0xFFD93A2B)
                          : p.isLowStock
                          ? const Color(0xFFD97706)
                          : const Color(0xFF4E5E52),
                    ),
                  ),
                ),
              ],
            ],
          ),
          trailing: GestureDetector(
            onTap: () async {
              await widget.onAddProduct(context, p);
              if (mounted) _clearSearch();
            },
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: BrandColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.add, size: 18, color: Colors.white),
            ),
          ),
        );
      },
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
