import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/utils/error_message.dart';
import '../../domain/repositories/session_repository.dart';
import '../../domain/repositories/sync_repository.dart';
import '../datasources/local/customer_local.dart';
import '../datasources/local/database.dart';
import '../datasources/local/laundry_local.dart';
import '../datasources/local/product_local.dart';
import '../datasources/local/sale_local.dart';
import '../datasources/remote/sync_remote.dart';
import '../models/sync_models.dart';

class SyncRepositoryImpl implements SyncRepository {
  static const _lastSyncedAtKey = 'last_synced_at';
  static const _uuid = Uuid();

  final SyncRemoteDataSource _remote;
  final AppDatabase _db;
  final ProductLocalDataSource _productLocal;
  final CustomerLocalDataSource _customerLocal;
  final SaleLocalDataSource _saleLocal;
  final LaundryLocalDataSource _laundryLocal;
  final SessionRepository _sessionRepository;

  // Serializes sale pushes so the reconnect trigger, the periodic timer, and a
  // manual push can't send the same queue twice concurrently.
  bool _pushingSales = false;

  SyncRepositoryImpl(
    this._remote,
    this._db,
    this._productLocal,
    this._customerLocal,
    this._saleLocal,
    this._laundryLocal,
    this._sessionRepository,
  );

  @override
  Future<SyncBootstrap> bootstrap({required String branchId}) async {
    final data = await _remote.bootstrap(branchId: branchId);
    if (data.products.isNotEmpty) {
      await _productLocal.cacheProducts(data.products);
    }
    if (data.categories.isNotEmpty) {
      await _productLocal.cacheCategories(data.categories);
    }
    if (data.customers.isNotEmpty) {
      await _customerLocal.cacheCustomers(data.customers, replace: true);
    }
    await setLastSyncedAt(data.serverTime);
    return data;
  }

  @override
  Future<SyncDelta> delta({
    required String branchId,
    required DateTime since,
  }) async {
    final data = await _remote.delta(branchId: branchId, since: since);
    // Upsert products additively
    for (final p in data.products) {
      await _db.upsertProduct(
        CachedProductsCompanion(
          id: Value(p.id),
          name: Value(p.name),
          description: Value(p.description),
          sku: Value(p.sku),
          barcode: Value(p.barcode),
          sellingPrice: Value(p.sellingPrice),
          costPrice: Value(p.costPrice),
          categoryId: Value(p.categoryId),
          categoryName: Value(p.categoryName),
          unit: Value(p.unit),
          stockQuantity: Value(p.stockQuantity),
          minStockLevel: Value(p.minStockLevel),
          trackInventory: Value(p.trackInventory),
          isActive: Value(p.isActive),
          imageUrl: Value(p.imageUrl),
          taxRate: Value(p.taxRate),
          cachedAt: Value(DateTime.now()),
        ),
      );
    }
    for (final c in data.categories) {
      await _db.upsertCategory(
        CachedCategoriesCompanion(
          id: Value(c.id),
          name: Value(c.name),
          description: Value(c.description),
          parentId: Value(c.parentId),
          productCount: Value(c.productCount),
          cachedAt: Value(DateTime.now()),
        ),
      );
    }
    if (data.customers.isNotEmpty) {
      await _customerLocal.cacheCustomers(data.customers);
    }
    for (final id in data.deletedProductIds) {
      await _db.deleteProductById(id);
    }
    for (final id in data.deletedCustomerIds) {
      await _customerLocal.deleteCustomer(id);
    }
    await setLastSyncedAt(data.serverTime);
    return data;
  }

  @override
  Future<int> recoverStuckSales() {
    return _saleLocal.resetSyncingSales();
  }

  @override
  Future<SyncPushResult> pushPendingSales() async {
    // In-flight guard: only one push may run at a time.
    if (_pushingSales) return const SyncPushResult();
    _pushingSales = true;
    try {
      // If the shift was opened offline, turn the provisional session into a
      // real one and repoint queued sales to it BEFORE pushing. If that fails,
      // skip this round rather than push sales with an invalid session id.
      try {
        await _sessionRepository.reconcileProvisionalSession();
      } catch (_) {
        return const SyncPushResult();
      }
      return await _pushPendingSalesInner();
    } finally {
      _pushingSales = false;
    }
  }

