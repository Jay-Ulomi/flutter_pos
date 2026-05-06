import '../../data/models/sync_models.dart';

abstract class SyncRepository {
  /// Full bootstrap: fetches all resources and writes to local cache.
  /// Returns the serverTime which will be persisted as last-synced.
  Future<SyncBootstrap> bootstrap({required String branchId});

  /// Incremental delta: fetches records updated since [since], applies upserts/deletes.
  Future<SyncDelta> delta({required String branchId, required DateTime since});

  /// Pushes pending sales to the backend. Marks accepted sales as synced,
  /// flags rejected ones locally with their error.
  Future<SyncPushResult> pushPendingSales();
  Future<LaundrySyncPushResult> pushPendingLaundryActions();

  /// Returns the timestamp of the most recent successful sync (bootstrap or delta).
  Future<DateTime?> getLastSyncedAt();

  /// Persists the most-recent successful-sync timestamp.
  Future<void> setLastSyncedAt(DateTime when);

  Future<int> getPendingSaleCount();
  Future<int> getFailedSaleCount();
  Future<int> getPendingLaundryActionCount();
  Future<int> getFailedLaundryActionCount();
}
