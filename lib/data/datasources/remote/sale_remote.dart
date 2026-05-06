import 'package:dio/dio.dart';
import '../../../core/network/api_response.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/error/exceptions.dart';
import '../../../core/network/api_client.dart';
import '../../models/sale_models.dart';

class SaleRemoteDataSource {
  final ApiClient _apiClient;

  SaleRemoteDataSource(this._apiClient);

  Future<Sale> completeSale(Sale sale) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.sales,
        data: sale.toJson(),
      );
      return Sale.fromJson(response.data);
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message'] ?? 'Failed to complete sale',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<Sale> getSaleByNumber(String saleNumber) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiConstants.sales}/by-number/$saleNumber',
      );
      return Sale.fromJson(response.data);
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message'] ?? 'Sale not found',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<Sale> processReturn({
    required String saleId,
    required List<Map<String, dynamic>> returnItems,
    required String reason,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.returns,
        data: {'saleId': saleId, 'items': returnItems, 'reason': reason},
      );
      return Sale.fromJson(response.data);
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message'] ?? 'Failed to process return',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<Receipt> getReceipt(String saleId) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiConstants.sales}/$saleId/receipt',
      );
      return Receipt.fromJson(response.data);
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message'] ?? 'Failed to get receipt',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<List<Sale>> getSales({
    String status = 'COMPLETED',
    int page = 0,
    int size = 50,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.sales,
        queryParameters: {
          'status': status,
          'page': page,
          'size': size,
          'sort': 'createdAt,desc',
        },
      );
      final paged = PaginatedResponse<Sale>.fromJson(
        response.data as Map<String, dynamic>,
        Sale.fromJson,
      );
      return paged.content;
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message'] ?? 'Failed to load sales',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
