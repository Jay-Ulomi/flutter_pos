import 'dart:convert';

import 'package:drift/drift.dart';

import '../../models/sync_models.dart';
import 'database.dart';

class LaundryLocalDataSource {
  final AppDatabase _db;

  LaundryLocalDataSource(this._db);

  Future<void> savePendingAction(PendingLaundrySyncAction action) async {
    await _db.insertPendingLaundryAction(
      PendingLaundryActionsCompanion(
        localId: Value(action.localId),
        clientOpId: Value(action.clientOpId),
        actionType: Value(laundrySyncActionTypeApi(action.actionType)),
        orderId: Value(action.orderId),
        payloadJson: Value(jsonEncode(action.payload)),
        status: Value(action.status.name),
        errorMessage: Value(action.errorMessage),
        retryCount: Value(action.retryCount),
        createdAt: Value(action.createdAt),
      ),
    );
  }

  Future<List<PendingLaundrySyncAction>> getPendingActions() async {
    final rows = await _db.getPendingLaundryActions();
    return rows.map((row) {
      final payload = jsonDecode(row.payloadJson) as Map<String, dynamic>;
      return PendingLaundrySyncAction(
        localId: row.localId,
        clientOpId: row.clientOpId,
        actionType: laundrySyncActionTypeFromApi(row.actionType),
        orderId: row.orderId,
        payload: payload,
        createdAt: row.createdAt,
        status: SyncItemStatus.values.firstWhere(
          (e) => e.name == row.status,
          orElse: () => SyncItemStatus.pending,
        ),
        errorMessage: row.errorMessage,
        retryCount: row.retryCount,
      );
    }).toList();
  }

  Future<int> getPendingActionCount() => _db.getPendingLaundryActionCount();

  Future<int> getFailedActionCount() => _db.getFailedLaundryActionCount();

  Future<void> updateActionStatus(
    String localId,
    SyncItemStatus status,
    String? error,
  ) async {
    await _db.updatePendingLaundryActionStatus(localId, status.name, error);
  }

  Future<void> deletePendingAction(String localId) async {
    await _db.deletePendingLaundryAction(localId);
  }

  Future<void> incrementRetryCount(String localId) async {
    await _db.incrementLaundryRetryCount(localId);
  }
}
