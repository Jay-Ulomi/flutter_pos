import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_pos/data/datasources/remote/feed_remote.dart';
import 'package:flutter_pos/data/models/feed_models.dart';
import 'package:flutter_pos/presentation/blocs/feeds/feed_cubits.dart';
import 'package:flutter_pos/presentation/screens/parties/parties_screen.dart';
import 'package:flutter_pos/presentation/screens/products/add_product_screen.dart';
import 'package:flutter_pos/presentation/screens/profile/profile_screen.dart';
import 'package:flutter_pos/presentation/screens/reports/sales_report_screen.dart';
import 'package:flutter_pos/presentation/screens/transactions/payment_forms.dart';
import 'package:flutter_pos/presentation/screens/transactions/transactions_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_api.dart';
import '../helpers/test_app.dart';

Map<String, dynamic> page(List<Map<String, dynamic>> content, {int number = 0, int total = 0, int size = 30}) =>
    {'content': content, 'number': number, 'size': size, 'totalElements': total == 0 ? content.length : total};

Map<String, dynamic> tx(String type, String id, {String status = 'PAID', double amount = 45000, String? party}) => {
      'type': type,
      'id': id,
      'number': id,
      'date': '2026-02-04T13:42:00Z',
      'partyName': party ?? 'Cash Sale',
      'amount': amount,
      'status': status,
      'paymentMethod': 'CASH',
    };

const amina = PartySummary(
    type: PartyType.customer, id: 'c1', name: 'Amina', balance: 50000, direction: BalanceDirection.receivable);
const baraka = PartySummary(
    type: PartyType.customer, id: 'c2', name: 'Baraka', balance: 0, direction: BalanceDirection.settled);
const kilimo = PartySummary(
    type: PartyType.supplier, id: 's1', name: 'Kilimo Ltd', balance: 30000, direction: BalanceDirection.payable);
const owedSupplier = PartySummary(
    type: PartyType.supplier, id: 's2', name: 'Maji Co', balance: 80000, direction: BalanceDirection.payable);

