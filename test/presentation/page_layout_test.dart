import 'package:flutter/material.dart';
import 'package:flutter_pos/data/datasources/remote/feed_remote.dart';
import 'package:flutter_pos/presentation/screens/products/add_product_screen.dart';
import 'package:flutter_pos/presentation/screens/transactions/payment_forms.dart';
import 'package:flutter_pos/presentation/widgets/aduinola/app_page.dart';
import 'package:flutter_pos/presentation/widgets/aduinola/ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_api.dart';
import '../helpers/test_app.dart';

void useSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  late FeedRemoteDataSource remote;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    remote = FeedRemoteDataSource(FakeApi().dio());
  });

  test('gutter is 16 / 24 / 32 for phone / tablet / desktop', () {
    expect(AppBreakpoints.gutter(390), 16);
    expect(AppBreakpoints.gutter(800), 24);
    expect(AppBreakpoints.gutter(1400), 32);
    expect(responsiveColumns(390), 1);
    expect(responsiveColumns(1000), 2);
    expect(responsiveColumns(1400), 3);
  });

  testWidgets('Payment In fills a 1400px surface and lays fields in two columns', (tester) async {
    useSize(tester, const Size(1400, 900));
    await pumpRoutes(tester, initial: '/p', routes: [
      GoRoute(path: '/p', builder: (_, _) => PaymentInScreen(remote: remote)),
    ]);
    await tester.pumpAndSettle();

    final card = tester.getRect(find.byType(PageCard));
    final content = tester.getRect(find.byType(ListView).first);
    // Card spans the content area minus the 32 px desktop gutter on each side.
    expect(card.width, closeTo(content.width - 64, 1));
    expect(card.width, greaterThan(1000));

    // Customer and Invoice sit side by side; Amount starts a new row.
    final customer = tester.getRect(find.byKey(const ValueKey('pick-customer')));
    final invoice = tester.getRect(find.text('Invoice'));
    final amount = tester.getRect(find.byKey(const ValueKey('amount-field')));
    expect(invoice.left, greaterThan(customer.right));
    expect((invoice.top - customer.top).abs(), lessThan(60));
    expect(amount.left, closeTo(customer.left, 1));
    expect(amount.top, greaterThan(customer.bottom));
  });

  testWidgets('Payment In on a phone is one column', (tester) async {
    usePhone(tester);
    await pumpRoutes(tester, initial: '/p', routes: [
      GoRoute(path: '/p', builder: (_, _) => PaymentInScreen(remote: remote)),
    ]);
    await tester.pumpAndSettle();
    final customer = tester.getRect(find.byKey(const ValueKey('pick-customer')));
    final invoice = tester.getRect(find.text('Invoice'));
    expect(invoice.top, greaterThan(customer.bottom));
    expect(tester.getRect(find.byType(PageCard)).width, closeTo(390 - 32, 1));
  });

  testWidgets('Add product form uses the full width on desktop', (tester) async {
    useSize(tester, const Size(1400, 900));
    await pumpRoutes(tester, initial: '/n', routes: [
      GoRoute(path: '/n', builder: (_, _) => AddProductScreen(remote: remote)),
    ]);
    await tester.pumpAndSettle();
    final name = tester.getRect(find.byKey(const ValueKey('product-name')));
    final price = tester.getRect(find.byKey(const ValueKey('product-price')));
    expect(name.width, greaterThan(1000), reason: 'product name spans both columns');
    expect(price.width, lessThan(name.width / 2 + 10));
  });

  testWidgets('AppPage header: round back button and left title', (tester) async {
    usePhone(tester);
    await pumpRoutes(tester, initial: '/', routes: [
      GoRoute(path: '/', builder: (_, _) => const Scaffold(body: Text('home')), routes: [
        GoRoute(
          path: 'child',
          builder: (_, _) => const AppPage(title: 'Child page', body: Text('body')),
        ),
      ]),
    ]);
    GoRouter.of(tester.element(find.text('home'))).push('/child');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('page-back')), findsOneWidget);
    expect(find.byType(RoundIconButton), findsWidgets);
    final body = tester.getTopLeft(find.text('body'));
    expect(body.dx, closeTo(16, 1));

    await tester.tap(find.byKey(const ValueKey('page-back')));
    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);
  });
}
