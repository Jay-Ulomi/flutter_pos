import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/error/exceptions.dart';
import '../../../core/network/api_client.dart';
import '../../models/product_models.dart';

class InventoryRemoteDataSource {
  final ApiClient _apiClient;

  InventoryRemoteDataSource(this._apiClient);

  Future<List<Product>> getStockLevels({
    required String branchId,
    int page = 0,
    int size = 50,
    String? search,
    bool? lowStockOnly,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page, 'size': size};
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (lowStockOnly == true) {
        queryParams['lowStock'] = true;
      }

      final response = await _apiClient.dio.get(
        ApiConstants.stockLevels(branchId),
        queryParameters: queryParams,
      );
      final data = response.data;
      final list = data is List ? data : (data['content'] ?? []) as List;
      return list
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message'] ?? 'Failed to get stock levels',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
