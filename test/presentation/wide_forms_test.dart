import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_pos/core/network/network_info.dart';
import 'package:flutter_pos/data/models/sale_models.dart';
import 'package:flutter_pos/data/models/session_models.dart';
import 'package:flutter_pos/domain/repositories/sale_repository.dart';
import 'package:flutter_pos/domain/repositories/session_repository.dart';
import 'package:flutter_pos/presentation/blocs/sale/sale_bloc.dart';
import 'package:flutter_pos/presentation/blocs/session/session_bloc.dart';
import 'package:flutter_pos/presentation/blocs/session/session_state.dart';
import 'package:flutter_pos/presentation/screens/sales/return_screen.dart';
import 'package:flutter_pos/presentation/screens/session/close_session_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_app.dart';

/// Every repository call fails as if offline; the layouts don't need data.
class _Offline {
  dynamic goOffline(Invocation i) => Future<Never>.error(Exception('offline'));
}

class _OfflineSessions extends _Offline implements SessionRepository {
  @override
  dynamic noSuchMethod(Invocation i) => goOffline(i);
}

class _OfflineSales extends _Offline implements SaleRepository {
  @override
  dynamic noSuchMethod(Invocation i) => goOffline(i);
}

class _OfflineNet implements NetworkInfo {
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _OpenSessionBloc extends SessionBloc {
  _OpenSessionBloc() : super(_OfflineSessions(), _OfflineSales()) {
    emit(SessionState(
      status: SessionStatus.open,
      current: CashSession(
        id: 's1',
        userId: 'u1',
        branchId: 'br1',
        openingCash: 50000,
        status: 'OPEN',
        openedAt: DateTime(2026, 10, 19, 8),
      ),
    ));
  }
}

void useSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pumpClose(WidgetTester tester) => pumpRoutes(tester, initial: '/c', routes: [
        GoRoute(
          path: '/c',
          builder: (_, _) => BlocProvider<SessionBloc>(
            create: (_) => _OpenSessionBloc(),
            child: const CloseSessionScreen(),
          ),
        ),
      ]);

  testWidgets('close session: cash count | summary side by side on wide screens', (tester) async {
    useSize(tester, const Size(1400, 1000));
    await pumpClose(tester);
    await tester.pump(const Duration(milliseconds: 100));

    final count = tester.getRect(find.byKey(const ValueKey('close-count')));
    final summary = tester.getRect(find.byKey(const ValueKey('close-summary')));
    expect(summary.left, greaterThan(count.right), reason: 'summary on the right');
    expect((summary.top - count.top).abs(), lessThan(40));
    expect(count.width + summary.width, greaterThan(900), reason: 'uses the full width');
  });

  testWidgets('close session: stacked on phones', (tester) async {
    usePhone(tester);
    await pumpClose(tester);
    await tester.pump(const Duration(milliseconds: 100));
    final count = tester.getRect(find.byKey(const ValueKey('close-count')));
    final summary = tester.getRect(find.byKey(const ValueKey('close-summary')));
    expect(count.top, greaterThan(summary.bottom));
  });

  const sale = Sale(
    id: 'sale1',
    saleNumber: 'S-100',
    items: [
      SaleItem(productId: 'p1', productName: 'Burger', quantity: 2, unitPrice: 7500, totalPrice: 15000),
      SaleItem(productId: 'p2', productName: 'Juice', quantity: 1, unitPrice: 3000, totalPrice: 3000),
    ],
    additionalCharges: [SaleCharge(name: 'Delivery', amount: 2000)],
  );

  Future<void> pumpReturn(WidgetTester tester) => pumpRoutes(tester, initial: '/r', routes: [
        GoRoute(
          path: '/r',
          builder: (_, _) => BlocProvider<SaleBloc>(
            create: (_) => SaleBloc(_OfflineSales(), _OfflineNet()),
            child: const ReturnScreen(sale: sale),
          ),
        ),
      ]);

  testWidgets('returns: items | refund summary on wide screens', (tester) async {
    useSize(tester, const Size(1400, 1000));
    await pumpReturn(tester);
    await tester.pumpAndSettle();

    final items = tester.getRect(find.byKey(const ValueKey('return-items')));
    final summary = tester.getRect(find.byKey(const ValueKey('return-summary')));
    expect(summary.left, greaterThan(items.right));
    expect((summary.top - items.top).abs(), lessThan(1));
    expect(find.byKey(const ValueKey('charges-not-refunded')), findsOneWidget);

    // Stepping an item updates the refund in the summary column.
    await tester.tap(find.byTooltip('Increase').first);
    await tester.pump();
    expect(find.text('TZS 7,500.00'), findsWidgets);
  });

  testWidgets('returns: stacked on phones', (tester) async {
    usePhone(tester);
    await pumpReturn(tester);
    await tester.pumpAndSettle();
    final items = tester.getRect(find.byKey(const ValueKey('return-items')));
    final summary = tester.getRect(find.byKey(const ValueKey('return-summary')));
    expect(summary.top, greaterThan(items.bottom));
  });
}
