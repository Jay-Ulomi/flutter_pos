import 'package:equatable/equatable.dart';

abstract class SyncEvent extends Equatable {
  const SyncEvent();
  @override
  List<Object?> get props => [];
}

class SyncStatusRequested extends SyncEvent {
  const SyncStatusRequested();
}

/// Legacy "Sync Now" — now routed through push + delta.
class SyncTriggered extends SyncEvent {
  const SyncTriggered();
}

class SyncBootstrapRequested extends SyncEvent {
  final String branchId;
  const SyncBootstrapRequested(this.branchId);
  @override
  List<Object?> get props => [branchId];
}

class SyncDeltaRequested extends SyncEvent {
  final String branchId;
  const SyncDeltaRequested(this.branchId);
  @override
  List<Object?> get props => [branchId];
}

class SyncPushRequested extends SyncEvent {
  const SyncPushRequested();
}

class SyncConnectivityChanged extends SyncEvent {
  final bool isOnline;
  const SyncConnectivityChanged(this.isOnline);
  @override
  List<Object?> get props => [isOnline];
}

/// Quiet background push — fired by the periodic retry timer and on app resume.
/// Unlike [SyncPushRequested] it does not flip the loud syncing/success phase,
/// so it won't flicker the UI while the user is idle. Swallows errors and just
/// refreshes the status snapshot.
class SyncAutoRetryRequested extends SyncEvent {
  const SyncAutoRetryRequested();
}

/// Discards all queued sales stuck in the `failed` state (e.g. permanently
/// rejected by the server) so they stop blocking the queue.
class SyncFailedSalesCleared extends SyncEvent {
  const SyncFailedSalesCleared();
}

/// Quiet, periodic delta pull to refresh products/prices/stock while online.
/// Does not flip the loud syncing phase.
class SyncBackgroundDeltaRequested extends SyncEvent {
  const SyncBackgroundDeltaRequested();
}
