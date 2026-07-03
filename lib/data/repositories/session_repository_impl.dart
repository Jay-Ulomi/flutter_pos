import 'package:uuid/uuid.dart';

import '../../core/error/exceptions.dart';
import '../../core/network/network_info.dart';
import '../../core/utils/token_manager.dart';
import '../../domain/repositories/session_repository.dart';
import '../datasources/local/sale_local.dart';
import '../datasources/local/session_local.dart';
import '../datasources/remote/session_remote.dart';
import '../models/session_models.dart';

class SessionRepositoryImpl implements SessionRepository {
  final SessionRemoteDataSource _remote;
  final SessionLocalDataSource _local;
  final NetworkInfo _networkInfo;
  final SaleLocalDataSource _saleLocal;
  final TokenManager _tokenManager;
  final _uuid = const Uuid();

  SessionRepositoryImpl(
    this._remote,
    this._local,
    this._networkInfo,
    this._saleLocal,
    this._tokenManager,
  );

  /// A session opened offline carries a client-generated id until it's
  /// reconciled to the real server session.
  static bool _isProvisional(CashSession s) => s.id.startsWith('local_');

  bool _isTransient(Object e) {
    if (e is NetworkException) return true;
    if (e is ServerException) {
      return e.statusCode == null || e.statusCode! >= 500;
    }
    return true;
  }

  @override
  Future<CashSession> openSession(OpenSessionRequest request) async {
    if (_networkInfo.isConnected) {
      try {
        final session = await _remote.openSession(request);
        await _local.cacheSession(session);
        return session;
      } catch (e) {
        // A real business rejection (e.g. "already has an active session")
        // must surface — only fall back to a provisional session on a
        // transient failure.
        if (!_isTransient(e)) rethrow;
      }
    }
    // Offline / transient: open a provisional local session so the cashier can
    // start selling. It's reconciled to a real server session on reconnect.
    final branchId = await _tokenManager.getBranchId() ?? '';
    final provisional = CashSession(
      id: 'local_${_uuid.v4()}',
      userId: '',
      branchId: branchId,
      openingCash: request.openingCash,
      status: 'OPEN',
      openedAt: DateTime.now(),
      notes: request.notes,
    );
    await _local.cacheSession(provisional);
    return provisional;
  }

  @override
  Future<void> reconcileProvisionalSession() async {
    if (!_networkInfo.isConnected) return;
    final cached = await _local.getCachedSession();
    final cacheProvisional = cached != null && _isProvisional(cached);
    // Also handle stragglers: sales queued with a provisional id from stale UI
    // state after the session was already reconciled.
    final hasStragglers = await _saleLocal.hasProvisionalSessionSales();
    if (!cacheProvisional && !hasStragglers) return;

    // Adopt the server's already-open session if there is one; otherwise open a
    // new one with the cash the cashier counted offline.
    final active = await _remote.getCurrentSession();
    final real = active ??
        await _remote.openSession(
          OpenSessionRequest(
            openingCash: cached?.openingCash ?? 0,
            notes: cached?.notes,
          ),
        );

    // Repoint EVERY provisional-session sale BEFORE caching the real session,
    // so a failure leaves rows still provisional (retried on the next push).
    await _saleLocal.remapProvisionalSessions(real.id);
    if (cacheProvisional) await _local.cacheSession(real);
  }

  @override
  Future<CashSession> closeSession(CloseSessionRequest request) async {
    // A provisional session must become real before it can be closed on the
    // server. (The bloc already blocks closing while sales are queued.)
    final cached = await _local.getCachedSession();
    if (cached != null && _isProvisional(cached)) {
      if (!_networkInfo.isConnected) {
        throw ServerException(
          message: 'Reconnect to close a session that was opened offline.',
        );
      }
      await reconcileProvisionalSession();
      final real = await _local.getCachedSession();
      request = CloseSessionRequest(
        sessionId: real?.id ?? request.sessionId,
        closingCash: request.closingCash,
        notes: request.notes,
      );
    }
    final session = await _remote.closeSession(request);
    await _local.clearSession();
    return session;
  }

  @override
  Future<CashSession?> getCurrentSession() async {
    // Never overwrite an unreconciled provisional session with the server's
    // (likely null) answer — the cashier is mid-shift offline.
    final cached = await _local.getCachedSession();
    if (cached != null && _isProvisional(cached)) return cached;

    if (_networkInfo.isConnected) {
      try {
        final session = await _remote.getCurrentSession();
        if (session != null) {
          await _local.cacheSession(session);
        }
        return session;
      } catch (_) {
        return _local.getCachedSession();
      }
    }
    return _local.getCachedSession();
  }

  @override
  Future<ShiftSummary> getSessionSummary(String sessionId) async {
    return _remote.getSessionSummary(sessionId);
  }
}
