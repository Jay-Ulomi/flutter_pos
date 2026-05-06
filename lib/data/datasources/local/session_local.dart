import 'dart:convert';
import '../../models/session_models.dart';
import 'database.dart';

class SessionLocalDataSource {
  final AppDatabase _db;

  SessionLocalDataSource(this._db);

  Future<void> cacheSession(CashSession session) async {
    final json = {
      'id': session.id,
      'userId': session.userId,
      'userName': session.userName,
      'branchId': session.branchId,
      'openingCash': session.openingCash,
      'closingCash': session.closingCash,
      'expectedCash': session.expectedCash,
      'difference': session.difference,
      'status': session.status,
      'openedAt': session.openedAt.toIso8601String(),
      'closedAt': session.closedAt?.toIso8601String(),
      'notes': session.notes,
    };
    await _db.cacheSession('current', jsonEncode(json));
  }

  Future<CashSession?> getCachedSession() async {
    final jsonStr = await _db.getCachedSession('current');
    if (jsonStr == null) return null;
    final json = jsonDecode(jsonStr) as Map<String, dynamic>;
    return CashSession.fromJson(json);
  }

  Future<void> clearSession() async {
    await _db.cacheSession('current', '');
  }
}
