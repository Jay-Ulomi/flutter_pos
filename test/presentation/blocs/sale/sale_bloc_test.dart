import 'package:flutter_pos/core/error/exceptions.dart';
import 'package:flutter_pos/core/network/network_info.dart';
import 'package:flutter_pos/data/models/sale_models.dart';
import 'package:flutter_pos/domain/repositories/sale_repository.dart';
import 'package:flutter_pos/presentation/blocs/sale/sale_bloc.dart';
import 'package:flutter_pos/presentation/blocs/sale/sale_event.dart';
import 'package:flutter_pos/presentation/blocs/sale/sale_state.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeNetwork implements NetworkInfo {
  bool online = true;
  @override
  bool get isConnected => online;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeSaleRepository implements SaleRepository {
  Object? failWith;
  @override
  Future<Sale> completeSale(Sale sale) async {
    if (failWith != null) throw failWith!;
    return sale.copyWith(saleNumber: 'BR-MAIN-000007');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeNetwork network;
  late FakeSaleRepository repo;
  late SaleBloc bloc;
  const sale = Sale(clientId: 'c1', sessionId: 's1', totalAmount: 500);

  setUp(() {
    network = FakeNetwork();
    repo = FakeSaleRepository();
    bloc = SaleBloc(repo, network);
  });
  tearDown(() => bloc.close());

  Future<List<SaleState>> checkout() async {
    final states = <SaleState>[];
    final sub = bloc.stream.listen(states.add);
    bloc.add(const SaleCheckoutRequested(sale));
    await bloc.stream.firstWhere((s) => s.status != SaleStatus.processing);
    await sub.cancel();
    return states;
  }

  test('online success: processing then completed with the server sale', () async {
    final states = await checkout();

    expect(states.map((s) => s.status), [SaleStatus.processing, SaleStatus.completed]);
    expect(states.last.lastSale?.saleNumber, 'BR-MAIN-000007');
  });

  test('offline: the sale is reported as safely queued, not as an error', () async {
    network.online = false;

    final states = await checkout();

    expect(states.last.status, SaleStatus.queuedOffline);
    expect(states.last.errorMessage, isNull);
  });

  test('offline even if the repository throws: still queued (repo saved it locally)', () async {
    network.online = false;
    repo.failWith = NetworkException();

    final states = await checkout();

    expect(states.last.status, SaleStatus.queuedOffline);
    expect(states.last.lastSale?.clientId, 'c1');
  });

  test('online rejection: error with a human-readable message', () async {
    repo.failWith = ServerException(message: 'Insufficient stock. Current: 1, Requested: 2', statusCode: 400);

    final states = await checkout();

    expect(states.last.status, SaleStatus.error);
    expect(states.last.errorMessage, contains('Insufficient stock'));
  });
}