  Future<SyncPushResult> _pushPendingSalesInner() async {
    final pending = await _saleLocal.getPendingSales();
    if (pending.isEmpty) {
      return const SyncPushResult();
    }

    // Normalize pending rows to guarantee every payload has a stable clientId.
    // This prevents rows from getting stuck in "syncing" when the server rejects
    // missing/blank ids.
    final payload = <Map<String, dynamic>>[];
    final localIdsByClientId = <String, List<String>>{};
    for (final p in pending) {
      var normalized = p.sale;
      var clientId = (p.clientId ?? '').trim();
      if (clientId.isEmpty) {
        clientId = (normalized.clientId ?? '').trim();
      }
      if (clientId.isEmpty) {
        clientId = _uuid.v4();
      }
      if (normalized.clientId != clientId) {
        normalized = normalized.copyWith(clientId: clientId);
      }

      await _saleLocal.updatePendingSaleClientData(
        localId: p.localId,
        clientId: clientId,
        sale: normalized,
      );

      payload.add(normalized.toJson());
      localIdsByClientId.putIfAbsent(clientId, () => []).add(p.localId);
    }

    // Mark as syncing first.
    for (final p in pending) {
      await _saleLocal.updateSaleStatus(
        p.localId,
        SyncItemStatus.syncing,
        null,
      );
    }

    try {
      final result = await _remote.pushSales(payload);
      final unresolvedLocalIds = pending.map((p) => p.localId).toSet();

      // Accepted -> delete local
      for (final accepted in result.accepted) {
        final ids = localIdsByClientId[accepted.clientId] ?? const <String>[];
        for (final localId in ids) {
          await _saleLocal.deletePendingSale(localId);
          unresolvedLocalIds.remove(localId);
        }
      }
      // Rejected -> mark failed with error
      for (final rejected in result.rejected) {
        final ids = localIdsByClientId[rejected.clientId] ?? const <String>[];
        for (final localId in ids) {
          await _saleLocal.updateSaleStatus(
            localId,
            SyncItemStatus.failed,
            rejected.error,
          );
          await _saleLocal.incrementRetryCount(localId);
          unresolvedLocalIds.remove(localId);
        }
      }

      // Any row not echoed by the server should not remain stuck in syncing.
      for (final localId in unresolvedLocalIds) {
        await _saleLocal.updateSaleStatus(
          localId,
          SyncItemStatus.failed,
          'Sync result missing for queued sale.',
        );
        await _saleLocal.incrementRetryCount(localId);
      }

      // If backend returned an empty result for a non-empty payload, keep the
      // operation visible as a failure in caller/UI.
      if (result.accepted.isEmpty && result.rejected.isEmpty) {
        throw Exception('Sync returned no accepted/rejected items.');
      }

      return result;
    } catch (e) {
      // Whole-batch/transient failure (network, 5xx, malformed response): put
      // rows back to `pending` so they retry — WITHOUT marking them failed or
      // consuming the retry budget. Only genuine per-item server rejections
      // (handled above) count as failures.
      for (final p in pending) {
        await _saleLocal.updateSaleStatus(
          p.localId,
          SyncItemStatus.pending,
          null,
        );
      }
      rethrow;
    }
  }

  @override
  Future<LaundrySyncPushResult> pushPendingLaundryActions() async {
    final pending = await _laundryLocal.getPendingActions();
    if (pending.isEmpty) {
      return const LaundrySyncPushResult();
    }

    final payload = <Map<String, dynamic>>[];
    final localIdsByClientOpId = <String, List<String>>{};
    for (final action in pending) {
      payload.add({
        'clientOpId': action.clientOpId,
        'actionType': laundrySyncActionTypeApi(action.actionType),
        if (action.orderId != null) 'orderId': action.orderId,
        ...action.payload,
      });
      localIdsByClientOpId
          .putIfAbsent(action.clientOpId, () => [])
          .add(action.localId);
    }

    for (final action in pending) {
      await _laundryLocal.updateActionStatus(
        action.localId,
        SyncItemStatus.syncing,
        null,
      );
    }

    try {
      final result = await _remote.pushLaundryActions(payload);
      final unresolvedLocalIds = pending.map((p) => p.localId).toSet();

      for (final accepted in result.accepted) {
        final ids =
            localIdsByClientOpId[accepted.clientOpId] ?? const <String>[];
        for (final localId in ids) {
          await _laundryLocal.deletePendingAction(localId);
          unresolvedLocalIds.remove(localId);
        }
      }

      for (final rejected in result.rejected) {
        final ids =
            localIdsByClientOpId[rejected.clientOpId] ?? const <String>[];
        for (final localId in ids) {
          await _laundryLocal.updateActionStatus(
            localId,
            SyncItemStatus.failed,
            rejected.error,
          );
          await _laundryLocal.incrementRetryCount(localId);
          unresolvedLocalIds.remove(localId);
        }
      }

      for (final localId in unresolvedLocalIds) {
        await _laundryLocal.updateActionStatus(
          localId,
          SyncItemStatus.failed,
          'Sync result missing for queued laundry action.',
        );
        await _laundryLocal.incrementRetryCount(localId);
      }

      if (result.accepted.isEmpty && result.rejected.isEmpty) {
        throw Exception('Laundry sync returned no accepted/rejected items.');
      }

      return result;
    } catch (e) {
      final errorText = humanizeError(e);
      for (final action in pending) {
        await _laundryLocal.updateActionStatus(
          action.localId,
          SyncItemStatus.failed,
          errorText,
        );
        await _laundryLocal.incrementRetryCount(action.localId);
      }
      rethrow;
    }
  }

  @override
  Future<DateTime?> getLastSyncedAt() async {
    final raw = await _db.getMeta(_lastSyncedAtKey);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  @override
  Future<void> setLastSyncedAt(DateTime when) async {
    await _db.setMeta(_lastSyncedAtKey, when.toUtc().toIso8601String());
  }

  @override
  Future<int> getPendingSaleCount() {
    return _saleLocal.getPendingSaleCount();
  }

  @override
  Future<int> getFailedSaleCount() {
    return _db.getFailedSaleCount();
  }

  @override
  Future<int> getRetriablePendingSaleCount() {
    return _saleLocal.getRetriablePendingSaleCount();
  }

  @override
  Future<int> clearFailedSales() {
    return _saleLocal.deleteFailedSales();
  }

  @override
  Future<int> getPendingLaundryActionCount() {
    return _laundryLocal.getPendingActionCount();
  }

  @override
  Future<int> getFailedLaundryActionCount() {
    return _laundryLocal.getFailedActionCount();
  }
}
