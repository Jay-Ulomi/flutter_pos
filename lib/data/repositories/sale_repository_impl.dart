import 'package:uuid/uuid.dart';

import '../../core/network/network_info.dart';
import '../../domain/repositories/sale_repository.dart';
import '../datasources/local/sale_local.dart';
import '../datasources/remote/sale_remote.dart';
import '../models/sale_models.dart';
import '../models/sync_models.dart';

class SaleRepositoryImpl implements SaleRepository {
  final SaleRemoteDataSource _remote;
  final SaleLocalDataSource _local;
  final NetworkInfo _networkInfo;
  final Uuid _uuid = const Uuid();

  SaleRepositoryImpl(this._remote, this._local, this._networkInfo);

  Sale _ensureClientId(Sale sale) {
    if (sale.clientId != null && sale.clientId!.isNotEmpty) return sale;
    return sale.copyWith(clientId: _uuid.v4());
  }

  @override
  Future<Sale> completeSale(Sale sale) async {
    final saleWithId = _ensureClientId(sale);
    final pendingPayload = saleWithId.createdAt != null
        ? saleWithId
        : saleWithId.copyWith(createdAt: DateTime.now());
    if (_networkInfo.isConnected) {
      try {
        return await _remote.completeSale(saleWithId);
      } catch (_) {
        // Save locally if remote fails
        final pendingSale = PendingSale(
          localId: DateTime.now().millisecondsSinceEpoch.toString(),
          clientId: saleWithId.clientId,
          sale: pendingPayload,
          createdAt: DateTime.now(),
        );
        await _local.savePendingSale(pendingSale);
        rethrow;
      }
    }
    // Offline: save locally
    final pendingSale = PendingSale(
      localId: DateTime.now().millisecondsSinceEpoch.toString(),
      clientId: saleWithId.clientId,
      sale: pendingPayload,
      createdAt: DateTime.now(),
    );
    await _local.savePendingSale(pendingSale);
    return pendingPayload;
  }

  @override
  Future<Sale> getSaleByNumber(String saleNumber) async {
    return _remote.getSaleByNumber(saleNumber);
  }

  @override
  Future<Sale> processReturn({
    required String saleId,
    required List<Map<String, dynamic>> returnItems,
    required String reason,
  }) async {
    return _remote.processReturn(
      saleId: saleId,
      returnItems: returnItems,
      reason: reason,
    );
  }

  @override
  Future<Receipt> getReceipt(String saleId) async {
    return _remote.getReceipt(saleId);
  }

  @override
  Future<List<Sale>> getRecentSales({int page = 0, int size = 50}) async {
    return _remote.getSales(status: 'COMPLETED', page: page, size: size);
  }

  @override
  Future<void> savePendingSale(PendingSale pendingSale) async {
    await _local.savePendingSale(pendingSale);
  }

  @override
  Future<List<PendingSale>> getPendingSales() async {
    return _local.getPendingSales();
  }

  @override
  Future<int> getPendingSaleCount() async {
    return _local.getPendingSaleCount();
  }
}
