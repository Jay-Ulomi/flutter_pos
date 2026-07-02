import 'package:equatable/equatable.dart';

class Category extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String? parentId;
  final int productCount;

  const Category({
    required this.id,
    required this.name,
    this.description,
    this.parentId,
    this.productCount = 0,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      parentId: json['parentId']?.toString(),
      productCount: json['productCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'parentId': parentId,
    'productCount': productCount,
  };

  @override
  List<Object?> get props => [id, name, description, parentId];
}

class ProductVariant extends Equatable {
  final String id;
  final String productId;
  final String name;
  final String? sku;
  final String? barcode;
  final double? costPrice;
  final double? sellingPrice;
  final Map<String, String> attributes;
  final bool isActive;

  const ProductVariant({
    required this.id,
    required this.productId,
    required this.name,
    this.sku,
    this.barcode,
    this.costPrice,
    this.sellingPrice,
    this.attributes = const {},
    this.isActive = true,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    final rawAttrs = json['attributes'];
    final attrs = <String, String>{};
    if (rawAttrs is Map) {
      rawAttrs.forEach((k, v) => attrs[k.toString()] = v.toString());
    }
    return ProductVariant(
      id: json['id']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      name: json['name'] ?? '',
      sku: json['sku'],
      barcode: json['barcode'],
      costPrice: json['costPrice']?.toDouble(),
      sellingPrice: json['sellingPrice']?.toDouble(),
      attributes: attrs,
      isActive: json['isActive'] ?? true,
    );
  }

  String get displayLabel {
    if (attributes.isEmpty) return name;
    final parts = attributes.entries.map((e) => '${e.key}: ${e.value}').join(' · ');
    return '$name ($parts)';
  }

  @override
  List<Object?> get props => [id, productId, name, sku];
}

class Product extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String? sku;
  final String? barcode;
  final double sellingPrice;
  final double? costPrice;
  final String? categoryId;
  final String? categoryName;
  final String? unit;
  final double? stockQuantity;
  final double? minStockLevel;
  final bool trackInventory;
  final bool isActive;
  final String? imageUrl;
  final double? taxRate;
  final Map<String, double> tierPrices;
  final List<ProductVariant> variants;
  /// 'NONE', 'SERIAL', or 'LOT'
  final String trackingType;

  const Product({
    required this.id,
    required this.name,
    this.description,
    this.sku,
    this.barcode,
    required this.sellingPrice,
    this.costPrice,
    this.categoryId,
    this.categoryName,
    this.unit,
    this.stockQuantity,
    this.minStockLevel,
    this.trackInventory = true,
    this.isActive = true,
    this.imageUrl,
    this.taxRate,
    this.tierPrices = const {},
    this.variants = const [],
    this.trackingType = 'NONE',
  });

  bool get hasVariants => variants.isNotEmpty;
  bool get requiresSerial => trackingType == 'SERIAL';
  bool get requiresLot => trackingType == 'LOT';

  double priceForTier(String? tierName) {
    if (tierName == null || tierName.trim().isEmpty) return sellingPrice;
    final key = tierName.trim().toUpperCase();
    return tierPrices[key] ?? sellingPrice;
  }

  bool get isLowStock {
    if (!trackInventory || stockQuantity == null || minStockLevel == null) {
      return false;
    }
    return stockQuantity! <= minStockLevel!;
  }

  bool get isOutOfStock {
    if (!trackInventory || stockQuantity == null) return false;
    return stockQuantity! <= 0;
  }

  /// Human-readable available stock, e.g. "12 pcs" or "3.5 kg". Returns null
  /// when the product isn't inventory-tracked (nothing to show).
  String? get stockLabel {
    if (!trackInventory || stockQuantity == null) return null;
    final q = stockQuantity!;
    final qStr =
        q == q.floorToDouble() ? q.toInt().toString() : q.toStringAsFixed(2);
    return (unit != null && unit!.isNotEmpty) ? '$qStr $unit' : qStr;
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    final rawTierPrices = json['tierPrices'];
    final parsedTierPrices = <String, double>{};
    if (rawTierPrices is Map) {
      for (final entry in rawTierPrices.entries) {
        final key = entry.key.toString().trim().toUpperCase();
        final value = entry.value;
        if (key.isEmpty || value == null) continue;
        if (value is num) {
          parsedTierPrices[key] = value.toDouble();
          continue;
        }
        final parsed = double.tryParse(value.toString());
        if (parsed != null) {
          parsedTierPrices[key] = parsed;
        }
      }
    }
    parsedTierPrices.putIfAbsent(
      'NORMAL',
      () => (json['sellingPrice'] ?? 0).toDouble(),
    );

    final rawVariants = json['variants'];
    final parsedVariants = <ProductVariant>[];
    if (rawVariants is List) {
      for (final v in rawVariants) {
        if (v is Map<String, dynamic>) {
          parsedVariants.add(ProductVariant.fromJson(v));
        }
      }
    }

    return Product(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      sku: json['sku'],
      barcode: json['barcode'],
      sellingPrice: (json['sellingPrice'] ?? 0).toDouble(),
      costPrice: json['costPrice']?.toDouble(),
      categoryId:
          json['categoryId']?.toString() ?? json['category']?['id']?.toString(),
      categoryName: json['categoryName'] ?? json['category']?['name'],
      unit: json['unit'] ?? json['unitAbbreviation'] ?? json['unitName'],
      stockQuantity:
          json['stockQuantity']?.toDouble() ?? json['currentStock']?.toDouble(),
      minStockLevel: json['minStockLevel']?.toDouble(),
      trackInventory: json['trackInventory'] ?? true,
      isActive: json['active'] ?? json['isActive'] ?? true,
      imageUrl: json['imageUrl'],
      taxRate: json['taxRate']?.toDouble(),
      tierPrices: parsedTierPrices,
      variants: parsedVariants,
      trackingType: json['trackingType'] ?? 'NONE',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'sku': sku,
    'barcode': barcode,
    'sellingPrice': sellingPrice,
    'costPrice': costPrice,
    'categoryId': categoryId,
    'categoryName': categoryName,
    'unit': unit,
    'stockQuantity': stockQuantity,
    'minStockLevel': minStockLevel,
    'trackInventory': trackInventory,
    'isActive': isActive,
    'imageUrl': imageUrl,
    'taxRate': taxRate,
    'tierPrices': tierPrices,
  };

  @override
  List<Object?> get props => [id, name, barcode, sellingPrice];
}
