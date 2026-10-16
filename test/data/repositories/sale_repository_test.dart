import 'package:flutter_pos/core/error/exceptions.dart';
import 'package:flutter_pos/core/network/network_info.dart';
import 'package:flutter_pos/data/datasources/local/sale_local.dart';
import 'package:flutter_pos/data/datasources/remote/sale_remote.dart';
import 'package:flutter_pos/data/models/sale_models.dart';
import 'package:flutter_pos/data/models/sync_models.dart';
import 'package:flutter_pos/data/repositories/sale_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeNetwork implements NetworkInfo {
  bool online = true;
  @override
  bool get isConnected => online;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeRemote implements SaleRemoteDataSource {
  Object? failWith;
  final sent = <Sale>[];
  @override
  Future<Sale> completeSale(Sale sale) async {
    sent.add(sale);
    if (failWith != null) throw failWith!;
    return sale.copyWith(saleNumber: 'BR-MAIN-000001');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeLocal implements SaleLocalDataSource {
  final queued = <PendingSale>[];
  @override
  Future<void> savePendingSale(PendingSale pendingSale) async => queued.add(pendingSale);
  @override
  Future<List<PendingSale>> getPendingSales() async => queued;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeNetwork network;
  late FakeRemote remote;
  late FakeLocal local;
  late SaleRepositoryImpl repo;

  const sale = Sale(sessionId: 's1', totalAmount: 1180, items: [
    SaleItem(productId: 'p1', productName: 'Widget', quantity: 1, unitPrice: 1000, totalPrice: 1180),
  ]);

  setUp(() {
    network = FakeNetwork();
    remote = FakeRemote();
    local = FakeLocal();
    repo = SaleRepositoryImpl(remote, local, network);
  });

  test('online: sends the sale with a generated clientId and queues nothing', () async {
    final result = await repo.completeSale(sale);

    expect(result.saleNumber, 'BR-MAIN-000001');
    expect(remote.sent.single.clientId, isNotEmpty);
    expect(local.queued, isEmpty);
  });

  test('keeps the clientId the checkout already chose (idempotent retries)', () async {
    await repo.completeSale(sale.copyWith(clientId: 'checkout-42'));
    await repo.completeSale(sale.copyWith(clientId: 'checkout-42'));

    expect(remote.sent.map((s) => s.clientId), ['checkout-42', 'checkout-42']);
  });

  test('offline: queues the sale locally with its clientId and a timestamp', () async {
    network.online = false;

    final result = await repo.completeSale(sale.copyWith(clientId: 'offline-1'));

    expect(remote.sent, isEmpty);
    expect(local.queued.single.clientId, 'offline-1');
    expect(local.queued.single.sale.createdAt, isNotNull);
    expect(result.clientId, 'offline-1');
  });

  test('a network failure while online is queued with the same clientId, then reported', () async {
    remote.failWith = NetworkException();

    await expectLater(repo.completeSale(sale.copyWith(clientId: 'c-net')), throwsA(isA<NetworkException>()));

    expect(local.queued.single.clientId, 'c-net');
  });

  test('a server 5xx is treated as transient and queued', () async {
    remote.failWith = ServerException(message: 'Bad gateway', statusCode: 502);

    await expectLater(repo.completeSale(sale), throwsA(isA<ServerException>()));

    expect(local.queued, hasLength(1));
    expect(local.queued.single.clientId, remote.sent.single.clientId);
  });

  test('a 4xx business rejection is NOT queued (it would fail forever on sync)', () async {
    remote.failWith = ServerException(message: 'Insufficient stock', statusCode: 400);

    await expectLater(repo.completeSale(sale), throwsA(isA<ServerException>()));

    expect(local.queued, isEmpty);
  });
}
