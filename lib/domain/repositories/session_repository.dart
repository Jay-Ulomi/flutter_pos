import '../../data/models/session_models.dart';

abstract class SessionRepository {
  Future<CashSession> openSession(OpenSessionRequest request);
  Future<CashSession> closeSession(CloseSessionRequest request);
  Future<CashSession?> getCurrentSession();
  Future<ShiftSummary> getSessionSummary(String sessionId);
}
