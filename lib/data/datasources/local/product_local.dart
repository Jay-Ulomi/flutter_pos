import 'dart:convert';

import 'package:drift/drift.dart';
import '../../models/product_models.dart';
import 'database.dart';

class ProductLocalDataSource {
  final AppDatabase _db;

  ProductLocalDataSource(this._db);

  Future<List<Product>> getProducts({
    String? search,
    String? categoryId,
  }) async {
    List<CachedProduct> results;

    if (search != null && search.isNotEmpty) {
      results = await _db.searchProducts(search);
    } else if (categoryId != null && categoryId.isNotEmpty) {
      results = await _db.getProductsByCategory(categoryId);
    } else {
      results = await _db.getAllProducts();
    }

    return results.map(_mapToProduct).toList();
  }

  Future<Product?> getProductByBarcode(String barcode) async {
    final result = await _db.getProductByBarcode(barcode);
    return result != null ? _mapToProduct(result) : null;
  }

  Future<void> cacheProducts(List<Product> products) async {
    await _db.clearProducts();
    final now = DateTime.now();
    for (final product in products) {
      await _db.upsertProduct(
        CachedProductsCompanion(
          id: Value(product.id),
          name: Value(product.name),
          description: Value(product.description),
          sku: Value(product.sku),
          barcode: Value(product.barcode),
          sellingPrice: Value(product.sellingPrice),
          costPrice: Value(product.costPrice),
          categoryId: Value(product.categoryId),
          categoryName: Value(product.categoryName),
          unit: Value(product.unit),
          stockQuantity: Value(product.stockQuantity),
          minStockLevel: Value(product.minStockLevel),
          trackInventory: Value(product.trackInventory),
          isActive: Value(product.isActive),
          imageUrl: Value(product.imageUrl),
          taxRate: Value(product.taxRate),
          taxable: Value(product.taxable),
          tierPricesJson: Value(product.tierPrices.isEmpty ? null : jsonEncode(product.tierPrices)),
          cachedAt: Value(now),
        ),
      );
    }
  }

  Future<List<Category>> getCategories() async {
    final results = await _db.getAllCategories();
    return results
        .map(
          (c) => Category(
            id: c.id,
            name: c.name,
            description: c.description,
            parentId: c.parentId,
            productCount: c.productCount,
          ),
        )
        .toList();
  }

  Future<void> cacheCategories(List<Category> categories) async {
    await _db.clearCategories();
    final now = DateTime.now();
    for (final cat in categories) {
      await _db.upsertCategory(
        CachedCategoriesCompanion(
          id: Value(cat.id),
          name: Value(cat.name),
          description: Value(cat.description),
          parentId: Value(cat.parentId),
          productCount: Value(cat.productCount),
          cachedAt: Value(now),
        ),
      );
    }
  }

  Product _mapToProduct(CachedProduct cp) {
    return Product(
      id: cp.id,
      name: cp.name,
      description: cp.description,
      sku: cp.sku,
      barcode: cp.barcode,
      sellingPrice: cp.sellingPrice,
      costPrice: cp.costPrice,
      categoryId: cp.categoryId,
      categoryName: cp.categoryName,
      unit: cp.unit,
      stockQuantity: cp.stockQuantity,
      minStockLevel: cp.minStockLevel,
      trackInventory: cp.trackInventory,
      isActive: cp.isActive,
      imageUrl: cp.imageUrl,
      taxRate: cp.taxRate,
      taxable: cp.taxable,
      tierPrices: _decodeTierPrices(cp.tierPricesJson),
    );
  }

  static Map<String, double> _decodeTierPrices(String? raw) {
    if (raw == null || raw.isEmpty) return const {};
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return const {};
    return {
      for (final e in decoded.entries)
        if (e.value is num) e.key.toString(): (e.value as num).toDouble(),
    };
  }
}
