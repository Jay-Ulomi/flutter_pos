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

  /// Count of queued sales still worth auto-retrying (pending + not-yet-exhausted
  /// failed). Used to gate the background retry loop so it stops once only
  /// permanently-rejected sales remain.
  Future<int> getRetriablePendingSaleCount();

  /// Discards all queued sales stuck in the `failed` state. Returns how many
  /// were removed. Used to clear sales that can never succeed (e.g. rejected by
  /// the server) so they stop blocking the queue.
  Future<int> clearFailedSales();

  Future<int> getPendingLaundryActionCount();
  Future<int> getFailedLaundryActionCount();
}
