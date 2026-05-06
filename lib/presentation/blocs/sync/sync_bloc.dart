import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/network_info.dart';
import '../../../core/utils/token_manager.dart';
import '../../../domain/repositories/sync_repository.dart';
import 'sync_event.dart';
import 'sync_state.dart';

class SyncBloc extends Bloc<SyncEvent, SyncBlocState> {
  final SyncRepository _syncRepository;
  final NetworkInfo _networkInfo;
  final TokenManager _tokenManager;
  StreamSubscription<bool>? _connectivitySub;

  SyncBloc(this._syncRepository, this._networkInfo, this._tokenManager)
    : super(const SyncBlocState()) {
    on<SyncStatusRequested>(_onStatusRequested);
    on<SyncTriggered>(_onTriggered);
    on<SyncBootstrapRequested>(_onBootstrap);
    on<SyncDeltaRequested>(_onDelta);
    on<SyncPushRequested>(_onPush);
    on<SyncConnectivityChanged>(_onConnectivityChanged);

    _connectivitySub = _networkInfo.onConnectivityChanged.listen((isOnline) {
      add(SyncConnectivityChanged(isOnline));
    });
  }

  Future<String?> _currentBranchId() => _tokenManager.getBranchId();

  Future<void> _refreshStatusSnapshot(Emitter<SyncBlocState> emit) async {
    final pendingSales = await _syncRepository.getPendingSaleCount();
    final failedSales = await _syncRepository.getFailedSaleCount();
    final pendingLaundry = await _syncRepository.getPendingLaundryActionCount();
    final failedLaundry = await _syncRepository.getFailedLaundryActionCount();
    final last = await _syncRepository.getLastSyncedAt();
    emit(
      state.copyWith(
        status: state.status.copyWith(
          pendingCount: pendingSales + pendingLaundry,
          failedCount: failedSales + failedLaundry,
          pendingSalesCount: pendingSales,
          failedSalesCount: failedSales,
          pendingLaundryCount: pendingLaundry,
          failedLaundryCount: failedLaundry,
          isOnline: _networkInfo.isConnected,
          lastSyncTime: last,
        ),
      ),
    );
  }

  Future<void> _onStatusRequested(
    SyncStatusRequested event,
    Emitter<SyncBlocState> emit,
  ) async {
    emit(state.copyWith(phase: SyncPhase.loading, clearError: true));
    try {
      await _refreshStatusSnapshot(emit);
      emit(state.copyWith(phase: SyncPhase.idle));
    } catch (e) {
      emit(
        state.copyWith(phase: SyncPhase.error, errorMessage: _humanizeError(e)),
      );
    }
  }

