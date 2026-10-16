import 'package:flutter_pos/data/models/product_models.dart';
import 'package:flutter_pos/presentation/blocs/cart/cart_bloc.dart';
import 'package:flutter_pos/presentation/blocs/cart/cart_event.dart';
import 'package:flutter_pos/presentation/blocs/cart/cart_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const widget = Product(id: 'p1', name: 'Widget', sellingPrice: 1000, taxRate: 18);
  const soap = Product(id: 'p2', name: 'Soap', sellingPrice: 150);

  late CartBloc bloc;

  setUp(() => bloc = CartBloc());
  tearDown(() => bloc.close());

  /// Dispatch events and wait until the bloc has processed them.
  Future<CartState> run(List<CartEvent> events) async {
    for (final e in events) {
      bloc.add(e);
    }
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    return bloc.state;
  }

  test('re-scanning a product bumps its quantity and moves it to the top', () async {
    final state = await run(const [
      CartItemAdded(widget),
      CartItemAdded(soap),
      CartItemAdded(widget, quantity: 2),
    ]);

    expect(state.lines.map((l) => l.product.id), ['p1', 'p2']);
    expect(state.lines.first.quantity, 3);
  });

  test('serial-tracked items are always separate lines', () async {
    final state = await run(const [
      CartItemAdded(widget, serialNumber: 'SN-1'),
      CartItemAdded(widget, serialNumber: 'SN-2'),
    ]);

    expect(state.lines, hasLength(2));
    expect(state.lines.map((l) => l.serialNumber), containsAll(['SN-1', 'SN-2']));
  });

  test('setting a quantity of zero removes the line', () async {
    final state = await run(const [
      CartItemAdded(widget),
      CartItemAdded(soap),
      CartItemQtyChanged('p1', 0),
    ]);

    expect(state.lines.map((l) => l.product.id), ['p2']);
  });

  test('line discount, price override and sale discount feed the total', () async {
    final state = await run(const [
      CartItemAdded(widget, quantity: 2),
      CartItemDiscountApplied('p1', discount: 10, isPercent: true),
      CartDiscountApplied(100),
    ]);

    expect(state.lines.single.lineDiscount, 200);
    expect(state.total, closeTo(2024, 1e-9)); // 2000 - 200 + 324 - 100

    final overridden = await run(const [CartItemPriceChanged('p1', 500)]);
    expect(overridden.lines.single.effectivePrice, 500);
  });

  test('clearing a line discount resets it to none', () async {
    final state = await run(const [
      CartItemAdded(widget),
      CartItemDiscountApplied('p1', discount: 50, isPercent: false),
      CartItemDiscountApplied('p1', discount: 0, isPercent: false),
    ]);

    expect(state.lines.single.hasDiscount, isFalse);
    expect(state.lines.single.isPercentDiscount, isFalse);
  });

  test('custom items get unique ids so they never merge', () async {
    final state = await run(const [
      CartCustomItemAdded(name: 'Service', price: 500),
      CartCustomItemAdded(name: 'Service', price: 500),
    ]);

    expect(state.lines, hasLength(2));
    expect(state.lines[0].product.id, isNot(state.lines[1].product.id));
  });

  test('customer selection, clearing and full cart clear', () async {
    final withCustomer = await run(const [
      CartItemAdded(widget),
      CartCustomerSelected(customerId: 'c1', customerName: 'Amina', customerBalance: 5000),
    ]);
    expect(withCustomer.selectedCustomerId, 'c1');
    expect(withCustomer.customerBalance, 5000);

    final noCustomer = await run(const [CartCustomerCleared()]);
    expect(noCustomer.hasCustomer, isFalse);
    expect(noCustomer.customerBalance, 0);
    expect(noCustomer.lines, hasLength(1));

    final cleared = await run(const [CartCleared()]);
    expect(cleared, const CartState());
  });

  test('restoring a held sale brings back its lines, discount and customer', () async {
    final state = await run([
      const CartRestored(
        lines: [CartLine(product: soap, quantity: 4)],
        discount: 50,
        customerId: 'c9',
        customerName: 'Juma',
      ),
    ]);

    expect(state.lines.single.quantity, 4);
    expect(state.discount, 50);
    expect(state.selectedCustomerName, 'Juma');
  });
}
