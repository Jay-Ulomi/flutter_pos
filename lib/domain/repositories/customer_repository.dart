import '../../data/models/customer_models.dart';

abstract class CustomerRepository {
  Future<List<Customer>> getCustomers({String? search});
  Future<Customer?> getCustomerById(String id);
  Future<Customer> createCustomer(Customer customer);
  Future<Customer> updateCustomer(String id, Customer customer);
  Future<Customer> adjustLoyaltyPoints(String id, int delta);
  Future<Customer> adjustBalance(String id, double delta);
  Future<List<CustomerGroup>> getCustomerGroups();
  Future<CustomerGroup> createCustomerGroup(CustomerGroup group);
  Future<CustomerGroup> updateCustomerGroup(String id, CustomerGroup group);
  Future<void> deleteCustomerGroup(String id);
}
