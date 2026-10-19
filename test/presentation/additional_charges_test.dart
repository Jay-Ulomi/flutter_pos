import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_pos/core/theme/app_theme.dart';
import 'package:flutter_pos/data/models/product_models.dart';
import 'package:flutter_pos/data/models/sale_models.dart';
import 'package:flutter_pos/presentation/blocs/cart/cart_bloc.dart';
import 'package:flutter_pos/presentation/blocs/cart/cart_event.dart';
import 'package:flutter_pos/presentation/blocs/cart/cart_state.dart';
import 'package:flutter_pos/presentation/blocs/held_sales/held_sales_cubit.dart';
import 'package:flutter_pos/presentation/widgets/additional_charges.dart';
import 'package:flutter_pos/presentation/widgets/checkout_pricing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const burger = Product(id: 'p1', name: 'Burger', sellingPrice: 10000, taxRate: 0);
  const delivery = SaleCharge(name: 'Delivery', amount: 2000);
  const packaging = SaleCharge(name: 'Packaging', amount: 1000, taxRate: 18);

  CartState cartWith(List<SaleCharge> charges, {double discount = 0}) => CartState(
        lines: const [CartLine(product: burger, quantity: 2)],
        discount: discount,
        charges: charges,
      );

  test('charges add to the total with their tax; the discount never eats them', () {
    final cart = cartWith(const [delivery, packaging]);
    expect(packaging.taxAmount, 180);
    expect(cart.chargesTotal, 3180);
    expect(cart.total, 20000 + 3180);
    expect(cartWith(const [delivery], discount: 50000).total, 2000);
  });

  test('preview and sale bodies carry additionalCharges per the contract', () {
    final body = CheckoutPricing.previewBody(cartWith(const [packaging]));
    expect(body['additionalCharges'], [
      {'name': 'Packaging', 'amount': 1000.0, 'taxRate': 18.0},
    ]);
    // No charges → key absent, so existing preview keys are unchanged.
    expect(CheckoutPricing.previewBody(cartWith(const [])).containsKey('additionalCharges'), isFalse);

    const sale = Sale(additionalCharges: [delivery]);
    expect(sale.toJson()['additionalCharges'], [
      {'name': 'Delivery', 'amount': 2000.0, 'taxRate': 0.0},
    ]);
  });

  test('offline queue keeps charges (local JSON round trip)', () {
    const sale = Sale(clientId: 'c1', additionalCharges: [delivery, packaging], totalAmount: 23180);
    final restored = Sale.fromJson(sale.toLocalJson());
    expect(restored.additionalCharges, sale.additionalCharges);
    expect(restored.chargesTotal, 3180);
  });

  test('server response charges use the server tax and chargesTotal', () {
    final preview = SalePreview.fromJson({
      'subtotal': 20000,
      'discountAmount': 0,
      'taxAmount': 180,
      'totalAmount': 23180,
      'chargesTotal': 3180,
      'additionalCharges': [
        {'name': 'Packaging', 'amount': 1000, 'taxRate': 18, 'taxAmount': 180},
      ],
    });
    expect(preview.chargesTotal, 3180);
    expect(preview.additionalCharges.single.taxAmount, 180);
  });

  test('held sales keep their charges', () {
    final held = HeldSale(id: 'h', label: 'x', lines: const [], heldAt: DateTime(2026), charges: const [packaging]);
    final back = HeldSale.fromJson(held.toJson());
    expect(back.charges, const [packaging]);
    expect(back.total, 1180);
  });

  test('cart refuses empty, non-positive and more than ten charges', () async {
    final bloc = CartBloc();
    bloc.add(const CartChargeAdded(SaleCharge(name: '', amount: 10)));
    bloc.add(const CartChargeAdded(SaleCharge(name: 'Zero', amount: 0)));
    for (var i = 0; i < 12; i++) {
      bloc.add(CartChargeAdded(SaleCharge(name: 'C$i', amount: 100)));
    }
    bloc.add(const CartChargeRemoved(0));
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state.charges, hasLength(SaleCharge.maxPerSale - 1));
    expect(bloc.state.charges.first.name, 'C1');
    await bloc.close();
  });

  testWidgets('Confirm Sale: add a charge from the sheet', (tester) async {
    final bloc = CartBloc();
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      home: BlocProvider.value(
        value: bloc,
        child: Scaffold(
          body: BlocBuilder<CartBloc, CartState>(
            builder: (_, cart) => AdditionalChargesSection(cart: cart),
          ),
        ),
      ),
    ));
    await tester.tap(find.byKey(const ValueKey('add-charge')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delivery'));
    await tester.enterText(find.byKey(const ValueKey('charge-amount')), '2,500');
    await tester.tap(find.byKey(const ValueKey('charge-save')));
    await tester.pumpAndSettle();

    expect(bloc.state.charges.single, const SaleCharge(name: 'Delivery', amount: 2500));
    expect(find.text('TZS 2,500.00'), findsOneWidget);

    await tester.tap(find.byTooltip('Remove charge'));
    await tester.pump();
    expect(bloc.state.charges, isEmpty);
  });
}
