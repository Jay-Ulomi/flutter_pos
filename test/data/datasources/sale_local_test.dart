import 'package:flutter_pos/data/datasources/local/database.dart' show AppDatabase;
import 'package:flutter_pos/data/datasources/local/sale_local.dart';
import 'package:flutter_pos/data/models/sale_models.dart';
import 'package:flutter_pos/data/models/sync_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_database.dart';

/// The offline sale queue on the real drift schema.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late SaleLocalDataSource local;

  setUp(() async {
    db = await openTestDatabase();
    local = SaleLocalDataSource(db);
  });
  tearDown(() => db.close());

  PendingSale pending(String localId, {String? clientId, String sessionId = 's1', int minutesAgo = 0}) {
    final at = DateTime(2026, 10, 16, 12).subtract(Duration(minutes: minutesAgo));
    return PendingSale(
      localId: localId,
      clientId: clientId,
      createdAt: at,
      sale: Sale(
        clientId: clientId,
        sessionId: sessionId,
        totalAmount: 1180,
        items: const [
          SaleItem(productId: 'p1', productName: 'Widget', quantity: 1, unitPrice: 1000, taxAmount: 180, totalPrice: 1180),
        ],
        payments: const [SalePayment(method: 'CASH', amount: 1180)],
        createdAt: at,
      ),
    );
  }

  test('a queued sale survives the round trip with its clientId, items and payments', () async {
    await local.savePendingSale(pending('L1', clientId: 'c-1'));

    final queued = await local.getPendingSales();

    expect(queued, hasLength(1));
    final p = queued.single;
    expect(p.localId, 'L1');
    expect(p.clientId, 'c-1');
    expect(p.status, SyncItemStatus.pending);
    expect(p.sale.clientId, 'c-1');
    expect(p.sale.items.single.productId, 'p1');
    expect(p.sale.payments.single.amount, 1180);
    expect(await local.getPendingSaleCount(), 1);
  });

  test('sales are returned oldest first, so they sync in the order they were made', () async {
    await local.savePendingSale(pending('newer', clientId: 'b', minutesAgo: 1));
    await local.savePendingSale(pending('older', clientId: 'a', minutesAgo: 5));

    final queued = await local.getPendingSales();

    expect(queued.map((p) => p.localId), ['older', 'newer']);
  });

  test('status changes, errors and retry counts are persisted; syncing rows are hidden', () async {
    await local.savePendingSale(pending('L1', clientId: 'c-1'));

    await local.updateSaleStatus('L1', SyncItemStatus.failed, 'Insufficient stock');
    await local.incrementRetryCount('L1');
    var p = (await local.getPendingSales()).single;
    expect(p.status, SyncItemStatus.failed);
    expect(p.errorMessage, 'Insufficient stock');
    expect(p.retryCount, 1);

    await local.updateSaleStatus('L1', SyncItemStatus.syncing, null);
    expect(await local.getPendingSales(), isEmpty, reason: 'a row mid-push is not picked up twice');
  });

  test('rows stuck in syncing (app killed mid-push) are recovered to pending', () async {
    await local.savePendingSale(pending('L1', clientId: 'c-1'));
    await local.updateSaleStatus('L1', SyncItemStatus.syncing, null);

    final recovered = await local.resetSyncingSales();

    expect(recovered, 1);
    expect((await local.getPendingSales()).single.status, SyncItemStatus.pending);
  });

  test('sales queued against an offline (local_) session are repointed to the real one', () async {
    await local.savePendingSale(pending('L1', clientId: 'c-1', sessionId: 'local_123'));
    await local.savePendingSale(pending('L2', clientId: 'c-2', sessionId: 'server-s9'));
    expect(await local.hasProvisionalSessionSales(), isTrue);

    final remapped = await local.remapProvisionalSessions('server-s10');

    expect(remapped, 1);
    final bySession = {for (final p in await local.getPendingSales()) p.localId: p.sale.sessionId};
    expect(bySession, {'L1': 'server-s10', 'L2': 'server-s9'});
    expect(await local.hasProvisionalSessionSales(), isFalse);
  });

  test('deleting a synced sale removes it from the queue', () async {
    await local.savePendingSale(pending('L1', clientId: 'c-1'));

    await local.deletePendingSale('L1');

    expect(await local.getPendingSales(), isEmpty);
    expect(await local.getPendingSaleCount(), 0);
  });
}
