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
