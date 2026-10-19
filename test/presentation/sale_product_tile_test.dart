import 'package:flutter/material.dart';
import 'package:flutter_pos/core/theme/app_theme.dart';
import 'package:flutter_pos/data/models/product_models.dart';
import 'package:flutter_pos/presentation/widgets/aduinola/sale_product_tile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const fries = Product(id: 'p1', name: 'Fish and Chips', sellingPrice: 12500, stockQuantity: 20);

  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(body: Center(child: SizedBox(width: 180, height: 230, child: child))),
      ));

  testWidgets('not in cart: placeholder initial and a single + button', (tester) async {
    var added = 0;
    await pump(tester, SaleProductTile(product: fries, quantity: 0, onAdd: () => added++));
    expect(find.text('F'), findsOneWidget);
    expect(find.text('TZS 12,500.00'), findsOneWidget);
    expect(find.bySemanticsLabel('Remove one Fish and Chips'), findsNothing);
    await tester.tap(find.bySemanticsLabel('Add Fish and Chips'));
    expect(added, 1);
  });

  testWidgets('in cart: stepper shows the quantity and steps down', (tester) async {
    var removed = 0;
    await pump(
      tester,
      SaleProductTile(product: fries, quantity: 2, onAdd: () {}, onRemove: () => removed++),
    );
    expect(find.byKey(const ValueKey('qty-p1')), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Remove one Fish and Chips'));
    expect(removed, 1);
  });

  testWidgets('out of stock cannot be added', (tester) async {
    var added = 0;
    await pump(
      tester,
      SaleProductTile(
        product: const Product(id: 'p2', name: 'Salmon', sellingPrice: 7500, stockQuantity: 0),
        quantity: 0,
        onAdd: () => added++,
      ),
    );
    expect(find.text('Out of stock'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('product-p2')));
    expect(added, 0);
  });
}
