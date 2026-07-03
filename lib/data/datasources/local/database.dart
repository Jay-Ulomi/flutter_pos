import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

class CachedProducts extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get sku => text().nullable()();
  TextColumn get barcode => text().nullable()();
  RealColumn get sellingPrice => real()();
  RealColumn get costPrice => real().nullable()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get categoryName => text().nullable()();
  TextColumn get unit => text().nullable()();
  RealColumn get stockQuantity => real().nullable()();
  RealColumn get minStockLevel => real().nullable()();
  BoolColumn get trackInventory =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  TextColumn get imageUrl => text().nullable()();
  RealColumn get taxRate => real().nullable()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class CachedCategories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get parentId => text().nullable()();
  IntColumn get productCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class CachedCustomers extends Table {
  TextColumn get id => text()();
  TextColumn get code => text().nullable()();
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get tinNumber => text().nullable()();
  TextColumn get customerType => text().nullable()();
  TextColumn get customerGroupId => text().nullable()();
  RealColumn get currentBalance => real().withDefault(const Constant(0))();
  IntColumn get loyaltyPoints => integer().withDefault(const Constant(0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class PendingSales extends Table {
  TextColumn get localId => text()();
  TextColumn get clientId => text().nullable()();
  TextColumn get saleJson => text()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  TextColumn get errorMessage => text().nullable()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {localId};
}

class PendingLaundryActions extends Table {
  TextColumn get localId => text()();
  TextColumn get clientOpId => text()();
  TextColumn get actionType => text()();
  TextColumn get orderId => text().nullable()();
  TextColumn get payloadJson => text()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  TextColumn get errorMessage => text().nullable()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {localId};
}

class CachedSessions extends Table {
  TextColumn get id => text()();
  TextColumn get sessionJson => text()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class SyncMeta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(
  tables: [
    CachedProducts,
    CachedCategories,
    CachedCustomers,
    PendingSales,
    PendingLaundryActions,
    CachedSessions,
    SyncMeta,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(cachedCustomers);
        await m.createTable(syncMeta);
        await m.addColumn(pendingSales, pendingSales.clientId);
      }
      if (from < 3) {
        await m.createTable(pendingLaundryActions);
      }
    },
  );

  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'pos_cache.sqlite'));
      return NativeDatabase(file);
    });
  }

  // Products
  Future<List<CachedProduct>> getAllProducts() => select(cachedProducts).get();

  Future<List<CachedProduct>> searchProducts(String query) {
    return (select(cachedProducts)..where(
          (p) =>
              p.name.like('%$query%') |
              p.barcode.like('%$query%') |
              p.sku.like('%$query%'),
        ))
        .get();
  }

  Future<CachedProduct?> getProductByBarcode(String barcode) {
    return (select(
      cachedProducts,
    )..where((p) => p.barcode.equals(barcode))).getSingleOrNull();
  }

  Future<List<CachedProduct>> getProductsByCategory(String categoryId) {
    return (select(
      cachedProducts,
    )..where((p) => p.categoryId.equals(categoryId))).get();
  }

  Future<void> upsertProduct(CachedProductsCompanion product) {
    return into(cachedProducts).insertOnConflictUpdate(product);
  }

  Future<void> clearProducts() => delete(cachedProducts).go();

  Future<void> deleteProductById(String id) {
    return (delete(cachedProducts)..where((p) => p.id.equals(id))).go();
  }

  // Categories
  Future<List<CachedCategory>> getAllCategories() =>
      select(cachedCategories).get();

  Future<void> upsertCategory(CachedCategoriesCompanion category) {
    return into(cachedCategories).insertOnConflictUpdate(category);
  }

  Future<void> clearCategories() => delete(cachedCategories).go();

  // Customers
  Future<List<CachedCustomer>> getAllCustomers() => (select(
    cachedCustomers,
  )..orderBy([(c) => OrderingTerm.asc(c.name)])).get();

  Future<List<CachedCustomer>> searchCustomers(String query) {
    final q = '%$query%';
    return (select(cachedCustomers)
          ..where(
            (c) =>
                c.name.like(q) |
                c.phone.like(q) |
                c.email.like(q) |
                c.code.like(q),
          )
          ..orderBy([(c) => OrderingTerm.asc(c.name)]))
        .get();
  }

  Future<CachedCustomer?> getCustomerById(String id) {
    return (select(
      cachedCustomers,
    )..where((c) => c.id.equals(id))).getSingleOrNull();
  }

  Future<void> upsertCustomer(CachedCustomersCompanion customer) {
    return into(cachedCustomers).insertOnConflictUpdate(customer);
  }

  Future<void> deleteCustomerById(String id) {
    return (delete(cachedCustomers)..where((c) => c.id.equals(id))).go();
  }

  Future<void> clearCustomers() => delete(cachedCustomers).go();

  // Pending Sales
  Future<List<PendingSale>> getPendingSales() {
    return (select(pendingSales)
          ..where((s) => s.status.isIn(['pending', 'failed']))
          ..orderBy([(s) => OrderingTerm.asc(s.createdAt)]))
        .get();
  }

  Future<List<PendingSale>> getAllSalesRows() {
    return (select(
      pendingSales,
    )..orderBy([(s) => OrderingTerm.desc(s.createdAt)])).get();
  }

  Future<int> getPendingSaleCount() async {
    final count = countAll();
    final query = selectOnly(pendingSales)
      ..where(pendingSales.status.isIn(['pending', 'failed']))
      ..addColumns([count]);
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  Future<int> getFailedSaleCount() async {
    final count = countAll();
    final query = selectOnly(pendingSales)
      ..where(pendingSales.status.equals('failed'))
      ..addColumns([count]);
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  /// Count of queued sales still worth auto-retrying: everything still
  /// `pending`, plus `failed` rows that have not yet exhausted [maxRetry]
  /// attempts. Exhausted-failed rows are excluded so the background retry
  /// loop stops hammering permanently-rejected sales (they remain visible
  /// and can still be pushed manually or cleared).
  Future<int> getRetriablePendingSaleCount({int maxRetry = 5}) async {
    final count = countAll();
    final query = selectOnly(pendingSales)
      ..where(
        pendingSales.status.equals('pending') |
            (pendingSales.status.equals('failed') &
                pendingSales.retryCount.isSmallerThanValue(maxRetry)),
      )
      ..addColumns([count]);
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  /// Removes all queued sales stuck in the `failed` state. Returns the number
  /// of rows deleted.
  Future<int> deleteFailedSales() {
    return (delete(pendingSales)..where((s) => s.status.equals('failed'))).go();
  }

  Future<void> insertPendingSale(PendingSalesCompanion sale) {
    return into(pendingSales).insert(sale);
  }

  Future<void> updatePendingSaleStatus(
    String localId,
    String status,
    String? error,
  ) {
    return (update(
      pendingSales,
    )..where((s) => s.localId.equals(localId))).write(
      PendingSalesCompanion(
        status: Value(status),
        errorMessage: Value(error),
        retryCount: const Value.absent(),
      ),
    );
  }

  Future<void> deletePendingSale(String localId) {
    return (delete(pendingSales)..where((s) => s.localId.equals(localId))).go();
  }

  Future<void> deletePendingSaleByClientId(String clientId) {
    return (delete(
      pendingSales,
    )..where((s) => s.clientId.equals(clientId))).go();
  }

  Future<void> updatePendingSaleClientData(
    String localId,
    String clientId,
    String saleJson,
  ) {
    return (update(
      pendingSales,
    )..where((s) => s.localId.equals(localId))).write(
      PendingSalesCompanion(
        clientId: Value(clientId),
        saleJson: Value(saleJson),
      ),
    );
  }

  Future<void> incrementRetryCount(String localId) async {
    // Atomic increment — avoids a lost update if two pushes race.
    await customUpdate(
      'UPDATE pending_sales SET retry_count = retry_count + 1 WHERE local_id = ?',
      variables: [Variable.withString(localId)],
      updates: {pendingSales},
    );
  }

  /// Recovers sales left in `syncing` after an app-kill mid-push. They are
  /// idempotent by clientId, so re-queueing them is safe and prevents silent
  /// loss. Returns the number of rows recovered.
  Future<int> resetSyncingSales() {
    return (update(pendingSales)..where((s) => s.status.equals('syncing')))
        .write(const PendingSalesCompanion(status: Value('pending')));
  }

  // Pending Laundry Actions
  Future<List<PendingLaundryAction>> getPendingLaundryActions() {
    return (select(pendingLaundryActions)
          ..where((s) => s.status.isIn(['pending', 'failed']))
          ..orderBy([(s) => OrderingTerm.asc(s.createdAt)]))
        .get();
  }

  Future<int> getPendingLaundryActionCount() async {
    final count = countAll();
    final query = selectOnly(pendingLaundryActions)
      ..where(pendingLaundryActions.status.isIn(['pending', 'failed']))
      ..addColumns([count]);
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  Future<int> getFailedLaundryActionCount() async {
    final count = countAll();
    final query = selectOnly(pendingLaundryActions)
      ..where(pendingLaundryActions.status.equals('failed'))
      ..addColumns([count]);
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  Future<void> insertPendingLaundryAction(
    PendingLaundryActionsCompanion action,
  ) {
    return into(pendingLaundryActions).insert(action);
  }

  Future<void> updatePendingLaundryActionStatus(
    String localId,
    String status,
    String? error,
  ) {
    return (update(
      pendingLaundryActions,
    )..where((s) => s.localId.equals(localId))).write(
      PendingLaundryActionsCompanion(
        status: Value(status),
        errorMessage: Value(error),
        retryCount: const Value.absent(),
      ),
    );
  }

  Future<void> deletePendingLaundryAction(String localId) {
    return (delete(
      pendingLaundryActions,
    )..where((s) => s.localId.equals(localId))).go();
  }

  Future<void> incrementLaundryRetryCount(String localId) async {
    final action = await (select(
      pendingLaundryActions,
    )..where((s) => s.localId.equals(localId))).getSingleOrNull();
    if (action != null) {
      await (update(
        pendingLaundryActions,
      )..where((s) => s.localId.equals(localId))).write(
        PendingLaundryActionsCompanion(
          retryCount: Value(action.retryCount + 1),
        ),
      );
    }
  }

  // Sessions
  Future<void> cacheSession(String id, String sessionJson) {
    return into(cachedSessions).insertOnConflictUpdate(
      CachedSessionsCompanion(
        id: Value(id),
        sessionJson: Value(sessionJson),
        cachedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<String?> getCachedSession(String id) async {
    final result = await (select(
      cachedSessions,
    )..where((s) => s.id.equals(id))).getSingleOrNull();
    return result?.sessionJson;
  }

  // Sync Meta
  Future<String?> getMeta(String key) async {
    final row = await (select(
      syncMeta,
    )..where((m) => m.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> setMeta(String key, String? value) {
    return into(syncMeta).insertOnConflictUpdate(
      SyncMetaCompanion(
        key: Value(key),
        value: Value(value),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
