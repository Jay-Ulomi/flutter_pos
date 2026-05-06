import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/error/exceptions.dart';
import '../../../core/network/api_client.dart';
import '../../models/product_models.dart';

class ProductRemoteDataSource {
  final ApiClient _apiClient;

  ProductRemoteDataSource(this._apiClient);

  Future<List<Product>> getProducts({
    int page = 0,
    int size = 100,
    String? search,
    String? categoryId,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page, 'size': size};
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (categoryId != null && categoryId.isNotEmpty) {
        queryParams['categoryId'] = categoryId;
      }

      final response = await _apiClient.dio.get(
        ApiConstants.products,
        queryParameters: queryParams,
      );
      final data = response.data;
      final list = data is List ? data : (data['content'] ?? []) as List;
      return list
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message'] ?? 'Failed to get products',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<Product?> getProductByBarcode(String barcode) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiConstants.productByBarcode}/$barcode',
      );
      return Product.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw ServerException(
        message: e.response?.data?['message'] ?? 'Failed to find product',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<List<Category>> getCategories() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.categories);
      final data = response.data;
      final list = data is List ? data : (data['content'] ?? []) as List;
      return list
          .map((e) => Category.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message'] ?? 'Failed to get categories',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
