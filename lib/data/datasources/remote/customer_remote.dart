import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/error/exceptions.dart';
import '../../../core/network/api_client.dart';
import '../../models/customer_models.dart';

class CustomerRemoteDataSource {
  final ApiClient _apiClient;

  CustomerRemoteDataSource(this._apiClient);

  Future<List<Customer>> getCustomers({
    int page = 0,
    int size = 50,
    String? search,
    String? customerGroupId,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page, 'size': size};
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (customerGroupId != null && customerGroupId.isNotEmpty) {
        queryParams['customerGroupId'] = customerGroupId;
      }

      final response = await _apiClient.dio.get(
        ApiConstants.customers,
        queryParameters: queryParams,
      );
      final data = response.data;
      final list = data is List ? data : (data['content'] ?? []) as List;
      return list
          .map((e) => Customer.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message'] ?? 'Failed to get customers',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<Customer> getCustomerById(String id) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiConstants.customers}/$id',
      );
      return Customer.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message'] ?? 'Customer not found',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<Customer> createCustomer(Customer customer) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.customers,
        data: customer.toCreateRequest(),
      );
      return Customer.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message'] ?? 'Failed to create customer',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<Customer> updateCustomer(String id, Customer customer) async {
    try {
      final response = await _apiClient.dio.put(
        '${ApiConstants.customers}/$id',
        data: customer.toCreateRequest(),
      );
      return Customer.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message'] ?? 'Failed to update customer',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<Customer> adjustLoyaltyPoints(String id, int delta) async {
    try {
      final response = await _apiClient.dio.post(
        '${ApiConstants.customers}/$id/loyalty-points',
        queryParameters: {'delta': delta},
      );
      return Customer.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(
        message:
            e.response?.data?['message'] ?? 'Failed to adjust loyalty points',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<Customer> adjustBalance(String id, double delta) async {
    try {
      final response = await _apiClient.dio.post(
        '${ApiConstants.customers}/$id/balance',
        queryParameters: {'delta': delta},
      );
      return Customer.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message'] ?? 'Failed to adjust balance',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<List<CustomerGroup>> getCustomerGroups() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.customerGroups);
      final data = response.data;
      final list = data is List ? data : (data['content'] ?? []) as List;
      return list
          .map((e) => CustomerGroup.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(
        message:
            e.response?.data?['message'] ?? 'Failed to get customer groups',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<CustomerGroup> createCustomerGroup(CustomerGroup group) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.customerGroups,
        data: group.toCreateRequest(),
      );
      return CustomerGroup.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(
        message:
            e.response?.data?['message'] ?? 'Failed to create customer group',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<CustomerGroup> updateCustomerGroup(
    String id,
    CustomerGroup group,
  ) async {
    try {
      final response = await _apiClient.dio.put(
        '${ApiConstants.customerGroups}/$id',
        data: group.toCreateRequest(),
      );
      return CustomerGroup.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(
        message:
            e.response?.data?['message'] ?? 'Failed to update customer group',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<void> deleteCustomerGroup(String id) async {
    try {
      await _apiClient.dio.delete('${ApiConstants.customerGroups}/$id');
    } on DioException catch (e) {
      throw ServerException(
        message:
            e.response?.data?['message'] ?? 'Failed to delete customer group',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