void main() {
  late FakeApi api;
  late FeedRemoteDataSource remote;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    api = FakeApi();
    remote = FeedRemoteDataSource(api.dio());
  });

  group('models', () {
    test('page parsing derives hasMore from totalElements/size', () {
      final r = PageResult.parse(page([tx('SALE', '1')], total: 61, size: 30), TransactionItem.fromJson);
      expect(r.totalPages, 3);
      expect(r.hasMore, isTrue);
    });

    test('parties: balance is positive, direction carries the sign', () {
      final p = PartySummary.fromJson(
          {'type': 'SUPPLIER', 'id': 's', 'name': 'S', 'balance': 1200, 'balanceDirection': 'PAYABLE'});
      expect(p.balance, 1200);
      expect(p.direction, BalanceDirection.payable);
    });

    test('report change vs previous period', () {
      expect(ReportSummary.change(150, 100), 50);
      expect(ReportSummary.change(10, 0), isNull);
    });
  });

  group('transfer limits mirror the server rules', () {
    test('customer→customer and supplier→supplier move the source balance', () {
      expect(transferLimit(amina, baraka), 50000);
      expect(transferLimit(kilimo, owedSupplier), 30000);
    });

    test('customer→supplier is capped by both balances', () {
      expect(transferLimit(amina, kilimo), 30000);
      expect(transferLimit(amina, owedSupplier), 50000);
    });

    test('supplier→customer, same party and settled sources are refused', () {
      expect(transferLimit(kilimo, amina), isNull);
      expect(transferLimit(amina, amina), isNull);
      expect(transferLimit(baraka, amina), isNull);
    });
  });

  group('TransactionsScreen', () {
    testWidgets('lists the feed, filters by status pill and sends date range', (tester) async {
      usePhone(tester);
      api.on('GET', '/api/transactions', (_) => FakeReply(page([
            tx('SALE', '101'),
            tx('SALE', '102', status: 'UNPAID', party: 'Juma'),
            tx('EXPENSE', '7', status: 'PAID', party: 'Rent'),
          ])));
      await pumpRoutes(tester, initial: '/transactions', routes: [
        GoRoute(path: '/transactions', builder: (_, _) => TransactionsScreen(cubit: TransactionsCubit(remote))),
        stubRoute('/payment-in'),
        stubRoute('/pos'),
      ]);
      await tester.pumpAndSettle();

      expect(find.text('Juma'), findsOneWidget);
      expect(find.text('Rent'), findsOneWidget);
      expect(find.text('Unpaid'), findsWidgets);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Unpaid'));
      await tester.pumpAndSettle();
      expect(find.text('Juma'), findsOneWidget);
      expect(find.text('Rent'), findsNothing);

      // Owner sees all types: no `types` filter.
      expect(api.callsTo('/api/transactions').first.query.containsKey('types'), isFalse);

      await tester.tap(find.text('Payment In'));
      await tester.pumpAndSettle();
      expect(find.text('stub:/payment-in'), findsOneWidget);
    });

    testWidgets('cashiers (no view_reports) request only sales, returns and quotations', (tester) async {
      usePhone(tester);
      api.on('GET', '/api/transactions', (_) => FakeReply(page([tx('SALE', '1')])));
      await pumpRoutes(
        tester,
        initial: '/transactions',
        auth: TestAuthBloc.signedIn(permissions: {'create_sale'}),
        routes: [
          GoRoute(path: '/transactions', builder: (_, _) => TransactionsScreen(cubit: TransactionsCubit(remote))),
        ],
      );
      await tester.pumpAndSettle();
      final types = (api.callsTo('/api/transactions').last.query['types'] as String).split(',').toSet();
      expect(types, {'SALE', 'SALE_RETURN', 'QUOTATION'});

      await tester.tap(find.byTooltip('Filter by type'));
      await tester.pumpAndSettle();
      expect(find.text('Purchase'), findsNothing);
      expect(find.text('Quotation'), findsOneWidget);
    });

    testWidgets('the + hub hides accounting flows from cashiers and routes the rest', (tester) async {
      usePhone(tester);
      api.on('GET', '/api/transactions', (_) => FakeReply(page([])));
      await pumpRoutes(
        tester,
        initial: '/transactions',
        auth: TestAuthBloc.signedIn(permissions: {'create_sale'}),
        routes: [
          GoRoute(path: '/transactions', builder: (_, _) => TransactionsScreen(cubit: TransactionsCubit(remote))),
          stubRoute('/pos'),
        ],
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('New transaction'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('hub-tx.payment_in')), findsNothing);
      expect(find.byKey(const ValueKey('hub-tx.party_transfer')), findsNothing);
      expect(find.byKey(const ValueKey('hub-tx.purchase')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('hub-tx.sale')));
      await tester.pumpAndSettle();
      expect(find.text('stub:/pos'), findsOneWidget);
    });
  });

  group('PartiesScreen', () {
    testWidgets('shows to-receive / to-pay and creates a supplier', (tester) async {
      usePhone(tester);
      api
        ..on('GET', '/api/parties', (_) => FakeReply(page([
              {'type': 'CUSTOMER', 'id': 'c1', 'name': 'Amina', 'balance': 50000, 'balanceDirection': 'RECEIVABLE'},
              {'type': 'SUPPLIER', 'id': 's1', 'name': 'Kilimo Ltd', 'balance': 30000, 'balanceDirection': 'PAYABLE'},
            ])))
        ..on('POST', '/api/suppliers', (_) => const FakeReply({'id': 's9'}));
      await pumpRoutes(tester, initial: '/parties', routes: [
        GoRoute(path: '/parties', builder: (_, _) => PartiesScreen(cubit: PartiesCubit(remote))),
      ]);
      await tester.pumpAndSettle();
      expect(find.text('To receive'), findsOneWidget);
      expect(find.text('To pay'), findsOneWidget);
      expect(find.text('TZS 30,000.00'), findsOneWidget);

      await tester.tap(find.text('Suppliers'));
      await tester.pumpAndSettle();
      expect(api.callsTo('/api/parties').last.query['type'], 'SUPPLIER');
    });
  });

  group('forms', () {
    testWidgets('Payment In applies to the oldest open receivable', (tester) async {
      usePhone(tester);
      api
        ..on('GET', '/api/parties', (_) => FakeReply(page([
              {'type': 'CUSTOMER', 'id': 'c1', 'name': 'Amina', 'balance': 50000, 'balanceDirection': 'RECEIVABLE'},
            ])))
        ..on('GET', '/api/accounting/receivables', (_) => FakeReply(page([
              {'id': 'r1', 'amount': 50000, 'balance': 20000, 'status': 'PARTIAL'},
            ])))
        ..on('POST', '/api/accounting/receivables/r1/payments', (_) => const FakeReply({'id': 'r1'}));
      await pumpRoutes(tester, initial: '/', routes: [
        GoRoute(path: '/', builder: (_, _) => const Scaffold(body: Text('home')), routes: [
          GoRoute(path: 'pay', builder: (_, _) => PaymentInScreen(remote: remote)),
        ]),
        stubRoute('/transactions'),
      ]);
      GoRouter.of(tester.element(find.text('home'))).push('/pay');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('pick-customer')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Amina').last);
      await tester.pumpAndSettle();
      expect(api.callsTo('/api/accounting/receivables').single.query['customerId'], 'c1');

      // Over the open balance is refused locally.
      await tester.enterText(find.byKey(const ValueKey('amount-field')), '25000');
      await tester.tap(find.byKey(const ValueKey('form-save')));
      await tester.pumpAndSettle();
      expect(api.callsTo('/api/accounting/receivables/r1/payments'), isEmpty);

      await tester.enterText(find.byKey(const ValueKey('amount-field')), '15000');
      await tester.tap(find.byKey(const ValueKey('form-save')));
      await tester.pumpAndSettle();
      final body = api.callsTo('/api/accounting/receivables/r1/payments').single.body as Map;
      expect(body['amount'], 15000);
      expect(body['paymentMethod'], 'CASH');
      expect(body['paymentDate'], matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
      expect(find.text('home'), findsOneWidget);
    });

    testWidgets('Party transfer shows the contra limit and posts the contract body', (tester) async {
      usePhone(tester);
      api
        ..on('GET', '/api/parties', (c) => FakeReply(page([
              {'type': 'CUSTOMER', 'id': 'c1', 'name': 'Amina', 'balance': 50000, 'balanceDirection': 'RECEIVABLE'},
              {'type': 'SUPPLIER', 'id': 's1', 'name': 'Kilimo Ltd', 'balance': 30000, 'balanceDirection': 'PAYABLE'},
            ])))
        ..on('POST', '/api/parties/transfers', (_) => const FakeReply({'id': 't1'}));
      await pumpRoutes(tester, initial: '/t', routes: [
        GoRoute(path: '/t', builder: (_, _) => PartyTransferScreen(remote: remote)),
        stubRoute('/transactions'),
      ]);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('pick-from')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Amina').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('pick-to')));
      await tester.pumpAndSettle();
      // Amina herself is not offered as a destination.
      expect(find.text('Amina'), findsOneWidget);
      await tester.tap(find.text('Kilimo Ltd').last);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('transfer-limit')), findsOneWidget);
      expect(find.textContaining('Up to TZS 30,000.00'), findsOneWidget);

      await tester.enterText(find.byKey(const ValueKey('amount-field')), '30000');
      await tester.tap(find.byKey(const ValueKey('form-save')));
      await tester.pumpAndSettle();
      final body = api.callsTo('/api/parties/transfers').single.body as Map;
      expect(body['from'], {'type': 'CUSTOMER', 'id': 'c1'});
      expect(body['to'], {'type': 'SUPPLIER', 'id': 's1'});
      expect(body['amount'], 30000);
    });

    testWidgets('Add product is refused without manage_products', (tester) async {
      usePhone(tester);
      await pumpRoutes(
        tester,
        initial: '/new',
        auth: TestAuthBloc.signedIn(permissions: {'create_sale'}),
        routes: [GoRoute(path: '/new', builder: (_, _) => AddProductScreen(remote: remote))],
      );
      expect(find.text('You do not have permission to add products.'), findsOneWidget);
    });

    testWidgets('Add product posts the basic fields', (tester) async {
      usePhone(tester);
      api.on('POST', '/api/products', (_) => const FakeReply({'id': 'p1'}));
      await pumpRoutes(tester, initial: '/', routes: [
        GoRoute(path: '/', builder: (_, _) => const Scaffold(body: Text('home')), routes: [
          GoRoute(path: 'new', builder: (_, _) => AddProductScreen(remote: remote)),
        ]),
      ]);
      GoRouter.of(tester.element(find.text('home'))).push('/new');
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('product-name')), 'Burger');
      await tester.enterText(find.byKey(const ValueKey('product-price')), '7,500');
      await tester.tap(find.byKey(const ValueKey('product-save')));
      await tester.pumpAndSettle();
      final body = api.callsTo('/api/products').single.body as Map;
      expect(body['name'], 'Burger');
      expect(body['sellingPrice'], 7500);
    });
  });

  group('SalesReportScreen', () {
    testWidgets('shows summary cards and saves a PDF export', (tester) async {
      usePhone(tester);
      api
        ..on('GET', '/api/transactions', (_) => FakeReply(page([tx('SALE', '1', party: 'M A Rouf')])))
        ..on('GET', '/api/reports/summary', (_) => const FakeReply({
              'salesCount': 5,
              'salesAmount': 1280,
              'receivedAmount': 1250,
              'unpaidAmount': 550,
              'previous': {'salesCount': 4, 'salesAmount': 1000, 'receivedAmount': 1000, 'unpaidAmount': 600},
            }))
        ..on('GET', '/api/exports/sales-report', (_) => FakeReply(
              [37, 80, 68, 70],
              headers: {
                'content-type': ['application/pdf'],
                'content-disposition': ['attachment; filename="sales-report.pdf"'],
              },
            ));
      final saved = <String>[];
      await pumpRoutes(tester, initial: '/r', routes: [
        GoRoute(
          path: '/r',
          builder: (_, _) => SalesReportScreen(
            remote: remote,
            saver: (f) async {
              saved.add(f.fileName);
              return File('${Directory.systemTemp.path}/${f.fileName}');
            },
          ),
        ),
      ]);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('card-sales-count')), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.textContaining('25%'), findsWidgets);
      expect(find.text('M A Rouf'), findsOneWidget);
      expect(api.callsTo('/api/transactions').last.query['types'], 'SALE');

      await tester.tap(find.text('Download PDF'));
      await tester.pumpAndSettle();
      expect(saved, ['sales-report.pdf']);
      expect(api.callsTo('/api/exports/sales-report').single.query['format'], 'pdf');
    });

    testWidgets('hides summary cards without view_reports', (tester) async {
      usePhone(tester);
      api.on('GET', '/api/transactions', (_) => FakeReply(page([])));
      await pumpRoutes(
        tester,
        initial: '/r',
        auth: TestAuthBloc.signedIn(permissions: {'create_sale'}),
        routes: [GoRoute(path: '/r', builder: (_, _) => SalesReportScreen(remote: remote))],
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('card-sales-count')), findsNothing);
      expect(api.callsTo('/api/reports/summary'), isEmpty);
    });
  });

  testWidgets('bottom nav: five tabs, active pill shows its label and navigates', (tester) async {
    usePhone(tester);
    await pumpRoutes(tester, initial: '/profile', routes: [
      GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
      stubRoute('/parties'),
    ]);
    await tester.pumpAndSettle();
    for (final path in ['/pos', '/transactions', '/parties', '/products', '/profile']) {
      expect(find.byKey(ValueKey('tab-$path')), findsOneWidget);
    }
    // Only the active tab shows a label.
    expect(find.descendant(of: find.byKey(const ValueKey('tab-/profile')), matching: find.text('Profile')),
        findsOneWidget);
    expect(find.descendant(of: find.byKey(const ValueKey('tab-/parties')), matching: find.text('Parties')),
        findsNothing);

    await tester.tap(find.byKey(const ValueKey('tab-/parties')));
    await tester.pumpAndSettle();
    expect(find.text('stub:/parties'), findsOneWidget);
  });
}
