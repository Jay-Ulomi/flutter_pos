import '../../core/network/network_info.dart';
import '../../domain/repositories/customer_repository.dart';
import '../datasources/local/customer_local.dart';
import '../datasources/remote/customer_remote.dart';
import '../models/customer_models.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  final CustomerRemoteDataSource _remote;
  final CustomerLocalDataSource _local;
  final NetworkInfo _networkInfo;

  CustomerRepositoryImpl(this._remote, this._local, this._networkInfo);

  @override
  Future<List<Customer>> getCustomers({String? search}) async {
    // Offline-first: read local, try to refresh when online
    final local = await _local.getCustomers(search: search);
    if (!_networkInfo.isConnected) {
      return local;
    }
    try {
      final remote = await _remote.getCustomers(search: search);
      // Cache remote results (additively — don't wipe)
      await _local.cacheCustomers(remote);
      return remote;
    } catch (_) {
      return local;
    }
  }

  @override
  Future<Customer?> getCustomerById(String id) async {
    if (_networkInfo.isConnected) {
      try {
        final fresh = await _remote.getCustomerById(id);
        await _local.cacheCustomer(fresh);
        return fresh;
      } catch (_) {
        return _local.getCustomerById(id);
      }
    }
    return _local.getCustomerById(id);
  }

  @override
  Future<Customer> createCustomer(Customer customer) async {
    final created = await _remote.createCustomer(customer);
    await _local.cacheCustomer(created);
    return created;
  }

  @override
  Future<Customer> updateCustomer(String id, Customer customer) async {
    final updated = await _remote.updateCustomer(id, customer);
    await _local.cacheCustomer(updated);
    return updated;
  }

  @override
  Future<Customer> adjustLoyaltyPoints(String id, int delta) async {
    final updated = await _remote.adjustLoyaltyPoints(id, delta);
    await _local.cacheCustomer(updated);
    return updated;
  }

  @override
  Future<Customer> adjustBalance(String id, double delta) async {
    final updated = await _remote.adjustBalance(id, delta);
    await _local.cacheCustomer(updated);
    return updated;
  }

  @override
  Future<List<CustomerGroup>> getCustomerGroups() async {
    if (_networkInfo.isConnected) {
      return _remote.getCustomerGroups();
    }
    return const [];
  }

  @override
  Future<CustomerGroup> createCustomerGroup(CustomerGroup group) {
    return _remote.createCustomerGroup(group);
  }

  @override
  Future<CustomerGroup> updateCustomerGroup(String id, CustomerGroup group) {
    return _remote.updateCustomerGroup(id, group);
  }

  @override
  Future<void> deleteCustomerGroup(String id) {
    return _remote.deleteCustomerGroup(id);
  }
}