  /// Legacy "Sync Now" — performs push + delta.
  Future<void> _onTriggered(
    SyncTriggered event,
    Emitter<SyncBlocState> emit,
  ) async {
    if (!_networkInfo.isConnected) {
      emit(
        state.copyWith(
          phase: SyncPhase.error,
          errorMessage: 'No internet connection',
        ),
      );
      return;
    }
    emit(state.copyWith(phase: SyncPhase.syncing, clearError: true));
    try {
      final salesPush = await _syncRepository.pushPendingSales();
      final laundryPush = await _syncRepository.pushPendingLaundryActions();
      final branchId = await _currentBranchId();
      if (branchId != null) {
        final last = await _syncRepository.getLastSyncedAt();
        if (last != null) {
          await _syncRepository.delta(branchId: branchId, since: last);
        } else {
          await _syncRepository.bootstrap(branchId: branchId);
        }
      }
      await _refreshStatusSnapshot(emit);
      emit(
        state.copyWith(
          phase: SyncPhase.success,
          status: state.status.copyWith(
            lastAcceptedCount:
                salesPush.accepted.length + laundryPush.accepted.length,
            lastRejectedCount:
                salesPush.rejected.length + laundryPush.rejected.length,
            lastSyncTime: DateTime.now(),
          ),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(phase: SyncPhase.error, errorMessage: _humanizeError(e)),
      );
    }
  }

  Future<void> _onBootstrap(
    SyncBootstrapRequested event,
    Emitter<SyncBlocState> emit,
  ) async {
    if (!_networkInfo.isConnected) {
      emit(
        state.copyWith(
          phase: SyncPhase.error,
          errorMessage: 'No internet connection',
        ),
      );
      return;
    }
    emit(state.copyWith(phase: SyncPhase.syncing, clearError: true));
    try {
      await _syncRepository.bootstrap(branchId: event.branchId);
      await _refreshStatusSnapshot(emit);
      emit(
        state.copyWith(
          phase: SyncPhase.success,
          status: state.status.copyWith(lastSyncTime: DateTime.now()),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(phase: SyncPhase.error, errorMessage: _humanizeError(e)),
      );
    }
  }

  Future<void> _onDelta(
    SyncDeltaRequested event,
    Emitter<SyncBlocState> emit,
  ) async {
    if (!_networkInfo.isConnected) {
      emit(
        state.copyWith(
          phase: SyncPhase.error,
          errorMessage: 'No internet connection',
        ),
      );
      return;
    }
    emit(state.copyWith(phase: SyncPhase.syncing, clearError: true));
    try {
      final last = await _syncRepository.getLastSyncedAt();
      if (last == null) {
        // No delta baseline yet: run bootstrap instead.
        await _syncRepository.bootstrap(branchId: event.branchId);
      } else {
        await _syncRepository.delta(branchId: event.branchId, since: last);
      }
      await _refreshStatusSnapshot(emit);
      emit(
        state.copyWith(
          phase: SyncPhase.success,
          status: state.status.copyWith(lastSyncTime: DateTime.now()),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(phase: SyncPhase.error, errorMessage: _humanizeError(e)),
      );
    }
  }

  Future<void> _onPush(
    SyncPushRequested event,
    Emitter<SyncBlocState> emit,
  ) async {
    if (!_networkInfo.isConnected) {
      emit(
        state.copyWith(
          phase: SyncPhase.error,
          errorMessage: 'No internet connection',
        ),
      );
      return;
    }
    emit(state.copyWith(phase: SyncPhase.syncing, clearError: true));
    try {
      final salesPush = await _syncRepository.pushPendingSales();
      final laundryPush = await _syncRepository.pushPendingLaundryActions();
      await _refreshStatusSnapshot(emit);
      emit(
        state.copyWith(
          phase: SyncPhase.success,
          status: state.status.copyWith(
            lastAcceptedCount:
                salesPush.accepted.length + laundryPush.accepted.length,
            lastRejectedCount:
                salesPush.rejected.length + laundryPush.rejected.length,
            lastSyncTime: DateTime.now(),
          ),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(phase: SyncPhase.error, errorMessage: _humanizeError(e)),
      );
    }
  }

  String _humanizeError(Object error) {
    final raw = error.toString();
    final lower = raw.toLowerCase();

    if (lower.contains('networkexception') ||
        lower.contains('socketexception') ||
        lower.contains('connection error')) {
      return 'No internet connection.';
    }

    if (lower.contains('page not found') ||
        lower.contains('not found') ||
        lower.contains('status: 404')) {
      return 'Sync endpoint not found. Check POS API URL and ensure backend /api/sync routes are available.';
    }

    if (lower.contains('serverexception')) {
      final idx = raw.indexOf(':');
      if (idx >= 0 && idx + 1 < raw.length) {
        final trimmed = raw.substring(idx + 1).trim();
        final statusIdx = trimmed.lastIndexOf('(status:');
        if (statusIdx > 0) {
          return trimmed.substring(0, statusIdx).trim();
        }
        return trimmed;
      }
    }

    return raw;
  }

  Future<void> _onConnectivityChanged(
    SyncConnectivityChanged event,
    Emitter<SyncBlocState> emit,
  ) async {
    emit(
      state.copyWith(status: state.status.copyWith(isOnline: event.isOnline)),
    );
    if (event.isOnline) {
      // Auto-trigger push+delta on connectivity restore.
      add(const SyncTriggered());
    }
  }

  @override
  Future<void> close() async {
    await _connectivitySub?.cancel();
    return super.close();
  }
}
