import 'package:flutter_pos/data/datasources/local/customer_local.dart';
import 'package:flutter_pos/data/datasources/local/database.dart' show AppDatabase;
import 'package:flutter_pos/data/datasources/local/laundry_local.dart';
import 'package:flutter_pos/data/datasources/local/product_local.dart';
import 'package:flutter_pos/data/datasources/local/sale_local.dart';
import 'package:flutter_pos/data/datasources/remote/sync_remote.dart';
import 'package:flutter_pos/data/models/sale_models.dart';
import 'package:flutter_pos/data/models/sync_models.dart';
import 'package:flutter_pos/data/repositories/sync_repository_impl.dart';
import 'package:flutter_pos/domain/repositories/session_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_database.dart';

/// What the server does with a pushed batch.
typedef ServerBehaviour = SyncPushResult Function(List<Map<String, dynamic>> sales);

class FakeSyncRemote implements SyncRemoteDataSource {
  FakeSyncRemote(this.behaviour);
  ServerBehaviour behaviour;
  Object? failWith;
  final batches = <List<Map<String, dynamic>>>[];

  @override
  Future<SyncPushResult> pushSales(List<Map<String, dynamic>> sales) async {
    batches.add(sales);
    if (failWith != null) throw failWith!;
    return behaviour(sales);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeSessionRepository implements SessionRepository {
  Object? failWith;
  int reconciled = 0;
  @override
  Future<void> reconcileProvisionalSession() async {
    reconciled++;
    if (failWith != null) throw failWith!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

SyncPushResult acceptAll(List<Map<String, dynamic>> sales) => SyncPushResult(
      accepted: [for (final s in sales) AcceptedSale(clientId: s['clientId'] as String, serverId: 'srv-${s['clientId']}')],
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late SaleLocalDataSource saleLocal;
  late FakeSyncRemote remote;
  late FakeSessionRepository sessions;
  late SyncRepositoryImpl repo;

  setUp(() async {
    db = await openTestDatabase();
    saleLocal = SaleLocalDataSource(db);
    remote = FakeSyncRemote(acceptAll);
    sessions = FakeSessionRepository();
    repo = SyncRepositoryImpl(remote, db, ProductLocalDataSource(db), CustomerLocalDataSource(db), saleLocal,
        LaundryLocalDataSource(db), sessions);
  });
  tearDown(() => db.close());

  Future<void> queue(String localId, {String? clientId}) => saleLocal.savePendingSale(PendingSale(
        localId: localId,
        clientId: clientId,
        createdAt: DateTime.now(),
        sale: Sale(clientId: clientId, sessionId: 's1', totalAmount: 500, items: const [
          SaleItem(productId: 'p1', productName: 'Widget', quantity: 1, unitPrice: 500, totalPrice: 500),
        ]),
      ));

  test('accepted sales are pushed once and removed from the queue', () async {
    await queue('L1', clientId: 'c-1');
    await queue('L2', clientId: 'c-2');

    final result = await repo.pushPendingSales();

    expect(result.accepted.map((a) => a.clientId), containsAll(['c-1', 'c-2']));
    expect(remote.batches.single.map((s) => s['clientId']), containsAll(['c-1', 'c-2']));
    expect(await saleLocal.getPendingSales(), isEmpty);
    expect(sessions.reconciled, 1, reason: 'offline sessions are reconciled before pushing');
  });

  test('a queued sale without a clientId gets one, and keeps it across retries', () async {
    await queue('L1');
    remote.failWith = Exception('timeout');

    await expectLater(repo.pushPendingSales(), throwsException);
    final firstId = remote.batches.single.single['clientId'] as String;
    expect(firstId, isNotEmpty);

    remote.failWith = null;
    await repo.pushPendingSales();

    expect(remote.batches[1].single['clientId'], firstId, reason: 'same id, so the server can de-duplicate');
    expect(await saleLocal.getPendingSales(), isEmpty);
  });

  test('a whole-batch failure puts every sale back to pending without spending retries', () async {
    await queue('L1', clientId: 'c-1');
    remote.failWith = Exception('502 Bad Gateway');

    await expectLater(repo.pushPendingSales(), throwsException);

    final p = (await saleLocal.getPendingSales()).single;
    expect(p.status, SyncItemStatus.pending);
    expect(p.retryCount, 0);
  });

  test('a sale the server rejects is marked failed with the reason and a retry count', () async {
    await queue('L1', clientId: 'good');
    await queue('L2', clientId: 'bad');
    remote.behaviour = (sales) => const SyncPushResult(
          accepted: [AcceptedSale(clientId: 'good', serverId: 'srv-1')],
          rejected: [RejectedSale(clientId: 'bad', error: 'Insufficient stock')],
        );

    await repo.pushPendingSales();

    final left = await saleLocal.getPendingSales();
    expect(left.single.localId, 'L2');
    expect(left.single.status, SyncItemStatus.failed);
    expect(left.single.errorMessage, 'Insufficient stock');
    expect(left.single.retryCount, 1);
  });

  test('a sale the server does not mention is not left stuck in syncing', () async {
    await queue('L1', clientId: 'c-1');
    await queue('L2', clientId: 'c-2');
    remote.behaviour = (sales) => const SyncPushResult(accepted: [AcceptedSale(clientId: 'c-1', serverId: 'srv-1')]);

    await repo.pushPendingSales();

    final left = (await saleLocal.getPendingSales()).single;
    expect(left.localId, 'L2');
    expect(left.status, SyncItemStatus.failed);
  });

  test('if the offline session cannot be reconciled, nothing is pushed this round', () async {
    await queue('L1', clientId: 'c-1');
    sessions.failWith = Exception('offline');

    final result = await repo.pushPendingSales();

    expect(result.accepted, isEmpty);
    expect(remote.batches, isEmpty);
    expect((await saleLocal.getPendingSales()).single.status, SyncItemStatus.pending);
  });

  test('two overlapping pushes send the queue only once', () async {
    await queue('L1', clientId: 'c-1');

    await Future.wait([repo.pushPendingSales(), repo.pushPendingSales()]);

    expect(remote.batches, hasLength(1));
  });
}
