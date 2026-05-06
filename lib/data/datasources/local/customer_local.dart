import 'package:drift/drift.dart';

import '../../models/customer_models.dart';
import 'database.dart';

class CustomerLocalDataSource {
  final AppDatabase _db;

  CustomerLocalDataSource(this._db);

  Future<List<Customer>> getCustomers({String? search}) async {
    final rows = (search != null && search.isNotEmpty)
        ? await _db.searchCustomers(search)
        : await _db.getAllCustomers();
    return rows.map(_mapToCustomer).toList();
  }

  Future<Customer?> getCustomerById(String id) async {
    final row = await _db.getCustomerById(id);
    return row != null ? _mapToCustomer(row) : null;
  }

  Future<void> cacheCustomer(Customer customer) async {
    await _db.upsertCustomer(_toCompanion(customer));
  }

  Future<void> cacheCustomers(
    List<Customer> customers, {
    bool replace = false,
  }) async {
    if (replace) {
      await _db.clearCustomers();
    }
    for (final c in customers) {
      await _db.upsertCustomer(_toCompanion(c));
    }
  }

  Future<void> deleteCustomer(String id) async {
    await _db.deleteCustomerById(id);
  }

  CachedCustomersCompanion _toCompanion(Customer c) {
    final now = DateTime.now();
    return CachedCustomersCompanion(
      id: Value(c.id),
      code: Value(c.code),
      name: Value(c.name),
      phone: Value(c.phone),
      email: Value(c.email),
      address: Value(c.address),
      tinNumber: Value(c.tinNumber),
      customerType: Value(c.customerType),
      customerGroupId: Value(c.customerGroupId),
      currentBalance: Value(c.currentBalance),
      loyaltyPoints: Value(c.loyaltyPoints),
      isActive: Value(c.isActive),
      updatedAt: Value(c.updatedAt),
      cachedAt: Value(now),
    );
  }

  Customer _mapToCustomer(CachedCustomer row) {
    return Customer(
      id: row.id,
      code: row.code,
      name: row.name,
      phone: row.phone,
      email: row.email,
      address: row.address,
      tinNumber: row.tinNumber,
      customerType: row.customerType,
      customerGroupId: row.customerGroupId,
      currentBalance: row.currentBalance,
      loyaltyPoints: row.loyaltyPoints,
      isActive: row.isActive,
      updatedAt: row.updatedAt,
    );
  }
}
