import 'package:flutter_pos/data/models/product_models.dart';
import 'package:flutter_pos/presentation/blocs/cart/cart_state.dart';
import 'package:flutter_test/flutter_test.dart';

/// Cart money math must match the backend (SaleService): tax is charged on the
/// line total after its own discount, and a sale-level discount is taken off the
/// total without reducing tax. Reference sale: 2 x 1000 at 18% = 2000 + 360 = 2360.
void main() {
  const widget = Product(id: 'p1', name: 'Widget', sellingPrice: 1000, taxRate: 18);
  const untaxed = Product(id: 'p2', name: 'Soap', sellingPrice: 150);

  group('CartLine', () {
    test('taxes the line on top of its price', () {
      const line = CartLine(product: widget, quantity: 2);

      expect(line.lineSubtotal, 2000);
      expect(line.lineDiscount, 0);
      expect(line.lineTax, closeTo(360, 1e-9));
      expect(line.lineTotal, closeTo(2360, 1e-9));
    });

    test('a fixed discount is taken off the whole line before tax', () {
      const line = CartLine(product: widget, quantity: 2, discount: 200);

      expect(line.lineDiscount, 200);
      expect(line.lineTax, closeTo(324, 1e-9)); // 18% of 1800
      expect(line.lineTotal, closeTo(2124, 1e-9));
    });

    test('a percent discount applies to the line subtotal', () {
      const line = CartLine(product: widget, quantity: 2, discount: 10, isPercentDiscount: true);

      expect(line.lineDiscount, 200);
      expect(line.lineTotal, closeTo(2124, 1e-9));
    });

    test('a discount can never exceed the line value', () {
      const line = CartLine(product: widget, quantity: 1, discount: 5000);

      expect(line.lineDiscount, 1000);
      expect(line.lineTax, 0);
      expect(line.lineTotal, 0);
    });

    test('discounts are rounded to cents so the backend gets no float drift', () {
      const odd = Product(id: 'p3', name: 'Odd', sellingPrice: 33.33);
      const line = CartLine(product: odd, quantity: 1, discount: 33.333, isPercentDiscount: true);

      expect(line.lineDiscount, 11.11);
    });

    test('a price override replaces the selling price', () {
      const line = CartLine(product: widget, quantity: 1, priceOverride: 800);

      expect(line.effectivePrice, 800);
      expect(line.lineTotal, closeTo(944, 1e-9));
      expect(line.hasPriceOverride, isTrue);
    });

    test('products without a tax rate are not taxed', () {
      const line = CartLine(product: untaxed, quantity: 3);

      expect(line.lineTax, 0);
      expect(line.lineTotal, 450);
    });

    test('flags lines that exceed the known stock of tracked products only', () {
      const tracked = Product(id: 't', name: 'T', sellingPrice: 1, stockQuantity: 2);
      const untracked = Product(id: 'u', name: 'U', sellingPrice: 1, stockQuantity: 2, trackInventory: false);
      const unknownStock = Product(id: 'k', name: 'K', sellingPrice: 1);

      expect(const CartLine(product: tracked, quantity: 3).exceedsStock, isTrue);
      expect(const CartLine(product: tracked, quantity: 2).exceedsStock, isFalse);
      expect(const CartLine(product: untracked, quantity: 3).exceedsStock, isFalse);
      expect(const CartLine(product: unknownStock, quantity: 99).exceedsStock, isFalse);
    });
  });

  group('CartState', () {
    test('totals match the backend reference sale', () {
      const cart = CartState(lines: [CartLine(product: widget, quantity: 2)]);

      expect(cart.subtotal, 2000);
      expect(cart.taxAmount, closeTo(360, 1e-9));
      expect(cart.total, closeTo(2360, 1e-9));
    });

    test('a sale-level discount reduces the total but not the tax', () {
      const cart = CartState(lines: [CartLine(product: widget, quantity: 2)], discount: 200);

      expect(cart.taxAmount, closeTo(360, 1e-9));
      expect(cart.total, closeTo(2160, 1e-9));
    });

    test('line discounts and a sale discount both come off the total', () {
      const cart = CartState(
        lines: [
          CartLine(product: widget, quantity: 2, discount: 200),
          CartLine(product: untaxed, quantity: 2),
        ],
        discount: 100,
      );

      expect(cart.subtotal, 2300);
      expect(cart.lineDiscountTotal, 200);
      expect(cart.taxAmount, closeTo(324, 1e-9));
      // 2300 - 200 + 324 - 100
      expect(cart.total, closeTo(2324, 1e-9));
    });

    test('the total never goes below zero', () {
      const cart = CartState(lines: [CartLine(product: untaxed, quantity: 1)], discount: 1000);

      expect(cart.total, 0);
    });

    test('item count, emptiness and customer flags', () {
      const empty = CartState();
      const cart = CartState(
        lines: [CartLine(product: widget, quantity: 2), CartLine(product: untaxed, quantity: 1)],
        selectedCustomerId: 'c1',
      );

      expect(empty.isEmpty, isTrue);
      expect(empty.hasCustomer, isFalse);
      expect(cart.itemCount, 3);
      expect(cart.hasCustomer, isTrue);
    });
  });
}
