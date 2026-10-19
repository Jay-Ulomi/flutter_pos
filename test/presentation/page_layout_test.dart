import 'dart:io';

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

  testWidgets('PageSections: two section columns on desktop, one on phones', (tester) async {
    Future<List<Rect>> layout(Size size) async {
      useSize(tester, size);
      await pumpRoutes(tester, initial: '/s', routes: [
        GoRoute(
          path: '/s',
          builder: (_, _) => const AppPage(
            title: 'Settings',
            padBody: false,
            body: PageSections(children: [
              PageSectionTitle('User'),
              Card(child: SizedBox(height: 80)),
              SizedBox(height: 16),
              PageSectionTitle('Session'),
              Card(child: SizedBox(height: 80)),
            ]),
          ),
        ),
      ]);
      await tester.pumpAndSettle();
      return [tester.getRect(find.text('USER')), tester.getRect(find.text('SESSION'))];
    }

    final wide = await layout(const Size(1400, 900));
    expect(wide[1].left, greaterThan(wide[0].left + 300), reason: 'side by side');
    expect((wide[1].top - wide[0].top).abs(), lessThan(1));

    final phone = await layout(const Size(390, 844));
    expect(phone[1].top, greaterThan(phone[0].top + 80), reason: 'stacked');
  });

  test('in-shell screens have no centred max-width caps', () {
    // Only pre-till screens (splash, login, forgot password, trial expired,
    // business/branch pickers, open session, lock) and the receipt paper may
    // constrain their width.
    const allowed = {
      'auth/login_screen.dart',
      'auth/forgot_password_screen.dart',
      'auth/trial_expired_screen.dart',
      'session/open_session_screen.dart',
    };
    final offenders = <String>[];
    for (final f in Directory('lib/presentation/screens').listSync(recursive: true).whereType<File>()) {
      final rel = f.path.split('lib/presentation/screens/').last;
      if (allowed.contains(rel)) continue;
      if (RegExp(r'BoxConstraints\(maxWidth:').hasMatch(f.readAsStringSync())) offenders.add(rel);
    }
    final shell = File('lib/presentation/widgets/responsive_shell.dart').readAsStringSync();
    if (shell.contains('BoxConstraints(maxWidth')) offenders.add('responsive_shell.dart');
    expect(offenders, isEmpty);
  });
}
