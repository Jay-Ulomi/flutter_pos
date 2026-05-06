import '../../core/network/network_info.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/local/product_local.dart';
import '../datasources/remote/inventory_remote.dart';
import '../datasources/remote/product_remote.dart';
import '../models/product_models.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource _remote;
  final InventoryRemoteDataSource _inventoryRemote;
  final ProductLocalDataSource _local;
  final NetworkInfo _networkInfo;

  ProductRepositoryImpl(
    this._remote,
    this._inventoryRemote,
    this._local,
    this._networkInfo,
  );

  @override
  Future<List<Product>> getProducts({
    String? search,
    String? categoryId,
  }) async {
    if (_networkInfo.isConnected) {
      try {
        final products = await _remote.getProducts(
          search: search,
          categoryId: categoryId,
        );
        if (search == null && categoryId == null) {
          await _local.cacheProducts(products);
        }
        return products;
      } catch (_) {
        return _local.getProducts(search: search, categoryId: categoryId);
      }
    }
    return _local.getProducts(search: search, categoryId: categoryId);
  }

  @override
  Future<Product?> getProductByBarcode(String barcode) async {
    if (_networkInfo.isConnected) {
      try {
        return await _remote.getProductByBarcode(barcode);
      } catch (_) {
        return _local.getProductByBarcode(barcode);
      }
    }
    return _local.getProductByBarcode(barcode);
  }

  @override
  Future<List<Category>> getCategories() async {
    if (_networkInfo.isConnected) {
      try {
        final categories = await _remote.getCategories();
        await _local.cacheCategories(categories);
        return categories;
      } catch (_) {
        return _local.getCategories();
      }
    }
    return _local.getCategories();
  }

  @override
  Future<void> refreshProducts() async {
    final products = await _remote.getProducts();
    await _local.cacheProducts(products);
    final categories = await _remote.getCategories();
    await _local.cacheCategories(categories);
  }

  @override
  Future<List<Product>> getStockLevels({
    required String branchId,
    String? search,
    bool? lowStockOnly,
  }) async {
    return _inventoryRemote.getStockLevels(
      branchId: branchId,
      search: search,
      lowStockOnly: lowStockOnly,
    );
  }
}
