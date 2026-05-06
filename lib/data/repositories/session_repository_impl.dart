import '../../core/network/network_info.dart';
import '../../domain/repositories/session_repository.dart';
import '../datasources/local/session_local.dart';
import '../datasources/remote/session_remote.dart';
import '../models/session_models.dart';

class SessionRepositoryImpl implements SessionRepository {
  final SessionRemoteDataSource _remote;
  final SessionLocalDataSource _local;
  final NetworkInfo _networkInfo;

  SessionRepositoryImpl(this._remote, this._local, this._networkInfo);

  @override
  Future<CashSession> openSession(OpenSessionRequest request) async {
    final session = await _remote.openSession(request);
    await _local.cacheSession(session);
    return session;
  }

  @override
  Future<CashSession> closeSession(CloseSessionRequest request) async {
    final session = await _remote.closeSession(request);
    await _local.clearSession();
    return session;
  }

  @override
  Future<CashSession?> getCurrentSession() async {
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
