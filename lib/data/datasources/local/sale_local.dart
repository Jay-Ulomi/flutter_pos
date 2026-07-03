import 'dart:convert';
import 'package:drift/drift.dart';
import '../../models/sale_models.dart';
import '../../models/sync_models.dart' as sync_model;
import 'database.dart';

class SaleLocalDataSource {
  final AppDatabase _db;

  SaleLocalDataSource(this._db);

  Future<void> savePendingSale(sync_model.PendingSale pendingSale) async {
    await _db.insertPendingSale(
      PendingSalesCompanion(
        localId: Value(pendingSale.localId),
        clientId: Value(pendingSale.clientId),
        saleJson: Value(jsonEncode(pendingSale.sale.toLocalJson())),
        status: Value(pendingSale.status.name),
        errorMessage: Value(pendingSale.errorMessage),
        retryCount: Value(pendingSale.retryCount),
        createdAt: Value(pendingSale.createdAt),
      ),
    );
  }

  Future<List<sync_model.PendingSale>> getPendingSales() async {
    final results = await _db.getPendingSales();
    return results.map((row) {
      final saleJson = jsonDecode(row.saleJson) as Map<String, dynamic>;
      return sync_model.PendingSale(
        localId: row.localId,
        clientId: row.clientId,
        sale: Sale.fromJson(saleJson),
        createdAt: row.createdAt,
        status: sync_model.SyncItemStatus.values.firstWhere(
          (e) => e.name == row.status,
          orElse: () => sync_model.SyncItemStatus.pending,
        ),
        errorMessage: row.errorMessage,
        retryCount: row.retryCount,
      );
    }).toList();
  }

  Future<int> getPendingSaleCount() async {
    return _db.getPendingSaleCount();
  }

  Future<int> getFailedSaleCount() async {
    return _db.getFailedSaleCount();
  }

  Future<int> getRetriablePendingSaleCount() async {
    return _db.getRetriablePendingSaleCount();
  }

  Future<int> deleteFailedSales() async {
    return _db.deleteFailedSales();
  }

  Future<int> resetSyncingSales() async {
    return _db.resetSyncingSales();
  }

  /// True if any queued sale still references a provisional (`local_…`) session
  /// id and therefore needs reconciling before it can be pushed.
  Future<bool> hasProvisionalSessionSales() async {
    final pending = await getPendingSales();
    return pending.any((p) => (p.sale.sessionId ?? '').startsWith('local_'));
  }

  /// Repoints EVERY queued sale that still references a provisional (`local_…`)
  /// session to the real server session id. Keying on the prefix (not one exact
  /// id) catches stragglers queued from stale UI state after the session was
  /// already reconciled. Returns how many rows were remapped.
  Future<int> remapProvisionalSessions(String realSessionId) async {
    final pending = await getPendingSales();
    var remapped = 0;
    for (final p in pending) {
      if ((p.sale.sessionId ?? '').startsWith('local_')) {
        final updated = p.sale.copyWith(sessionId: realSessionId);
        await _db.updatePendingSaleClientData(
          p.localId,
          p.clientId ?? p.sale.clientId ?? '',
          jsonEncode(updated.toLocalJson()),
        );
        remapped++;
      }
    }
    return remapped;
  }

  Future<void> updateSaleStatus(
    String localId,
    sync_model.SyncItemStatus status,
    String? error,
  ) async {
    await _db.updatePendingSaleStatus(localId, status.name, error);
  }

  Future<void> deletePendingSale(String localId) async {
    await _db.deletePendingSale(localId);
  }

  Future<void> incrementRetryCount(String localId) async {
    await _db.incrementRetryCount(localId);
  }

  Future<void> updatePendingSaleClientData({
    required String localId,
    required String clientId,
    required Sale sale,
  }) async {
    await _db.updatePendingSaleClientData(
      localId,
      clientId,
      jsonEncode(sale.toLocalJson()),
    );
  }
}
