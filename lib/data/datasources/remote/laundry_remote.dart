import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/error/exceptions.dart';
import '../../../core/network/api_client.dart';
import '../../models/laundry_models.dart';

class LaundryRemoteDataSource {
  final ApiClient _apiClient;

  LaundryRemoteDataSource(this._apiClient);

  Future<LaundryPage> getOrders({
    String? branchId,
    LaundryOrderStatus? status,
    String? search,
    int page = 0,
    int size = 15,
  }) async {
    try {
      final query = <String, dynamic>{
        'page': page,
        'size': size,
        'sort': 'createdAt,desc',
      };
      if (branchId != null && branchId.isNotEmpty) {
        query['branchId'] = branchId;
      }
      if (status != null) {
        query['status'] = laundryStatusToApi(status);
      }
      if (search != null && search.trim().isNotEmpty) {
        query['search'] = search.trim();
      }

      final response = await _apiClient.dio.get(
        ApiConstants.laundryOrders,
        queryParameters: query,
      );
      return LaundryPage.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(
        message:
            e.response?.data?['message'] ??
            e.message ??
            'Failed to load laundry orders',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<LaundryOrder> createOrder({
    String? clientId,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? dueDateIso,
    String? notes,
    required double paidAmount,
    String? paymentMethod,
    String? paymentReference,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final payload = <String, dynamic>{
        'paidAmount': paidAmount,
        'items': items,
      };
      if (paymentMethod != null && paymentMethod.trim().isNotEmpty) {
        payload['paymentMethod'] = paymentMethod.trim();
      }
      if (paymentReference != null && paymentReference.trim().isNotEmpty) {
        payload['paymentReference'] = paymentReference.trim();
      }
      if (clientId != null && clientId.trim().isNotEmpty) {
        payload['clientId'] = clientId.trim();
      }
      if (customerId != null && customerId.trim().isNotEmpty) {
        payload['customerId'] = customerId.trim();
      }
      if (customerName != null && customerName.trim().isNotEmpty) {
        payload['customerName'] = customerName.trim();
      }
      if (customerPhone != null && customerPhone.trim().isNotEmpty) {
        payload['customerPhone'] = customerPhone.trim();
      }
      if (dueDateIso != null && dueDateIso.isNotEmpty) {
        payload['dueDate'] = dueDateIso;
      }
      if (notes != null && notes.trim().isNotEmpty) {
        payload['notes'] = notes.trim();
      }

      final response = await _apiClient.dio.post(
        ApiConstants.laundryOrders,
        data: payload,
      );
      return LaundryOrder.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(
        message:
            e.response?.data?['message'] ??
            e.message ??
            'Failed to create laundry order',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<LaundryOrder> updateStatus({
    required String orderId,
    required LaundryOrderStatus status,
    String? notes,
  }) async {
    try {
      final payload = <String, dynamic>{'status': laundryStatusToApi(status)};
      if (notes != null && notes.trim().isNotEmpty) {
        payload['notes'] = notes.trim();
      }
      final response = await _apiClient.dio.post(
        '${ApiConstants.laundryOrders}/$orderId/status',
        data: payload,
      );
      return LaundryOrder.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(
        message:
            e.response?.data?['message'] ??
            e.message ??
            'Failed to update laundry status',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<LaundryOrder> recordPayment({
    required String orderId,
    required double amount,
    String? paymentMethod,
    String? reference,
    String? notes,
  }) async {
    try {
      final payload = <String, dynamic>{'amount': amount};
      if (paymentMethod != null && paymentMethod.trim().isNotEmpty) {
        payload['paymentMethod'] = paymentMethod.trim();
      }
      if (reference != null && reference.trim().isNotEmpty) {
        payload['reference'] = reference.trim();
      }
      if (notes != null && notes.trim().isNotEmpty) {
        payload['notes'] = notes.trim();
      }
      final response = await _apiClient.dio.post(
        '${ApiConstants.laundryOrders}/$orderId/payments',
        data: payload,
      );
      return LaundryOrder.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(
        message:
            e.response?.data?['message'] ??
            e.message ??
            'Failed to record payment',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
