import '../../data/models/session_models.dart';

abstract class SessionRepository {
  Future<CashSession> openSession(OpenSessionRequest request);
  Future<CashSession> closeSession(CloseSessionRequest request);
  Future<CashSession?> getCurrentSession();
  Future<ShiftSummary> getSessionSummary(String sessionId);

  /// If the active session was opened offline (provisional), create/adopt the
  /// real server session and repoint any queued sales to it. No-op when there's
  /// no provisional session or when offline. Throws on failure so callers can
  /// avoid pushing sales that still reference the provisional session id.
  Future<void> reconcileProvisionalSession();
}
