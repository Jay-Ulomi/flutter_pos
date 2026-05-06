import '../../data/models/product_models.dart';

abstract class ProductRepository {
  Future<List<Product>> getProducts({String? search, String? categoryId});
  Future<Product?> getProductByBarcode(String barcode);
  Future<List<Category>> getCategories();
  Future<void> refreshProducts();
  Future<List<Product>> getStockLevels({
    required String branchId,
    String? search,
    bool? lowStockOnly,
  });
}
