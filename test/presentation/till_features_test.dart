import 'package:flutter_pos/data/models/product_models.dart';
import 'package:flutter_pos/data/models/sale_models.dart';
import 'package:flutter_pos/presentation/blocs/cart/cart_bloc.dart';
import 'package:flutter_pos/presentation/blocs/cart/cart_event.dart';
import 'package:flutter_pos/presentation/blocs/cart/cart_state.dart';
import 'package:flutter_pos/presentation/blocs/held_sales/held_sales_cubit.dart';
import 'package:flutter_pos/presentation/widgets/checkout_pricing.dart';
import 'package:flutter_test/flutter_test.dart';

/// Till features backed by the server: tax-exempt products, price tiers,
/// variants, coupons (server preview) and loyalty-point redemption.
void main() {
  const widget = Product(
    id: 'p1',
    name: 'Widget',
    sellingPrice: 1000,
    taxRate: 18,
    tierPrices: {'NORMAL': 1000, 'WHOLESALE': 800},
  );
  const exempt = Product(id: 'p2', name: 'Bread', sellingPrice: 500, taxRate: 18, taxable: false);

  group('tax-exempt products', () {
    test('parse `taxable` from the product JSON (default true)', () {
      expect(Product.fromJson({'id': 'a', 'name': 'A', 'sellingPrice': 1, 'taxable': false}).taxable, isFalse);
      expect(Product.fromJson({'id': 'a', 'name': 'A', 'sellingPrice': 1}).taxable, isTrue);
    });

    test('carry no tax whatever their rate, like the backend', () {
      const line = CartLine(product: exempt, quantity: 2);
      expect(line.lineTax, 0);
      expect(line.lineTotal, 1000);
      const cart = CartState(lines: [line, CartLine(product: widget, quantity: 1)]);
      expect(cart.taxAmount, closeTo(180, 1e-9));
      expect(cart.total, closeTo(2180, 1e-9));
    });
  });

  group('price tiers', () {
    test('a line priced at a tier uses the tier price', () {
      const line = CartLine(product: widget, quantity: 2, priceTier: 'WHOLESALE');
      expect(line.effectivePrice, 800);
      expect(line.lineTax, closeTo(288, 1e-9));
    });

    test('choosing a tier replaces a manual price; choosing NORMAL clears the tier', () async {
      final bloc = CartBloc();
      addTearDown(bloc.close);
      bloc.emit(const CartState(lines: [CartLine(product: widget, quantity: 1, priceOverride: 950)]));

      bloc.add(const CartItemTierChanged('p1', 'WHOLESALE'));
      final tiered = await bloc.stream.first;
      expect(tiered.lines.single.priceTier, 'WHOLESALE');
      expect(tiered.lines.single.priceOverride, isNull);
      expect(tiered.lines.single.effectivePrice, 800);

      bloc.add(const CartItemTierChanged('p1', 'NORMAL'));
      final normal = await bloc.stream.first;
      expect(normal.lines.single.priceTier, isNull);
      expect(normal.lines.single.effectivePrice, 1000);
    });
  });

  group('sale lines', () {
    test('send tier and variant, and survive the offline queue round trip', () {
      const item = SaleItem(
        productId: 'p1',
        productName: 'Widget',
        quantity: 1,
        unitPrice: 800,
        totalPrice: 944,
        serialNumber: 'SN-1',
        lotNumber: 'L-1',
        priceTier: 'WHOLESALE',
        variantId: 'v1',
      );
      final json = item.toJson();
      expect(json['priceTier'], 'WHOLESALE');
      expect(json['variantId'], 'v1');

      final restored = SaleItem.fromJson(json);
      expect(restored.serialNumber, 'SN-1');
      expect(restored.lotNumber, 'L-1');
      expect(restored.priceTier, 'WHOLESALE');
      expect(restored.variantId, 'v1');
    });
  });

  group('held sales', () {
    test('keep tax exemption, tier, manual price and tracking codes when restored', () {
      final held = HeldSale(
        id: 'h1',
        label: 'Table 1',
        heldAt: DateTime(2026, 10, 16),
        lines: const [
          CartLine(product: exempt, quantity: 1, serialNumber: 'SN-9', lotNumber: 'L-9'),
          CartLine(product: widget, quantity: 2, priceTier: 'WHOLESALE'),
          CartLine(product: widget, quantity: 1, priceOverride: 900),
        ],
      );

      final restored = HeldSale.fromJson(held.toJson());

      expect(restored.lines[0].product.taxable, isFalse);
      expect(restored.lines[0].serialNumber, 'SN-9');
      expect(restored.lines[0].lotNumber, 'L-9');
      expect(restored.lines[1].priceTier, 'WHOLESALE');
      expect(restored.lines[1].effectivePrice, 800);
      expect(restored.lines[2].priceOverride, 900);
      expect(restored.total, held.total);
    });
  });

  group('checkout pricing', () {
    test('the preview body mirrors what checkout submits, coupon included', () {
      const variantProduct = Product(id: 'p3', name: 'Shirt · L', sellingPrice: 2000, variantId: 'v-l');
      const cart = CartState(
        discount: 100,
        lines: [
          CartLine(product: widget, quantity: 2, priceTier: 'WHOLESALE'),
          CartLine(product: variantProduct, quantity: 1),
        ],
      );

      final body = CheckoutPricing.previewBody(cart, couponCode: 'SAVE10');
      final items = body['items'] as List;

      expect(body['couponCode'], 'SAVE10');
      expect(body['discountAmount'], 100);
      expect(items[0], containsPair('priceTier', 'WHOLESALE'));
      expect(items[0], containsPair('unitPrice', 800.0));
      expect(items[1], containsPair('variantId', 'v-l'));
      expect(CheckoutPricing.previewBody(cart).containsKey('couponCode'), isFalse);
    });

    test('a changed cart or coupon changes the preview key', () {
      const a = CartState(lines: [CartLine(product: widget, quantity: 1)]);
      const b = CartState(lines: [CartLine(product: widget, quantity: 2)]);
      expect(CheckoutPricing.previewKey(a), isNot(CheckoutPricing.previewKey(b)));
      expect(CheckoutPricing.previewKey(a), isNot(CheckoutPricing.previewKey(a, couponCode: 'X')));
      expect(CheckoutPricing.previewKey(a), CheckoutPricing.previewKey(a));
    });

    test('loyalty redemption uses whole points, capped by balance and amount owed', () {
      // 50 points at 10 each could pay 500, but only 236 is owed: 23 points = 230.
      expect(CheckoutPricing.loyaltyRedeemAmount(points: 50, pointValue: 10, remaining: 236), 230);
      // Balance is the limit when the sale is bigger.
      expect(CheckoutPricing.loyaltyRedeemAmount(points: 50, pointValue: 10, remaining: 5000), 500);
      expect(CheckoutPricing.loyaltyRedeemAmount(points: 0, pointValue: 10, remaining: 500), 0);
      expect(CheckoutPricing.loyaltyRedeemAmount(points: 50, pointValue: 10, remaining: 0), 0);
    });

    test('a server preview knows which coupon it applied', () {
      final preview = SalePreview.fromJson({
        'subtotal': 2000,
        'discountAmount': 200,
        'taxAmount': 324,
        'totalAmount': 2124,
        'loyaltyPointValue': 10,
        'appliedPromotions': [
          {'name': 'Ten percent', 'couponCode': 'SAVE10', 'discountAmount': 200},
        ],
      });
      expect(preview.totalAmount, 2124);
      expect(preview.hasCoupon('save10'), isTrue);
      expect(preview.hasCoupon('OTHER'), isFalse);
      expect(preview.appliedPromotions.single.name, 'Ten percent');
    });
  });
}
