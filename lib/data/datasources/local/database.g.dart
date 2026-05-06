// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $CachedProductsTable extends CachedProducts
    with TableInfo<$CachedProductsTable, CachedProduct> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedProductsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _skuMeta = const VerificationMeta('sku');
  @override
  late final GeneratedColumn<String> sku = GeneratedColumn<String>(
    'sku',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _barcodeMeta = const VerificationMeta(
    'barcode',
  );
  @override
  late final GeneratedColumn<String> barcode = GeneratedColumn<String>(
    'barcode',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sellingPriceMeta = const VerificationMeta(
    'sellingPrice',
  );
  @override
  late final GeneratedColumn<double> sellingPrice = GeneratedColumn<double>(
    'selling_price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _costPriceMeta = const VerificationMeta(
    'costPrice',
  );
  @override
  late final GeneratedColumn<double> costPrice = GeneratedColumn<double>(
    'cost_price',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryNameMeta = const VerificationMeta(
    'categoryName',
  );
  @override
  late final GeneratedColumn<String> categoryName = GeneratedColumn<String>(
    'category_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stockQuantityMeta = const VerificationMeta(
    'stockQuantity',
  );
  @override
  late final GeneratedColumn<double> stockQuantity = GeneratedColumn<double>(
    'stock_quantity',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _minStockLevelMeta = const VerificationMeta(
    'minStockLevel',
  );
  @override
  late final GeneratedColumn<double> minStockLevel = GeneratedColumn<double>(
    'min_stock_level',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _trackInventoryMeta = const VerificationMeta(
    'trackInventory',
  );
  @override
  late final GeneratedColumn<bool> trackInventory = GeneratedColumn<bool>(
    'track_inventory',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("track_inventory" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _taxRateMeta = const VerificationMeta(
    'taxRate',
  );
  @override
  late final GeneratedColumn<double> taxRate = GeneratedColumn<double>(
    'tax_rate',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    description,
    sku,
    barcode,
    sellingPrice,
    costPrice,
    categoryId,
    categoryName,
    unit,
    stockQuantity,
    minStockLevel,
    trackInventory,
    isActive,
    imageUrl,
    taxRate,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_products';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedProduct> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('sku')) {
      context.handle(
        _skuMeta,
        sku.isAcceptableOrUnknown(data['sku']!, _skuMeta),
      );
    }
    if (data.containsKey('barcode')) {
      context.handle(
        _barcodeMeta,
        barcode.isAcceptableOrUnknown(data['barcode']!, _barcodeMeta),
      );
    }
    if (data.containsKey('selling_price')) {
      context.handle(
        _sellingPriceMeta,
        sellingPrice.isAcceptableOrUnknown(
          data['selling_price']!,
          _sellingPriceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sellingPriceMeta);
    }
    if (data.containsKey('cost_price')) {
      context.handle(
        _costPriceMeta,
        costPrice.isAcceptableOrUnknown(data['cost_price']!, _costPriceMeta),
      );
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('category_name')) {
      context.handle(
        _categoryNameMeta,
        categoryName.isAcceptableOrUnknown(
          data['category_name']!,
          _categoryNameMeta,
        ),
      );
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    if (data.containsKey('stock_quantity')) {
      context.handle(
        _stockQuantityMeta,
        stockQuantity.isAcceptableOrUnknown(
          data['stock_quantity']!,
          _stockQuantityMeta,
        ),
      );
    }
    if (data.containsKey('min_stock_level')) {
      context.handle(
        _minStockLevelMeta,
        minStockLevel.isAcceptableOrUnknown(
          data['min_stock_level']!,
          _minStockLevelMeta,
        ),
      );
    }
    if (data.containsKey('track_inventory')) {
      context.handle(
        _trackInventoryMeta,
        trackInventory.isAcceptableOrUnknown(
          data['track_inventory']!,
          _trackInventoryMeta,
        ),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    if (data.containsKey('tax_rate')) {
      context.handle(
        _taxRateMeta,
        taxRate.isAcceptableOrUnknown(data['tax_rate']!, _taxRateMeta),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedProduct map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedProduct(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      sku: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sku'],
      ),
      barcode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}barcode'],
      ),
      sellingPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}selling_price'],
      )!,
      costPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cost_price'],
      ),
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      categoryName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_name'],
      ),
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      ),
      stockQuantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}stock_quantity'],
      ),
      minStockLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}min_stock_level'],
      ),
      trackInventory: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}track_inventory'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      ),
      taxRate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}tax_rate'],
      ),
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $CachedProductsTable createAlias(String alias) {
    return $CachedProductsTable(attachedDatabase, alias);
  }
}

class CachedProduct extends DataClass implements Insertable<CachedProduct> {
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
  final DateTime cachedAt;
  const CachedProduct({
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
    required this.trackInventory,
    required this.isActive,
    this.imageUrl,
    this.taxRate,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || sku != null) {
      map['sku'] = Variable<String>(sku);
    }
    if (!nullToAbsent || barcode != null) {
      map['barcode'] = Variable<String>(barcode);
    }
    map['selling_price'] = Variable<double>(sellingPrice);
    if (!nullToAbsent || costPrice != null) {
      map['cost_price'] = Variable<double>(costPrice);
    }
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    if (!nullToAbsent || categoryName != null) {
      map['category_name'] = Variable<String>(categoryName);
    }
    if (!nullToAbsent || unit != null) {
      map['unit'] = Variable<String>(unit);
    }
    if (!nullToAbsent || stockQuantity != null) {
      map['stock_quantity'] = Variable<double>(stockQuantity);
    }
    if (!nullToAbsent || minStockLevel != null) {
      map['min_stock_level'] = Variable<double>(minStockLevel);
    }
    map['track_inventory'] = Variable<bool>(trackInventory);
    map['is_active'] = Variable<bool>(isActive);
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    if (!nullToAbsent || taxRate != null) {
      map['tax_rate'] = Variable<double>(taxRate);
    }
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedProductsCompanion toCompanion(bool nullToAbsent) {
    return CachedProductsCompanion(
      id: Value(id),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      sku: sku == null && nullToAbsent ? const Value.absent() : Value(sku),
      barcode: barcode == null && nullToAbsent
          ? const Value.absent()
          : Value(barcode),
      sellingPrice: Value(sellingPrice),
      costPrice: costPrice == null && nullToAbsent
          ? const Value.absent()
          : Value(costPrice),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      categoryName: categoryName == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryName),
      unit: unit == null && nullToAbsent ? const Value.absent() : Value(unit),
      stockQuantity: stockQuantity == null && nullToAbsent
          ? const Value.absent()
          : Value(stockQuantity),
      minStockLevel: minStockLevel == null && nullToAbsent
          ? const Value.absent()
          : Value(minStockLevel),
      trackInventory: Value(trackInventory),
      isActive: Value(isActive),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
      taxRate: taxRate == null && nullToAbsent
          ? const Value.absent()
          : Value(taxRate),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedProduct.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedProduct(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      sku: serializer.fromJson<String?>(json['sku']),
      barcode: serializer.fromJson<String?>(json['barcode']),
      sellingPrice: serializer.fromJson<double>(json['sellingPrice']),
      costPrice: serializer.fromJson<double?>(json['costPrice']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      categoryName: serializer.fromJson<String?>(json['categoryName']),
      unit: serializer.fromJson<String?>(json['unit']),
      stockQuantity: serializer.fromJson<double?>(json['stockQuantity']),
      minStockLevel: serializer.fromJson<double?>(json['minStockLevel']),
      trackInventory: serializer.fromJson<bool>(json['trackInventory']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      taxRate: serializer.fromJson<double?>(json['taxRate']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'sku': serializer.toJson<String?>(sku),
      'barcode': serializer.toJson<String?>(barcode),
      'sellingPrice': serializer.toJson<double>(sellingPrice),
      'costPrice': serializer.toJson<double?>(costPrice),
      'categoryId': serializer.toJson<String?>(categoryId),
      'categoryName': serializer.toJson<String?>(categoryName),
      'unit': serializer.toJson<String?>(unit),
      'stockQuantity': serializer.toJson<double?>(stockQuantity),
      'minStockLevel': serializer.toJson<double?>(minStockLevel),
      'trackInventory': serializer.toJson<bool>(trackInventory),
      'isActive': serializer.toJson<bool>(isActive),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'taxRate': serializer.toJson<double?>(taxRate),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedProduct copyWith({
    String? id,
    String? name,
    Value<String?> description = const Value.absent(),
    Value<String?> sku = const Value.absent(),
    Value<String?> barcode = const Value.absent(),
    double? sellingPrice,
    Value<double?> costPrice = const Value.absent(),
    Value<String?> categoryId = const Value.absent(),
    Value<String?> categoryName = const Value.absent(),
    Value<String?> unit = const Value.absent(),
    Value<double?> stockQuantity = const Value.absent(),
    Value<double?> minStockLevel = const Value.absent(),
    bool? trackInventory,
    bool? isActive,
    Value<String?> imageUrl = const Value.absent(),
    Value<double?> taxRate = const Value.absent(),
    DateTime? cachedAt,
  }) => CachedProduct(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    sku: sku.present ? sku.value : this.sku,
    barcode: barcode.present ? barcode.value : this.barcode,
    sellingPrice: sellingPrice ?? this.sellingPrice,
    costPrice: costPrice.present ? costPrice.value : this.costPrice,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    categoryName: categoryName.present ? categoryName.value : this.categoryName,
    unit: unit.present ? unit.value : this.unit,
    stockQuantity: stockQuantity.present
        ? stockQuantity.value
        : this.stockQuantity,
    minStockLevel: minStockLevel.present
        ? minStockLevel.value
        : this.minStockLevel,
    trackInventory: trackInventory ?? this.trackInventory,
    isActive: isActive ?? this.isActive,
    imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
    taxRate: taxRate.present ? taxRate.value : this.taxRate,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  CachedProduct copyWithCompanion(CachedProductsCompanion data) {
    return CachedProduct(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      sku: data.sku.present ? data.sku.value : this.sku,
      barcode: data.barcode.present ? data.barcode.value : this.barcode,
      sellingPrice: data.sellingPrice.present
          ? data.sellingPrice.value
          : this.sellingPrice,
      costPrice: data.costPrice.present ? data.costPrice.value : this.costPrice,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      categoryName: data.categoryName.present
          ? data.categoryName.value
          : this.categoryName,
      unit: data.unit.present ? data.unit.value : this.unit,
      stockQuantity: data.stockQuantity.present
          ? data.stockQuantity.value
          : this.stockQuantity,
      minStockLevel: data.minStockLevel.present
          ? data.minStockLevel.value
          : this.minStockLevel,
      trackInventory: data.trackInventory.present
          ? data.trackInventory.value
          : this.trackInventory,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      taxRate: data.taxRate.present ? data.taxRate.value : this.taxRate,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedProduct(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('sku: $sku, ')
          ..write('barcode: $barcode, ')
          ..write('sellingPrice: $sellingPrice, ')
          ..write('costPrice: $costPrice, ')
          ..write('categoryId: $categoryId, ')
          ..write('categoryName: $categoryName, ')
          ..write('unit: $unit, ')
          ..write('stockQuantity: $stockQuantity, ')
          ..write('minStockLevel: $minStockLevel, ')
          ..write('trackInventory: $trackInventory, ')
          ..write('isActive: $isActive, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('taxRate: $taxRate, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    description,
    sku,
    barcode,
    sellingPrice,
    costPrice,
    categoryId,
    categoryName,
    unit,
    stockQuantity,
    minStockLevel,
    trackInventory,
    isActive,
    imageUrl,
    taxRate,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedProduct &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.sku == this.sku &&
          other.barcode == this.barcode &&
          other.sellingPrice == this.sellingPrice &&
          other.costPrice == this.costPrice &&
          other.categoryId == this.categoryId &&
          other.categoryName == this.categoryName &&
          other.unit == this.unit &&
          other.stockQuantity == this.stockQuantity &&
          other.minStockLevel == this.minStockLevel &&
          other.trackInventory == this.trackInventory &&
          other.isActive == this.isActive &&
          other.imageUrl == this.imageUrl &&
          other.taxRate == this.taxRate &&
          other.cachedAt == this.cachedAt);
}

class CachedProductsCompanion extends UpdateCompanion<CachedProduct> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> description;
  final Value<String?> sku;
  final Value<String?> barcode;
  final Value<double> sellingPrice;
  final Value<double?> costPrice;
  final Value<String?> categoryId;
  final Value<String?> categoryName;
  final Value<String?> unit;
  final Value<double?> stockQuantity;
  final Value<double?> minStockLevel;
  final Value<bool> trackInventory;
  final Value<bool> isActive;
  final Value<String?> imageUrl;
  final Value<double?> taxRate;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const CachedProductsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.sku = const Value.absent(),
    this.barcode = const Value.absent(),
    this.sellingPrice = const Value.absent(),
    this.costPrice = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.categoryName = const Value.absent(),
    this.unit = const Value.absent(),
    this.stockQuantity = const Value.absent(),
    this.minStockLevel = const Value.absent(),
    this.trackInventory = const Value.absent(),
    this.isActive = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.taxRate = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedProductsCompanion.insert({
    required String id,
    required String name,
    this.description = const Value.absent(),
    this.sku = const Value.absent(),
    this.barcode = const Value.absent(),
    required double sellingPrice,
    this.costPrice = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.categoryName = const Value.absent(),
    this.unit = const Value.absent(),
    this.stockQuantity = const Value.absent(),
    this.minStockLevel = const Value.absent(),
    this.trackInventory = const Value.absent(),
    this.isActive = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.taxRate = const Value.absent(),
    required DateTime cachedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       sellingPrice = Value(sellingPrice),
       cachedAt = Value(cachedAt);
  static Insertable<CachedProduct> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? sku,
    Expression<String>? barcode,
    Expression<double>? sellingPrice,
    Expression<double>? costPrice,
    Expression<String>? categoryId,
    Expression<String>? categoryName,
    Expression<String>? unit,
    Expression<double>? stockQuantity,
    Expression<double>? minStockLevel,
    Expression<bool>? trackInventory,
    Expression<bool>? isActive,
    Expression<String>? imageUrl,
    Expression<double>? taxRate,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (sku != null) 'sku': sku,
      if (barcode != null) 'barcode': barcode,
      if (sellingPrice != null) 'selling_price': sellingPrice,
      if (costPrice != null) 'cost_price': costPrice,
      if (categoryId != null) 'category_id': categoryId,
      if (categoryName != null) 'category_name': categoryName,
      if (unit != null) 'unit': unit,
      if (stockQuantity != null) 'stock_quantity': stockQuantity,
      if (minStockLevel != null) 'min_stock_level': minStockLevel,
      if (trackInventory != null) 'track_inventory': trackInventory,
      if (isActive != null) 'is_active': isActive,
      if (imageUrl != null) 'image_url': imageUrl,
      if (taxRate != null) 'tax_rate': taxRate,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedProductsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? description,
    Value<String?>? sku,
    Value<String?>? barcode,
    Value<double>? sellingPrice,
    Value<double?>? costPrice,
    Value<String?>? categoryId,
    Value<String?>? categoryName,
    Value<String?>? unit,
    Value<double?>? stockQuantity,
    Value<double?>? minStockLevel,
    Value<bool>? trackInventory,
    Value<bool>? isActive,
    Value<String?>? imageUrl,
    Value<double?>? taxRate,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return CachedProductsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      costPrice: costPrice ?? this.costPrice,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      unit: unit ?? this.unit,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      minStockLevel: minStockLevel ?? this.minStockLevel,
      trackInventory: trackInventory ?? this.trackInventory,
      isActive: isActive ?? this.isActive,
      imageUrl: imageUrl ?? this.imageUrl,
      taxRate: taxRate ?? this.taxRate,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (sku.present) {
      map['sku'] = Variable<String>(sku.value);
    }
    if (barcode.present) {
      map['barcode'] = Variable<String>(barcode.value);
    }
    if (sellingPrice.present) {
      map['selling_price'] = Variable<double>(sellingPrice.value);
    }
    if (costPrice.present) {
      map['cost_price'] = Variable<double>(costPrice.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (categoryName.present) {
      map['category_name'] = Variable<String>(categoryName.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (stockQuantity.present) {
      map['stock_quantity'] = Variable<double>(stockQuantity.value);
    }
    if (minStockLevel.present) {
      map['min_stock_level'] = Variable<double>(minStockLevel.value);
    }
    if (trackInventory.present) {
      map['track_inventory'] = Variable<bool>(trackInventory.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (taxRate.present) {
      map['tax_rate'] = Variable<double>(taxRate.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedProductsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('sku: $sku, ')
          ..write('barcode: $barcode, ')
          ..write('sellingPrice: $sellingPrice, ')
          ..write('costPrice: $costPrice, ')
          ..write('categoryId: $categoryId, ')
          ..write('categoryName: $categoryName, ')
          ..write('unit: $unit, ')
          ..write('stockQuantity: $stockQuantity, ')
          ..write('minStockLevel: $minStockLevel, ')
          ..write('trackInventory: $trackInventory, ')
          ..write('isActive: $isActive, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('taxRate: $taxRate, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedCategoriesTable extends CachedCategories
    with TableInfo<$CachedCategoriesTable, CachedCategory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedCategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _productCountMeta = const VerificationMeta(
    'productCount',
  );
  @override
  late final GeneratedColumn<int> productCount = GeneratedColumn<int>(
    'product_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    description,
    parentId,
    productCount,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedCategory> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    if (data.containsKey('product_count')) {
      context.handle(
        _productCountMeta,
        productCount.isAcceptableOrUnknown(
          data['product_count']!,
          _productCountMeta,
        ),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedCategory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedCategory(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_id'],
      ),
      productCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}product_count'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $CachedCategoriesTable createAlias(String alias) {
    return $CachedCategoriesTable(attachedDatabase, alias);
  }
}

class CachedCategory extends DataClass implements Insertable<CachedCategory> {
  final String id;
  final String name;
  final String? description;
  final String? parentId;
  final int productCount;
  final DateTime cachedAt;
  const CachedCategory({
    required this.id,
    required this.name,
    this.description,
    this.parentId,
    required this.productCount,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    map['product_count'] = Variable<int>(productCount);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedCategoriesCompanion toCompanion(bool nullToAbsent) {
    return CachedCategoriesCompanion(
      id: Value(id),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      productCount: Value(productCount),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedCategory.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedCategory(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      productCount: serializer.fromJson<int>(json['productCount']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'parentId': serializer.toJson<String?>(parentId),
      'productCount': serializer.toJson<int>(productCount),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedCategory copyWith({
    String? id,
    String? name,
    Value<String?> description = const Value.absent(),
    Value<String?> parentId = const Value.absent(),
    int? productCount,
    DateTime? cachedAt,
  }) => CachedCategory(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    parentId: parentId.present ? parentId.value : this.parentId,
    productCount: productCount ?? this.productCount,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  CachedCategory copyWithCompanion(CachedCategoriesCompanion data) {
    return CachedCategory(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      productCount: data.productCount.present
          ? data.productCount.value
          : this.productCount,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedCategory(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('parentId: $parentId, ')
          ..write('productCount: $productCount, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, description, parentId, productCount, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedCategory &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.parentId == this.parentId &&
          other.productCount == this.productCount &&
          other.cachedAt == this.cachedAt);
}

class CachedCategoriesCompanion extends UpdateCompanion<CachedCategory> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> description;
  final Value<String?> parentId;
  final Value<int> productCount;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const CachedCategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.parentId = const Value.absent(),
    this.productCount = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedCategoriesCompanion.insert({
    required String id,
    required String name,
    this.description = const Value.absent(),
    this.parentId = const Value.absent(),
    this.productCount = const Value.absent(),
    required DateTime cachedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       cachedAt = Value(cachedAt);
  static Insertable<CachedCategory> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? parentId,
    Expression<int>? productCount,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (parentId != null) 'parent_id': parentId,
      if (productCount != null) 'product_count': productCount,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedCategoriesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? description,
    Value<String?>? parentId,
    Value<int>? productCount,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return CachedCategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      parentId: parentId ?? this.parentId,
      productCount: productCount ?? this.productCount,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (productCount.present) {
      map['product_count'] = Variable<int>(productCount.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedCategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('parentId: $parentId, ')
          ..write('productCount: $productCount, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedCustomersTable extends CachedCustomers
    with TableInfo<$CachedCustomersTable, CachedCustomer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedCustomersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _addressMeta = const VerificationMeta(
    'address',
  );
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tinNumberMeta = const VerificationMeta(
    'tinNumber',
  );
  @override
  late final GeneratedColumn<String> tinNumber = GeneratedColumn<String>(
    'tin_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customerTypeMeta = const VerificationMeta(
    'customerType',
  );
  @override
  late final GeneratedColumn<String> customerType = GeneratedColumn<String>(
    'customer_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customerGroupIdMeta = const VerificationMeta(
    'customerGroupId',
  );
  @override
  late final GeneratedColumn<String> customerGroupId = GeneratedColumn<String>(
    'customer_group_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currentBalanceMeta = const VerificationMeta(
    'currentBalance',
  );
  @override
  late final GeneratedColumn<double> currentBalance = GeneratedColumn<double>(
    'current_balance',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _loyaltyPointsMeta = const VerificationMeta(
    'loyaltyPoints',
  );
  @override
  late final GeneratedColumn<int> loyaltyPoints = GeneratedColumn<int>(
    'loyalty_points',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    code,
    name,
    phone,
    email,
    address,
    tinNumber,
    customerType,
    customerGroupId,
    currentBalance,
    loyaltyPoints,
    isActive,
    updatedAt,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_customers';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedCustomer> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('address')) {
      context.handle(
        _addressMeta,
        address.isAcceptableOrUnknown(data['address']!, _addressMeta),
      );
    }
    if (data.containsKey('tin_number')) {
      context.handle(
        _tinNumberMeta,
        tinNumber.isAcceptableOrUnknown(data['tin_number']!, _tinNumberMeta),
      );
    }
    if (data.containsKey('customer_type')) {
      context.handle(
        _customerTypeMeta,
        customerType.isAcceptableOrUnknown(
          data['customer_type']!,
          _customerTypeMeta,
        ),
      );
    }
    if (data.containsKey('customer_group_id')) {
      context.handle(
        _customerGroupIdMeta,
        customerGroupId.isAcceptableOrUnknown(
          data['customer_group_id']!,
          _customerGroupIdMeta,
        ),
      );
    }
    if (data.containsKey('current_balance')) {
      context.handle(
        _currentBalanceMeta,
        currentBalance.isAcceptableOrUnknown(
          data['current_balance']!,
          _currentBalanceMeta,
        ),
      );
    }
    if (data.containsKey('loyalty_points')) {
      context.handle(
        _loyaltyPointsMeta,
        loyaltyPoints.isAcceptableOrUnknown(
          data['loyalty_points']!,
          _loyaltyPointsMeta,
        ),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedCustomer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedCustomer(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      ),
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      ),
      address: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address'],
      ),
      tinNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tin_number'],
      ),
      customerType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_type'],
      ),
      customerGroupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_group_id'],
      ),
      currentBalance: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}current_balance'],
      )!,
      loyaltyPoints: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}loyalty_points'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $CachedCustomersTable createAlias(String alias) {
    return $CachedCustomersTable(attachedDatabase, alias);
  }
}

class CachedCustomer extends DataClass implements Insertable<CachedCustomer> {
  final String id;
  final String? code;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? tinNumber;
  final String? customerType;
  final String? customerGroupId;
  final double currentBalance;
  final int loyaltyPoints;
  final bool isActive;
  final DateTime? updatedAt;
  final DateTime cachedAt;
  const CachedCustomer({
    required this.id,
    this.code,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.tinNumber,
    this.customerType,
    this.customerGroupId,
    required this.currentBalance,
    required this.loyaltyPoints,
    required this.isActive,
    this.updatedAt,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || code != null) {
      map['code'] = Variable<String>(code);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    if (!nullToAbsent || address != null) {
      map['address'] = Variable<String>(address);
    }
    if (!nullToAbsent || tinNumber != null) {
      map['tin_number'] = Variable<String>(tinNumber);
    }
    if (!nullToAbsent || customerType != null) {
      map['customer_type'] = Variable<String>(customerType);
    }
    if (!nullToAbsent || customerGroupId != null) {
      map['customer_group_id'] = Variable<String>(customerGroupId);
    }
    map['current_balance'] = Variable<double>(currentBalance);
    map['loyalty_points'] = Variable<int>(loyaltyPoints);
    map['is_active'] = Variable<bool>(isActive);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedCustomersCompanion toCompanion(bool nullToAbsent) {
    return CachedCustomersCompanion(
      id: Value(id),
      code: code == null && nullToAbsent ? const Value.absent() : Value(code),
      name: Value(name),
      phone: phone == null && nullToAbsent
          ? const Value.absent()
          : Value(phone),
      email: email == null && nullToAbsent
          ? const Value.absent()
          : Value(email),
      address: address == null && nullToAbsent
          ? const Value.absent()
          : Value(address),
      tinNumber: tinNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(tinNumber),
      customerType: customerType == null && nullToAbsent
          ? const Value.absent()
          : Value(customerType),
      customerGroupId: customerGroupId == null && nullToAbsent
          ? const Value.absent()
          : Value(customerGroupId),
      currentBalance: Value(currentBalance),
      loyaltyPoints: Value(loyaltyPoints),
      isActive: Value(isActive),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedCustomer.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedCustomer(
      id: serializer.fromJson<String>(json['id']),
      code: serializer.fromJson<String?>(json['code']),
      name: serializer.fromJson<String>(json['name']),
      phone: serializer.fromJson<String?>(json['phone']),
      email: serializer.fromJson<String?>(json['email']),
      address: serializer.fromJson<String?>(json['address']),
      tinNumber: serializer.fromJson<String?>(json['tinNumber']),
      customerType: serializer.fromJson<String?>(json['customerType']),
      customerGroupId: serializer.fromJson<String?>(json['customerGroupId']),
      currentBalance: serializer.fromJson<double>(json['currentBalance']),
      loyaltyPoints: serializer.fromJson<int>(json['loyaltyPoints']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'code': serializer.toJson<String?>(code),
      'name': serializer.toJson<String>(name),
      'phone': serializer.toJson<String?>(phone),
      'email': serializer.toJson<String?>(email),
      'address': serializer.toJson<String?>(address),
      'tinNumber': serializer.toJson<String?>(tinNumber),
      'customerType': serializer.toJson<String?>(customerType),
      'customerGroupId': serializer.toJson<String?>(customerGroupId),
      'currentBalance': serializer.toJson<double>(currentBalance),
      'loyaltyPoints': serializer.toJson<int>(loyaltyPoints),
      'isActive': serializer.toJson<bool>(isActive),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedCustomer copyWith({
    String? id,
    Value<String?> code = const Value.absent(),
    String? name,
    Value<String?> phone = const Value.absent(),
    Value<String?> email = const Value.absent(),
    Value<String?> address = const Value.absent(),
    Value<String?> tinNumber = const Value.absent(),
    Value<String?> customerType = const Value.absent(),
    Value<String?> customerGroupId = const Value.absent(),
    double? currentBalance,
    int? loyaltyPoints,
    bool? isActive,
    Value<DateTime?> updatedAt = const Value.absent(),
    DateTime? cachedAt,
  }) => CachedCustomer(
    id: id ?? this.id,
    code: code.present ? code.value : this.code,
    name: name ?? this.name,
    phone: phone.present ? phone.value : this.phone,
    email: email.present ? email.value : this.email,
    address: address.present ? address.value : this.address,
    tinNumber: tinNumber.present ? tinNumber.value : this.tinNumber,
    customerType: customerType.present ? customerType.value : this.customerType,
    customerGroupId: customerGroupId.present
        ? customerGroupId.value
        : this.customerGroupId,
    currentBalance: currentBalance ?? this.currentBalance,
    loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
    isActive: isActive ?? this.isActive,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  CachedCustomer copyWithCompanion(CachedCustomersCompanion data) {
    return CachedCustomer(
      id: data.id.present ? data.id.value : this.id,
      code: data.code.present ? data.code.value : this.code,
      name: data.name.present ? data.name.value : this.name,
      phone: data.phone.present ? data.phone.value : this.phone,
      email: data.email.present ? data.email.value : this.email,
      address: data.address.present ? data.address.value : this.address,
      tinNumber: data.tinNumber.present ? data.tinNumber.value : this.tinNumber,
      customerType: data.customerType.present
          ? data.customerType.value
          : this.customerType,
      customerGroupId: data.customerGroupId.present
          ? data.customerGroupId.value
          : this.customerGroupId,
      currentBalance: data.currentBalance.present
          ? data.currentBalance.value
          : this.currentBalance,
      loyaltyPoints: data.loyaltyPoints.present
          ? data.loyaltyPoints.value
          : this.loyaltyPoints,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedCustomer(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('email: $email, ')
          ..write('address: $address, ')
          ..write('tinNumber: $tinNumber, ')
          ..write('customerType: $customerType, ')
          ..write('customerGroupId: $customerGroupId, ')
          ..write('currentBalance: $currentBalance, ')
          ..write('loyaltyPoints: $loyaltyPoints, ')
          ..write('isActive: $isActive, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    code,
    name,
    phone,
    email,
    address,
    tinNumber,
    customerType,
    customerGroupId,
    currentBalance,
    loyaltyPoints,
    isActive,
    updatedAt,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedCustomer &&
          other.id == this.id &&
          other.code == this.code &&
          other.name == this.name &&
          other.phone == this.phone &&
          other.email == this.email &&
          other.address == this.address &&
          other.tinNumber == this.tinNumber &&
          other.customerType == this.customerType &&
          other.customerGroupId == this.customerGroupId &&
          other.currentBalance == this.currentBalance &&
          other.loyaltyPoints == this.loyaltyPoints &&
          other.isActive == this.isActive &&
          other.updatedAt == this.updatedAt &&
          other.cachedAt == this.cachedAt);
}

class CachedCustomersCompanion extends UpdateCompanion<CachedCustomer> {
  final Value<String> id;
  final Value<String?> code;
  final Value<String> name;
  final Value<String?> phone;
  final Value<String?> email;
  final Value<String?> address;
  final Value<String?> tinNumber;
  final Value<String?> customerType;
  final Value<String?> customerGroupId;
  final Value<double> currentBalance;
  final Value<int> loyaltyPoints;
  final Value<bool> isActive;
  final Value<DateTime?> updatedAt;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const CachedCustomersCompanion({
    this.id = const Value.absent(),
    this.code = const Value.absent(),
    this.name = const Value.absent(),
    this.phone = const Value.absent(),
    this.email = const Value.absent(),
    this.address = const Value.absent(),
    this.tinNumber = const Value.absent(),
    this.customerType = const Value.absent(),
    this.customerGroupId = const Value.absent(),
    this.currentBalance = const Value.absent(),
    this.loyaltyPoints = const Value.absent(),
    this.isActive = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedCustomersCompanion.insert({
    required String id,
    this.code = const Value.absent(),
    required String name,
    this.phone = const Value.absent(),
    this.email = const Value.absent(),
    this.address = const Value.absent(),
    this.tinNumber = const Value.absent(),
    this.customerType = const Value.absent(),
    this.customerGroupId = const Value.absent(),
    this.currentBalance = const Value.absent(),
    this.loyaltyPoints = const Value.absent(),
    this.isActive = const Value.absent(),
    this.updatedAt = const Value.absent(),
    required DateTime cachedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       cachedAt = Value(cachedAt);
  static Insertable<CachedCustomer> custom({
    Expression<String>? id,
    Expression<String>? code,
    Expression<String>? name,
    Expression<String>? phone,
    Expression<String>? email,
    Expression<String>? address,
    Expression<String>? tinNumber,
    Expression<String>? customerType,
    Expression<String>? customerGroupId,
    Expression<double>? currentBalance,
    Expression<int>? loyaltyPoints,
    Expression<bool>? isActive,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (code != null) 'code': code,
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (address != null) 'address': address,
      if (tinNumber != null) 'tin_number': tinNumber,
      if (customerType != null) 'customer_type': customerType,
      if (customerGroupId != null) 'customer_group_id': customerGroupId,
      if (currentBalance != null) 'current_balance': currentBalance,
      if (loyaltyPoints != null) 'loyalty_points': loyaltyPoints,
      if (isActive != null) 'is_active': isActive,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedCustomersCompanion copyWith({
    Value<String>? id,
    Value<String?>? code,
    Value<String>? name,
    Value<String?>? phone,
    Value<String?>? email,
    Value<String?>? address,
    Value<String?>? tinNumber,
    Value<String?>? customerType,
    Value<String?>? customerGroupId,
    Value<double>? currentBalance,
    Value<int>? loyaltyPoints,
    Value<bool>? isActive,
    Value<DateTime?>? updatedAt,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return CachedCustomersCompanion(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      tinNumber: tinNumber ?? this.tinNumber,
      customerType: customerType ?? this.customerType,
      customerGroupId: customerGroupId ?? this.customerGroupId,
      currentBalance: currentBalance ?? this.currentBalance,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      isActive: isActive ?? this.isActive,
      updatedAt: updatedAt ?? this.updatedAt,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (tinNumber.present) {
      map['tin_number'] = Variable<String>(tinNumber.value);
    }
    if (customerType.present) {
      map['customer_type'] = Variable<String>(customerType.value);
    }
    if (customerGroupId.present) {
      map['customer_group_id'] = Variable<String>(customerGroupId.value);
    }
    if (currentBalance.present) {
      map['current_balance'] = Variable<double>(currentBalance.value);
    }
    if (loyaltyPoints.present) {
      map['loyalty_points'] = Variable<int>(loyaltyPoints.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedCustomersCompanion(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('email: $email, ')
          ..write('address: $address, ')
          ..write('tinNumber: $tinNumber, ')
          ..write('customerType: $customerType, ')
          ..write('customerGroupId: $customerGroupId, ')
          ..write('currentBalance: $currentBalance, ')
          ..write('loyaltyPoints: $loyaltyPoints, ')
          ..write('isActive: $isActive, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PendingSalesTable extends PendingSales
    with TableInfo<$PendingSalesTable, PendingSale> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingSalesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIdMeta = const VerificationMeta(
    'localId',
  );
  @override
  late final GeneratedColumn<String> localId = GeneratedColumn<String>(
    'local_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
    'client_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _saleJsonMeta = const VerificationMeta(
    'saleJson',
  );
  @override
  late final GeneratedColumn<String> saleJson = GeneratedColumn<String>(
    'sale_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _errorMessageMeta = const VerificationMeta(
    'errorMessage',
  );
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
    'error_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    localId,
    clientId,
    saleJson,
    status,
    errorMessage,
    retryCount,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_sales';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingSale> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_id')) {
      context.handle(
        _localIdMeta,
        localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta),
      );
    } else if (isInserting) {
      context.missing(_localIdMeta);
    }
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
      );
    }
    if (data.containsKey('sale_json')) {
      context.handle(
        _saleJsonMeta,
        saleJson.isAcceptableOrUnknown(data['sale_json']!, _saleJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_saleJsonMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('error_message')) {
      context.handle(
        _errorMessageMeta,
        errorMessage.isAcceptableOrUnknown(
          data['error_message']!,
          _errorMessageMeta,
        ),
      );
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  PendingSale map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingSale(
      localId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_id'],
      )!,
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_id'],
      ),
      saleJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sale_json'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      errorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_message'],
      ),
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PendingSalesTable createAlias(String alias) {
    return $PendingSalesTable(attachedDatabase, alias);
  }
}

class PendingSale extends DataClass implements Insertable<PendingSale> {
  final String localId;
  final String? clientId;
  final String saleJson;
  final String status;
  final String? errorMessage;
  final int retryCount;
  final DateTime createdAt;
  const PendingSale({
    required this.localId,
    this.clientId,
    required this.saleJson,
    required this.status,
    this.errorMessage,
    required this.retryCount,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<String>(localId);
    if (!nullToAbsent || clientId != null) {
      map['client_id'] = Variable<String>(clientId);
    }
    map['sale_json'] = Variable<String>(saleJson);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    map['retry_count'] = Variable<int>(retryCount);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PendingSalesCompanion toCompanion(bool nullToAbsent) {
    return PendingSalesCompanion(
      localId: Value(localId),
      clientId: clientId == null && nullToAbsent
          ? const Value.absent()
          : Value(clientId),
      saleJson: Value(saleJson),
      status: Value(status),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
      retryCount: Value(retryCount),
      createdAt: Value(createdAt),
    );
  }

  factory PendingSale.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingSale(
      localId: serializer.fromJson<String>(json['localId']),
      clientId: serializer.fromJson<String?>(json['clientId']),
      saleJson: serializer.fromJson<String>(json['saleJson']),
      status: serializer.fromJson<String>(json['status']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localId': serializer.toJson<String>(localId),
      'clientId': serializer.toJson<String?>(clientId),
      'saleJson': serializer.toJson<String>(saleJson),
      'status': serializer.toJson<String>(status),
      'errorMessage': serializer.toJson<String?>(errorMessage),
      'retryCount': serializer.toJson<int>(retryCount),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  PendingSale copyWith({
    String? localId,
    Value<String?> clientId = const Value.absent(),
    String? saleJson,
    String? status,
    Value<String?> errorMessage = const Value.absent(),
    int? retryCount,
    DateTime? createdAt,
  }) => PendingSale(
    localId: localId ?? this.localId,
    clientId: clientId.present ? clientId.value : this.clientId,
    saleJson: saleJson ?? this.saleJson,
    status: status ?? this.status,
    errorMessage: errorMessage.present ? errorMessage.value : this.errorMessage,
    retryCount: retryCount ?? this.retryCount,
    createdAt: createdAt ?? this.createdAt,
  );
  PendingSale copyWithCompanion(PendingSalesCompanion data) {
    return PendingSale(
      localId: data.localId.present ? data.localId.value : this.localId,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      saleJson: data.saleJson.present ? data.saleJson.value : this.saleJson,
      status: data.status.present ? data.status.value : this.status,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingSale(')
          ..write('localId: $localId, ')
          ..write('clientId: $clientId, ')
          ..write('saleJson: $saleJson, ')
          ..write('status: $status, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('retryCount: $retryCount, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    localId,
    clientId,
    saleJson,
    status,
    errorMessage,
    retryCount,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingSale &&
          other.localId == this.localId &&
          other.clientId == this.clientId &&
          other.saleJson == this.saleJson &&
          other.status == this.status &&
          other.errorMessage == this.errorMessage &&
          other.retryCount == this.retryCount &&
          other.createdAt == this.createdAt);
}

class PendingSalesCompanion extends UpdateCompanion<PendingSale> {
  final Value<String> localId;
  final Value<String?> clientId;
  final Value<String> saleJson;
  final Value<String> status;
  final Value<String?> errorMessage;
  final Value<int> retryCount;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const PendingSalesCompanion({
    this.localId = const Value.absent(),
    this.clientId = const Value.absent(),
    this.saleJson = const Value.absent(),
    this.status = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PendingSalesCompanion.insert({
    required String localId,
    this.clientId = const Value.absent(),
    required String saleJson,
    this.status = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.retryCount = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : localId = Value(localId),
       saleJson = Value(saleJson),
       createdAt = Value(createdAt);
  static Insertable<PendingSale> custom({
    Expression<String>? localId,
    Expression<String>? clientId,
    Expression<String>? saleJson,
    Expression<String>? status,
    Expression<String>? errorMessage,
    Expression<int>? retryCount,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (clientId != null) 'client_id': clientId,
      if (saleJson != null) 'sale_json': saleJson,
      if (status != null) 'status': status,
      if (errorMessage != null) 'error_message': errorMessage,
      if (retryCount != null) 'retry_count': retryCount,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PendingSalesCompanion copyWith({
    Value<String>? localId,
    Value<String?>? clientId,
    Value<String>? saleJson,
    Value<String>? status,
    Value<String?>? errorMessage,
    Value<int>? retryCount,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return PendingSalesCompanion(
      localId: localId ?? this.localId,
      clientId: clientId ?? this.clientId,
      saleJson: saleJson ?? this.saleJson,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      retryCount: retryCount ?? this.retryCount,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localId.present) {
      map['local_id'] = Variable<String>(localId.value);
    }
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (saleJson.present) {
      map['sale_json'] = Variable<String>(saleJson.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingSalesCompanion(')
          ..write('localId: $localId, ')
          ..write('clientId: $clientId, ')
          ..write('saleJson: $saleJson, ')
          ..write('status: $status, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('retryCount: $retryCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PendingLaundryActionsTable extends PendingLaundryActions
    with TableInfo<$PendingLaundryActionsTable, PendingLaundryAction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingLaundryActionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIdMeta = const VerificationMeta(
    'localId',
  );
  @override
  late final GeneratedColumn<String> localId = GeneratedColumn<String>(
    'local_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clientOpIdMeta = const VerificationMeta(
    'clientOpId',
  );
  @override
  late final GeneratedColumn<String> clientOpId = GeneratedColumn<String>(
    'client_op_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actionTypeMeta = const VerificationMeta(
    'actionType',
  );
  @override
  late final GeneratedColumn<String> actionType = GeneratedColumn<String>(
    'action_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _orderIdMeta = const VerificationMeta(
    'orderId',
  );
  @override
  late final GeneratedColumn<String> orderId = GeneratedColumn<String>(
    'order_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _errorMessageMeta = const VerificationMeta(
    'errorMessage',
  );
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
    'error_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    localId,
    clientOpId,
    actionType,
    orderId,
    payloadJson,
    status,
    errorMessage,
    retryCount,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_laundry_actions';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingLaundryAction> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_id')) {
      context.handle(
        _localIdMeta,
        localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta),
      );
    } else if (isInserting) {
      context.missing(_localIdMeta);
    }
    if (data.containsKey('client_op_id')) {
      context.handle(
        _clientOpIdMeta,
        clientOpId.isAcceptableOrUnknown(
          data['client_op_id']!,
          _clientOpIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clientOpIdMeta);
    }
    if (data.containsKey('action_type')) {
      context.handle(
        _actionTypeMeta,
        actionType.isAcceptableOrUnknown(data['action_type']!, _actionTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_actionTypeMeta);
    }
    if (data.containsKey('order_id')) {
      context.handle(
        _orderIdMeta,
        orderId.isAcceptableOrUnknown(data['order_id']!, _orderIdMeta),
      );
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('error_message')) {
      context.handle(
        _errorMessageMeta,
        errorMessage.isAcceptableOrUnknown(
          data['error_message']!,
          _errorMessageMeta,
        ),
      );
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  PendingLaundryAction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingLaundryAction(
      localId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_id'],
      )!,
      clientOpId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_op_id'],
      )!,
      actionType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action_type'],
      )!,
      orderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}order_id'],
      ),
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      errorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_message'],
      ),
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PendingLaundryActionsTable createAlias(String alias) {
    return $PendingLaundryActionsTable(attachedDatabase, alias);
  }
}

class PendingLaundryAction extends DataClass
    implements Insertable<PendingLaundryAction> {
  final String localId;
  final String clientOpId;
  final String actionType;
  final String? orderId;
  final String payloadJson;
  final String status;
  final String? errorMessage;
  final int retryCount;
  final DateTime createdAt;
  const PendingLaundryAction({
    required this.localId,
    required this.clientOpId,
    required this.actionType,
    this.orderId,
    required this.payloadJson,
    required this.status,
    this.errorMessage,
    required this.retryCount,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<String>(localId);
    map['client_op_id'] = Variable<String>(clientOpId);
    map['action_type'] = Variable<String>(actionType);
    if (!nullToAbsent || orderId != null) {
      map['order_id'] = Variable<String>(orderId);
    }
    map['payload_json'] = Variable<String>(payloadJson);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    map['retry_count'] = Variable<int>(retryCount);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PendingLaundryActionsCompanion toCompanion(bool nullToAbsent) {
    return PendingLaundryActionsCompanion(
      localId: Value(localId),
      clientOpId: Value(clientOpId),
      actionType: Value(actionType),
      orderId: orderId == null && nullToAbsent
          ? const Value.absent()
          : Value(orderId),
      payloadJson: Value(payloadJson),
      status: Value(status),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
      retryCount: Value(retryCount),
      createdAt: Value(createdAt),
    );
  }

  factory PendingLaundryAction.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingLaundryAction(
      localId: serializer.fromJson<String>(json['localId']),
      clientOpId: serializer.fromJson<String>(json['clientOpId']),
      actionType: serializer.fromJson<String>(json['actionType']),
      orderId: serializer.fromJson<String?>(json['orderId']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      status: serializer.fromJson<String>(json['status']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localId': serializer.toJson<String>(localId),
      'clientOpId': serializer.toJson<String>(clientOpId),
      'actionType': serializer.toJson<String>(actionType),
      'orderId': serializer.toJson<String?>(orderId),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'status': serializer.toJson<String>(status),
      'errorMessage': serializer.toJson<String?>(errorMessage),
      'retryCount': serializer.toJson<int>(retryCount),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  PendingLaundryAction copyWith({
    String? localId,
    String? clientOpId,
    String? actionType,
    Value<String?> orderId = const Value.absent(),
    String? payloadJson,
    String? status,
    Value<String?> errorMessage = const Value.absent(),
    int? retryCount,
    DateTime? createdAt,
  }) => PendingLaundryAction(
    localId: localId ?? this.localId,
    clientOpId: clientOpId ?? this.clientOpId,
    actionType: actionType ?? this.actionType,
    orderId: orderId.present ? orderId.value : this.orderId,
    payloadJson: payloadJson ?? this.payloadJson,
    status: status ?? this.status,
    errorMessage: errorMessage.present ? errorMessage.value : this.errorMessage,
    retryCount: retryCount ?? this.retryCount,
    createdAt: createdAt ?? this.createdAt,
  );
  PendingLaundryAction copyWithCompanion(PendingLaundryActionsCompanion data) {
    return PendingLaundryAction(
      localId: data.localId.present ? data.localId.value : this.localId,
      clientOpId: data.clientOpId.present
          ? data.clientOpId.value
          : this.clientOpId,
      actionType: data.actionType.present
          ? data.actionType.value
          : this.actionType,
      orderId: data.orderId.present ? data.orderId.value : this.orderId,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      status: data.status.present ? data.status.value : this.status,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingLaundryAction(')
          ..write('localId: $localId, ')
          ..write('clientOpId: $clientOpId, ')
          ..write('actionType: $actionType, ')
          ..write('orderId: $orderId, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('status: $status, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('retryCount: $retryCount, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    localId,
    clientOpId,
    actionType,
    orderId,
    payloadJson,
    status,
    errorMessage,
    retryCount,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingLaundryAction &&
          other.localId == this.localId &&
          other.clientOpId == this.clientOpId &&
          other.actionType == this.actionType &&
          other.orderId == this.orderId &&
          other.payloadJson == this.payloadJson &&
          other.status == this.status &&
          other.errorMessage == this.errorMessage &&
          other.retryCount == this.retryCount &&
          other.createdAt == this.createdAt);
}

class PendingLaundryActionsCompanion
    extends UpdateCompanion<PendingLaundryAction> {
  final Value<String> localId;
  final Value<String> clientOpId;
  final Value<String> actionType;
  final Value<String?> orderId;
  final Value<String> payloadJson;
  final Value<String> status;
  final Value<String?> errorMessage;
  final Value<int> retryCount;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const PendingLaundryActionsCompanion({
    this.localId = const Value.absent(),
    this.clientOpId = const Value.absent(),
    this.actionType = const Value.absent(),
    this.orderId = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.status = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PendingLaundryActionsCompanion.insert({
    required String localId,
    required String clientOpId,
    required String actionType,
    this.orderId = const Value.absent(),
    required String payloadJson,
    this.status = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.retryCount = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : localId = Value(localId),
       clientOpId = Value(clientOpId),
       actionType = Value(actionType),
       payloadJson = Value(payloadJson),
       createdAt = Value(createdAt);
  static Insertable<PendingLaundryAction> custom({
    Expression<String>? localId,
    Expression<String>? clientOpId,
    Expression<String>? actionType,
    Expression<String>? orderId,
    Expression<String>? payloadJson,
    Expression<String>? status,
    Expression<String>? errorMessage,
    Expression<int>? retryCount,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (clientOpId != null) 'client_op_id': clientOpId,
      if (actionType != null) 'action_type': actionType,
      if (orderId != null) 'order_id': orderId,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (status != null) 'status': status,
      if (errorMessage != null) 'error_message': errorMessage,
      if (retryCount != null) 'retry_count': retryCount,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PendingLaundryActionsCompanion copyWith({
    Value<String>? localId,
    Value<String>? clientOpId,
    Value<String>? actionType,
    Value<String?>? orderId,
    Value<String>? payloadJson,
    Value<String>? status,
    Value<String?>? errorMessage,
    Value<int>? retryCount,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return PendingLaundryActionsCompanion(
      localId: localId ?? this.localId,
      clientOpId: clientOpId ?? this.clientOpId,
      actionType: actionType ?? this.actionType,
      orderId: orderId ?? this.orderId,
      payloadJson: payloadJson ?? this.payloadJson,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      retryCount: retryCount ?? this.retryCount,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localId.present) {
      map['local_id'] = Variable<String>(localId.value);
    }
    if (clientOpId.present) {
      map['client_op_id'] = Variable<String>(clientOpId.value);
    }
    if (actionType.present) {
      map['action_type'] = Variable<String>(actionType.value);
    }
    if (orderId.present) {
      map['order_id'] = Variable<String>(orderId.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingLaundryActionsCompanion(')
          ..write('localId: $localId, ')
          ..write('clientOpId: $clientOpId, ')
          ..write('actionType: $actionType, ')
          ..write('orderId: $orderId, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('status: $status, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('retryCount: $retryCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedSessionsTable extends CachedSessions
    with TableInfo<$CachedSessionsTable, CachedSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionJsonMeta = const VerificationMeta(
    'sessionJson',
  );
  @override
  late final GeneratedColumn<String> sessionJson = GeneratedColumn<String>(
    'session_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, sessionJson, cachedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedSession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('session_json')) {
      context.handle(
        _sessionJsonMeta,
        sessionJson.isAcceptableOrUnknown(
          data['session_json']!,
          _sessionJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sessionJsonMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedSession(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sessionJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_json'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $CachedSessionsTable createAlias(String alias) {
    return $CachedSessionsTable(attachedDatabase, alias);
  }
}

class CachedSession extends DataClass implements Insertable<CachedSession> {
  final String id;
  final String sessionJson;
  final DateTime cachedAt;
  const CachedSession({
    required this.id,
    required this.sessionJson,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['session_json'] = Variable<String>(sessionJson);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedSessionsCompanion toCompanion(bool nullToAbsent) {
    return CachedSessionsCompanion(
      id: Value(id),
      sessionJson: Value(sessionJson),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedSession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedSession(
      id: serializer.fromJson<String>(json['id']),
      sessionJson: serializer.fromJson<String>(json['sessionJson']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sessionJson': serializer.toJson<String>(sessionJson),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedSession copyWith({
    String? id,
    String? sessionJson,
    DateTime? cachedAt,
  }) => CachedSession(
    id: id ?? this.id,
    sessionJson: sessionJson ?? this.sessionJson,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  CachedSession copyWithCompanion(CachedSessionsCompanion data) {
    return CachedSession(
      id: data.id.present ? data.id.value : this.id,
      sessionJson: data.sessionJson.present
          ? data.sessionJson.value
          : this.sessionJson,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedSession(')
          ..write('id: $id, ')
          ..write('sessionJson: $sessionJson, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, sessionJson, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedSession &&
          other.id == this.id &&
          other.sessionJson == this.sessionJson &&
          other.cachedAt == this.cachedAt);
}

class CachedSessionsCompanion extends UpdateCompanion<CachedSession> {
  final Value<String> id;
  final Value<String> sessionJson;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const CachedSessionsCompanion({
    this.id = const Value.absent(),
    this.sessionJson = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedSessionsCompanion.insert({
    required String id,
    required String sessionJson,
    required DateTime cachedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sessionJson = Value(sessionJson),
       cachedAt = Value(cachedAt);
  static Insertable<CachedSession> custom({
    Expression<String>? id,
    Expression<String>? sessionJson,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionJson != null) 'session_json': sessionJson,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedSessionsCompanion copyWith({
    Value<String>? id,
    Value<String>? sessionJson,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return CachedSessionsCompanion(
      id: id ?? this.id,
      sessionJson: sessionJson ?? this.sessionJson,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sessionJson.present) {
      map['session_json'] = Variable<String>(sessionJson.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedSessionsCompanion(')
          ..write('id: $id, ')
          ..write('sessionJson: $sessionJson, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncMetaTable extends SyncMeta
    with TableInfo<$SyncMetaTable, SyncMetaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncMetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncMetaData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SyncMetaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncMetaData(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SyncMetaTable createAlias(String alias) {
    return $SyncMetaTable(attachedDatabase, alias);
  }
}

class SyncMetaData extends DataClass implements Insertable<SyncMetaData> {
  final String key;
  final String? value;
  final DateTime updatedAt;
  const SyncMetaData({required this.key, this.value, required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    if (!nullToAbsent || value != null) {
      map['value'] = Variable<String>(value);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SyncMetaCompanion toCompanion(bool nullToAbsent) {
    return SyncMetaCompanion(
      key: Value(key),
      value: value == null && nullToAbsent
          ? const Value.absent()
          : Value(value),
      updatedAt: Value(updatedAt),
    );
  }

  factory SyncMetaData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncMetaData(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String?>(json['value']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String?>(value),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SyncMetaData copyWith({
    String? key,
    Value<String?> value = const Value.absent(),
    DateTime? updatedAt,
  }) => SyncMetaData(
    key: key ?? this.key,
    value: value.present ? value.value : this.value,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SyncMetaData copyWithCompanion(SyncMetaCompanion data) {
    return SyncMetaData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetaData(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncMetaData &&
          other.key == this.key &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt);
}

class SyncMetaCompanion extends UpdateCompanion<SyncMetaData> {
  final Value<String> key;
  final Value<String?> value;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SyncMetaCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncMetaCompanion.insert({
    required String key,
    this.value = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       updatedAt = Value(updatedAt);
  static Insertable<SyncMetaData> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncMetaCompanion copyWith({
    Value<String>? key,
    Value<String?>? value,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return SyncMetaCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetaCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CachedProductsTable cachedProducts = $CachedProductsTable(this);
  late final $CachedCategoriesTable cachedCategories = $CachedCategoriesTable(
    this,
  );
  late final $CachedCustomersTable cachedCustomers = $CachedCustomersTable(
    this,
  );
  late final $PendingSalesTable pendingSales = $PendingSalesTable(this);
  late final $PendingLaundryActionsTable pendingLaundryActions =
      $PendingLaundryActionsTable(this);
  late final $CachedSessionsTable cachedSessions = $CachedSessionsTable(this);
  late final $SyncMetaTable syncMeta = $SyncMetaTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    cachedProducts,
    cachedCategories,
    cachedCustomers,
    pendingSales,
    pendingLaundryActions,
    cachedSessions,
    syncMeta,
  ];
}

typedef $$CachedProductsTableCreateCompanionBuilder =
    CachedProductsCompanion Function({
      required String id,
      required String name,
      Value<String?> description,
      Value<String?> sku,
      Value<String?> barcode,
      required double sellingPrice,
      Value<double?> costPrice,
      Value<String?> categoryId,
      Value<String?> categoryName,
      Value<String?> unit,
      Value<double?> stockQuantity,
      Value<double?> minStockLevel,
      Value<bool> trackInventory,
      Value<bool> isActive,
      Value<String?> imageUrl,
      Value<double?> taxRate,
      required DateTime cachedAt,
      Value<int> rowid,
    });
typedef $$CachedProductsTableUpdateCompanionBuilder =
    CachedProductsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> description,
      Value<String?> sku,
      Value<String?> barcode,
      Value<double> sellingPrice,
      Value<double?> costPrice,
      Value<String?> categoryId,
      Value<String?> categoryName,
      Value<String?> unit,
      Value<double?> stockQuantity,
      Value<double?> minStockLevel,
      Value<bool> trackInventory,
      Value<bool> isActive,
      Value<String?> imageUrl,
      Value<double?> taxRate,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

class $$CachedProductsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedProductsTable> {
  $$CachedProductsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sku => $composableBuilder(
    column: $table.sku,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sellingPrice => $composableBuilder(
    column: $table.sellingPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get costPrice => $composableBuilder(
    column: $table.costPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryName => $composableBuilder(
    column: $table.categoryName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get stockQuantity => $composableBuilder(
    column: $table.stockQuantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get minStockLevel => $composableBuilder(
    column: $table.minStockLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get trackInventory => $composableBuilder(
    column: $table.trackInventory,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get taxRate => $composableBuilder(
    column: $table.taxRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedProductsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedProductsTable> {
  $$CachedProductsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sku => $composableBuilder(
    column: $table.sku,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sellingPrice => $composableBuilder(
    column: $table.sellingPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get costPrice => $composableBuilder(
    column: $table.costPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryName => $composableBuilder(
    column: $table.categoryName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get stockQuantity => $composableBuilder(
    column: $table.stockQuantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get minStockLevel => $composableBuilder(
    column: $table.minStockLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get trackInventory => $composableBuilder(
    column: $table.trackInventory,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get taxRate => $composableBuilder(
    column: $table.taxRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedProductsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedProductsTable> {
  $$CachedProductsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sku =>
      $composableBuilder(column: $table.sku, builder: (column) => column);

  GeneratedColumn<String> get barcode =>
      $composableBuilder(column: $table.barcode, builder: (column) => column);

  GeneratedColumn<double> get sellingPrice => $composableBuilder(
    column: $table.sellingPrice,
    builder: (column) => column,
  );

  GeneratedColumn<double> get costPrice =>
      $composableBuilder(column: $table.costPrice, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get categoryName => $composableBuilder(
    column: $table.categoryName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<double> get stockQuantity => $composableBuilder(
    column: $table.stockQuantity,
    builder: (column) => column,
  );

  GeneratedColumn<double> get minStockLevel => $composableBuilder(
    column: $table.minStockLevel,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get trackInventory => $composableBuilder(
    column: $table.trackInventory,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<double> get taxRate =>
      $composableBuilder(column: $table.taxRate, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$CachedProductsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedProductsTable,
          CachedProduct,
          $$CachedProductsTableFilterComposer,
          $$CachedProductsTableOrderingComposer,
          $$CachedProductsTableAnnotationComposer,
          $$CachedProductsTableCreateCompanionBuilder,
          $$CachedProductsTableUpdateCompanionBuilder,
          (
            CachedProduct,
            BaseReferences<_$AppDatabase, $CachedProductsTable, CachedProduct>,
          ),
          CachedProduct,
          PrefetchHooks Function()
        > {
  $$CachedProductsTableTableManager(
    _$AppDatabase db,
    $CachedProductsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedProductsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedProductsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedProductsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> sku = const Value.absent(),
                Value<String?> barcode = const Value.absent(),
                Value<double> sellingPrice = const Value.absent(),
                Value<double?> costPrice = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String?> categoryName = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<double?> stockQuantity = const Value.absent(),
                Value<double?> minStockLevel = const Value.absent(),
                Value<bool> trackInventory = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<double?> taxRate = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedProductsCompanion(
                id: id,
                name: name,
                description: description,
                sku: sku,
                barcode: barcode,
                sellingPrice: sellingPrice,
                costPrice: costPrice,
                categoryId: categoryId,
                categoryName: categoryName,
                unit: unit,
                stockQuantity: stockQuantity,
                minStockLevel: minStockLevel,
                trackInventory: trackInventory,
                isActive: isActive,
                imageUrl: imageUrl,
                taxRate: taxRate,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> description = const Value.absent(),
                Value<String?> sku = const Value.absent(),
                Value<String?> barcode = const Value.absent(),
                required double sellingPrice,
                Value<double?> costPrice = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String?> categoryName = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<double?> stockQuantity = const Value.absent(),
                Value<double?> minStockLevel = const Value.absent(),
                Value<bool> trackInventory = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<double?> taxRate = const Value.absent(),
                required DateTime cachedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedProductsCompanion.insert(
                id: id,
                name: name,
                description: description,
                sku: sku,
                barcode: barcode,
                sellingPrice: sellingPrice,
                costPrice: costPrice,
                categoryId: categoryId,
                categoryName: categoryName,
                unit: unit,
                stockQuantity: stockQuantity,
                minStockLevel: minStockLevel,
                trackInventory: trackInventory,
                isActive: isActive,
                imageUrl: imageUrl,
                taxRate: taxRate,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedProductsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedProductsTable,
      CachedProduct,
      $$CachedProductsTableFilterComposer,
      $$CachedProductsTableOrderingComposer,
      $$CachedProductsTableAnnotationComposer,
      $$CachedProductsTableCreateCompanionBuilder,
      $$CachedProductsTableUpdateCompanionBuilder,
      (
        CachedProduct,
        BaseReferences<_$AppDatabase, $CachedProductsTable, CachedProduct>,
      ),
      CachedProduct,
      PrefetchHooks Function()
    >;
typedef $$CachedCategoriesTableCreateCompanionBuilder =
    CachedCategoriesCompanion Function({
      required String id,
      required String name,
      Value<String?> description,
      Value<String?> parentId,
      Value<int> productCount,
      required DateTime cachedAt,
      Value<int> rowid,
    });
typedef $$CachedCategoriesTableUpdateCompanionBuilder =
    CachedCategoriesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> description,
      Value<String?> parentId,
      Value<int> productCount,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

class $$CachedCategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CachedCategoriesTable> {
  $$CachedCategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get productCount => $composableBuilder(
    column: $table.productCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedCategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedCategoriesTable> {
  $$CachedCategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get productCount => $composableBuilder(
    column: $table.productCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedCategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedCategoriesTable> {
  $$CachedCategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get parentId =>
      $composableBuilder(column: $table.parentId, builder: (column) => column);

  GeneratedColumn<int> get productCount => $composableBuilder(
    column: $table.productCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$CachedCategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedCategoriesTable,
          CachedCategory,
          $$CachedCategoriesTableFilterComposer,
          $$CachedCategoriesTableOrderingComposer,
          $$CachedCategoriesTableAnnotationComposer,
          $$CachedCategoriesTableCreateCompanionBuilder,
          $$CachedCategoriesTableUpdateCompanionBuilder,
          (
            CachedCategory,
            BaseReferences<
              _$AppDatabase,
              $CachedCategoriesTable,
              CachedCategory
            >,
          ),
          CachedCategory,
          PrefetchHooks Function()
        > {
  $$CachedCategoriesTableTableManager(
    _$AppDatabase db,
    $CachedCategoriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedCategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedCategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedCategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<int> productCount = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedCategoriesCompanion(
                id: id,
                name: name,
                description: description,
                parentId: parentId,
                productCount: productCount,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> description = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<int> productCount = const Value.absent(),
                required DateTime cachedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedCategoriesCompanion.insert(
                id: id,
                name: name,
                description: description,
                parentId: parentId,
                productCount: productCount,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedCategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedCategoriesTable,
      CachedCategory,
      $$CachedCategoriesTableFilterComposer,
      $$CachedCategoriesTableOrderingComposer,
      $$CachedCategoriesTableAnnotationComposer,
      $$CachedCategoriesTableCreateCompanionBuilder,
      $$CachedCategoriesTableUpdateCompanionBuilder,
      (
        CachedCategory,
        BaseReferences<_$AppDatabase, $CachedCategoriesTable, CachedCategory>,
      ),
      CachedCategory,
      PrefetchHooks Function()
    >;
typedef $$CachedCustomersTableCreateCompanionBuilder =
    CachedCustomersCompanion Function({
      required String id,
      Value<String?> code,
      required String name,
      Value<String?> phone,
      Value<String?> email,
      Value<String?> address,
      Value<String?> tinNumber,
      Value<String?> customerType,
      Value<String?> customerGroupId,
      Value<double> currentBalance,
      Value<int> loyaltyPoints,
      Value<bool> isActive,
      Value<DateTime?> updatedAt,
      required DateTime cachedAt,
      Value<int> rowid,
    });
typedef $$CachedCustomersTableUpdateCompanionBuilder =
    CachedCustomersCompanion Function({
      Value<String> id,
      Value<String?> code,
      Value<String> name,
      Value<String?> phone,
      Value<String?> email,
      Value<String?> address,
      Value<String?> tinNumber,
      Value<String?> customerType,
      Value<String?> customerGroupId,
      Value<double> currentBalance,
      Value<int> loyaltyPoints,
      Value<bool> isActive,
      Value<DateTime?> updatedAt,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

class $$CachedCustomersTableFilterComposer
    extends Composer<_$AppDatabase, $CachedCustomersTable> {
  $$CachedCustomersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tinNumber => $composableBuilder(
    column: $table.tinNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerType => $composableBuilder(
    column: $table.customerType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerGroupId => $composableBuilder(
    column: $table.customerGroupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get currentBalance => $composableBuilder(
    column: $table.currentBalance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get loyaltyPoints => $composableBuilder(
    column: $table.loyaltyPoints,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedCustomersTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedCustomersTable> {
  $$CachedCustomersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tinNumber => $composableBuilder(
    column: $table.tinNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerType => $composableBuilder(
    column: $table.customerType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerGroupId => $composableBuilder(
    column: $table.customerGroupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get currentBalance => $composableBuilder(
    column: $table.currentBalance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get loyaltyPoints => $composableBuilder(
    column: $table.loyaltyPoints,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedCustomersTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedCustomersTable> {
  $$CachedCustomersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<String> get tinNumber =>
      $composableBuilder(column: $table.tinNumber, builder: (column) => column);

  GeneratedColumn<String> get customerType => $composableBuilder(
    column: $table.customerType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customerGroupId => $composableBuilder(
    column: $table.customerGroupId,
    builder: (column) => column,
  );

  GeneratedColumn<double> get currentBalance => $composableBuilder(
    column: $table.currentBalance,
    builder: (column) => column,
  );

  GeneratedColumn<int> get loyaltyPoints => $composableBuilder(
    column: $table.loyaltyPoints,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$CachedCustomersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedCustomersTable,
          CachedCustomer,
          $$CachedCustomersTableFilterComposer,
          $$CachedCustomersTableOrderingComposer,
          $$CachedCustomersTableAnnotationComposer,
          $$CachedCustomersTableCreateCompanionBuilder,
          $$CachedCustomersTableUpdateCompanionBuilder,
          (
            CachedCustomer,
            BaseReferences<
              _$AppDatabase,
              $CachedCustomersTable,
              CachedCustomer
            >,
          ),
          CachedCustomer,
          PrefetchHooks Function()
        > {
  $$CachedCustomersTableTableManager(
    _$AppDatabase db,
    $CachedCustomersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedCustomersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedCustomersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedCustomersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> code = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String?> address = const Value.absent(),
                Value<String?> tinNumber = const Value.absent(),
                Value<String?> customerType = const Value.absent(),
                Value<String?> customerGroupId = const Value.absent(),
                Value<double> currentBalance = const Value.absent(),
                Value<int> loyaltyPoints = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedCustomersCompanion(
                id: id,
                code: code,
                name: name,
                phone: phone,
                email: email,
                address: address,
                tinNumber: tinNumber,
                customerType: customerType,
                customerGroupId: customerGroupId,
                currentBalance: currentBalance,
                loyaltyPoints: loyaltyPoints,
                isActive: isActive,
                updatedAt: updatedAt,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> code = const Value.absent(),
                required String name,
                Value<String?> phone = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String?> address = const Value.absent(),
                Value<String?> tinNumber = const Value.absent(),
                Value<String?> customerType = const Value.absent(),
                Value<String?> customerGroupId = const Value.absent(),
                Value<double> currentBalance = const Value.absent(),
                Value<int> loyaltyPoints = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                required DateTime cachedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedCustomersCompanion.insert(
                id: id,
                code: code,
                name: name,
                phone: phone,
                email: email,
                address: address,
                tinNumber: tinNumber,
                customerType: customerType,
                customerGroupId: customerGroupId,
                currentBalance: currentBalance,
                loyaltyPoints: loyaltyPoints,
                isActive: isActive,
                updatedAt: updatedAt,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedCustomersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedCustomersTable,
      CachedCustomer,
      $$CachedCustomersTableFilterComposer,
      $$CachedCustomersTableOrderingComposer,
      $$CachedCustomersTableAnnotationComposer,
      $$CachedCustomersTableCreateCompanionBuilder,
      $$CachedCustomersTableUpdateCompanionBuilder,
      (
        CachedCustomer,
        BaseReferences<_$AppDatabase, $CachedCustomersTable, CachedCustomer>,
      ),
      CachedCustomer,
      PrefetchHooks Function()
    >;
typedef $$PendingSalesTableCreateCompanionBuilder =
    PendingSalesCompanion Function({
      required String localId,
      Value<String?> clientId,
      required String saleJson,
      Value<String> status,
      Value<String?> errorMessage,
      Value<int> retryCount,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$PendingSalesTableUpdateCompanionBuilder =
    PendingSalesCompanion Function({
      Value<String> localId,
      Value<String?> clientId,
      Value<String> saleJson,
      Value<String> status,
      Value<String?> errorMessage,
      Value<int> retryCount,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$PendingSalesTableFilterComposer
    extends Composer<_$AppDatabase, $PendingSalesTable> {
  $$PendingSalesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get saleJson => $composableBuilder(
    column: $table.saleJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PendingSalesTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingSalesTable> {
  $$PendingSalesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get saleJson => $composableBuilder(
    column: $table.saleJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingSalesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingSalesTable> {
  $$PendingSalesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<String> get clientId =>
      $composableBuilder(column: $table.clientId, builder: (column) => column);

  GeneratedColumn<String> get saleJson =>
      $composableBuilder(column: $table.saleJson, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => column,
  );

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$PendingSalesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PendingSalesTable,
          PendingSale,
          $$PendingSalesTableFilterComposer,
          $$PendingSalesTableOrderingComposer,
          $$PendingSalesTableAnnotationComposer,
          $$PendingSalesTableCreateCompanionBuilder,
          $$PendingSalesTableUpdateCompanionBuilder,
          (
            PendingSale,
            BaseReferences<_$AppDatabase, $PendingSalesTable, PendingSale>,
          ),
          PendingSale,
          PrefetchHooks Function()
        > {
  $$PendingSalesTableTableManager(_$AppDatabase db, $PendingSalesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingSalesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingSalesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingSalesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> localId = const Value.absent(),
                Value<String?> clientId = const Value.absent(),
                Value<String> saleJson = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PendingSalesCompanion(
                localId: localId,
                clientId: clientId,
                saleJson: saleJson,
                status: status,
                errorMessage: errorMessage,
                retryCount: retryCount,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String localId,
                Value<String?> clientId = const Value.absent(),
                required String saleJson,
                Value<String> status = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => PendingSalesCompanion.insert(
                localId: localId,
                clientId: clientId,
                saleJson: saleJson,
                status: status,
                errorMessage: errorMessage,
                retryCount: retryCount,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingSalesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PendingSalesTable,
      PendingSale,
      $$PendingSalesTableFilterComposer,
      $$PendingSalesTableOrderingComposer,
      $$PendingSalesTableAnnotationComposer,
      $$PendingSalesTableCreateCompanionBuilder,
      $$PendingSalesTableUpdateCompanionBuilder,
      (
        PendingSale,
        BaseReferences<_$AppDatabase, $PendingSalesTable, PendingSale>,
      ),
      PendingSale,
      PrefetchHooks Function()
    >;
typedef $$PendingLaundryActionsTableCreateCompanionBuilder =
    PendingLaundryActionsCompanion Function({
      required String localId,
      required String clientOpId,
      required String actionType,
      Value<String?> orderId,
      required String payloadJson,
      Value<String> status,
      Value<String?> errorMessage,
      Value<int> retryCount,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$PendingLaundryActionsTableUpdateCompanionBuilder =
    PendingLaundryActionsCompanion Function({
      Value<String> localId,
      Value<String> clientOpId,
      Value<String> actionType,
      Value<String?> orderId,
      Value<String> payloadJson,
      Value<String> status,
      Value<String?> errorMessage,
      Value<int> retryCount,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$PendingLaundryActionsTableFilterComposer
    extends Composer<_$AppDatabase, $PendingLaundryActionsTable> {
  $$PendingLaundryActionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientOpId => $composableBuilder(
    column: $table.clientOpId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actionType => $composableBuilder(
    column: $table.actionType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get orderId => $composableBuilder(
    column: $table.orderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PendingLaundryActionsTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingLaundryActionsTable> {
  $$PendingLaundryActionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientOpId => $composableBuilder(
    column: $table.clientOpId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actionType => $composableBuilder(
    column: $table.actionType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get orderId => $composableBuilder(
    column: $table.orderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingLaundryActionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingLaundryActionsTable> {
  $$PendingLaundryActionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<String> get clientOpId => $composableBuilder(
    column: $table.clientOpId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get actionType => $composableBuilder(
    column: $table.actionType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get orderId =>
      $composableBuilder(column: $table.orderId, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => column,
  );

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$PendingLaundryActionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PendingLaundryActionsTable,
          PendingLaundryAction,
          $$PendingLaundryActionsTableFilterComposer,
          $$PendingLaundryActionsTableOrderingComposer,
          $$PendingLaundryActionsTableAnnotationComposer,
          $$PendingLaundryActionsTableCreateCompanionBuilder,
          $$PendingLaundryActionsTableUpdateCompanionBuilder,
          (
            PendingLaundryAction,
            BaseReferences<
              _$AppDatabase,
              $PendingLaundryActionsTable,
              PendingLaundryAction
            >,
          ),
          PendingLaundryAction,
          PrefetchHooks Function()
        > {
  $$PendingLaundryActionsTableTableManager(
    _$AppDatabase db,
    $PendingLaundryActionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingLaundryActionsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$PendingLaundryActionsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PendingLaundryActionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> localId = const Value.absent(),
                Value<String> clientOpId = const Value.absent(),
                Value<String> actionType = const Value.absent(),
                Value<String?> orderId = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PendingLaundryActionsCompanion(
                localId: localId,
                clientOpId: clientOpId,
                actionType: actionType,
                orderId: orderId,
                payloadJson: payloadJson,
                status: status,
                errorMessage: errorMessage,
                retryCount: retryCount,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String localId,
                required String clientOpId,
                required String actionType,
                Value<String?> orderId = const Value.absent(),
                required String payloadJson,
                Value<String> status = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => PendingLaundryActionsCompanion.insert(
                localId: localId,
                clientOpId: clientOpId,
                actionType: actionType,
                orderId: orderId,
                payloadJson: payloadJson,
                status: status,
                errorMessage: errorMessage,
                retryCount: retryCount,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingLaundryActionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PendingLaundryActionsTable,
      PendingLaundryAction,
      $$PendingLaundryActionsTableFilterComposer,
      $$PendingLaundryActionsTableOrderingComposer,
      $$PendingLaundryActionsTableAnnotationComposer,
      $$PendingLaundryActionsTableCreateCompanionBuilder,
      $$PendingLaundryActionsTableUpdateCompanionBuilder,
      (
        PendingLaundryAction,
        BaseReferences<
          _$AppDatabase,
          $PendingLaundryActionsTable,
          PendingLaundryAction
        >,
      ),
      PendingLaundryAction,
      PrefetchHooks Function()
    >;
typedef $$CachedSessionsTableCreateCompanionBuilder =
    CachedSessionsCompanion Function({
      required String id,
      required String sessionJson,
      required DateTime cachedAt,
      Value<int> rowid,
    });
typedef $$CachedSessionsTableUpdateCompanionBuilder =
    CachedSessionsCompanion Function({
      Value<String> id,
      Value<String> sessionJson,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

class $$CachedSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedSessionsTable> {
  $$CachedSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionJson => $composableBuilder(
    column: $table.sessionJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedSessionsTable> {
  $$CachedSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionJson => $composableBuilder(
    column: $table.sessionJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedSessionsTable> {
  $$CachedSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sessionJson => $composableBuilder(
    column: $table.sessionJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$CachedSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedSessionsTable,
          CachedSession,
          $$CachedSessionsTableFilterComposer,
          $$CachedSessionsTableOrderingComposer,
          $$CachedSessionsTableAnnotationComposer,
          $$CachedSessionsTableCreateCompanionBuilder,
          $$CachedSessionsTableUpdateCompanionBuilder,
          (
            CachedSession,
            BaseReferences<_$AppDatabase, $CachedSessionsTable, CachedSession>,
          ),
          CachedSession,
          PrefetchHooks Function()
        > {
  $$CachedSessionsTableTableManager(
    _$AppDatabase db,
    $CachedSessionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sessionJson = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedSessionsCompanion(
                id: id,
                sessionJson: sessionJson,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sessionJson,
                required DateTime cachedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedSessionsCompanion.insert(
                id: id,
                sessionJson: sessionJson,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedSessionsTable,
      CachedSession,
      $$CachedSessionsTableFilterComposer,
      $$CachedSessionsTableOrderingComposer,
      $$CachedSessionsTableAnnotationComposer,
      $$CachedSessionsTableCreateCompanionBuilder,
      $$CachedSessionsTableUpdateCompanionBuilder,
      (
        CachedSession,
        BaseReferences<_$AppDatabase, $CachedSessionsTable, CachedSession>,
      ),
      CachedSession,
      PrefetchHooks Function()
    >;
typedef $$SyncMetaTableCreateCompanionBuilder =
    SyncMetaCompanion Function({
      required String key,
      Value<String?> value,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$SyncMetaTableUpdateCompanionBuilder =
    SyncMetaCompanion Function({
      Value<String> key,
      Value<String?> value,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$SyncMetaTableFilterComposer
    extends Composer<_$AppDatabase, $SyncMetaTable> {
  $$SyncMetaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncMetaTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncMetaTable> {
  $$SyncMetaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncMetaTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncMetaTable> {
  $$SyncMetaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SyncMetaTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncMetaTable,
          SyncMetaData,
          $$SyncMetaTableFilterComposer,
          $$SyncMetaTableOrderingComposer,
          $$SyncMetaTableAnnotationComposer,
          $$SyncMetaTableCreateCompanionBuilder,
          $$SyncMetaTableUpdateCompanionBuilder,
          (
            SyncMetaData,
            BaseReferences<_$AppDatabase, $SyncMetaTable, SyncMetaData>,
          ),
          SyncMetaData,
          PrefetchHooks Function()
        > {
  $$SyncMetaTableTableManager(_$AppDatabase db, $SyncMetaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncMetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncMetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncMetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String?> value = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncMetaCompanion(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                Value<String?> value = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => SyncMetaCompanion.insert(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncMetaTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncMetaTable,
      SyncMetaData,
      $$SyncMetaTableFilterComposer,
      $$SyncMetaTableOrderingComposer,
      $$SyncMetaTableAnnotationComposer,
      $$SyncMetaTableCreateCompanionBuilder,
      $$SyncMetaTableUpdateCompanionBuilder,
      (
        SyncMetaData,
        BaseReferences<_$AppDatabase, $SyncMetaTable, SyncMetaData>,
      ),
      SyncMetaData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CachedProductsTableTableManager get cachedProducts =>
      $$CachedProductsTableTableManager(_db, _db.cachedProducts);
  $$CachedCategoriesTableTableManager get cachedCategories =>
      $$CachedCategoriesTableTableManager(_db, _db.cachedCategories);
  $$CachedCustomersTableTableManager get cachedCustomers =>
      $$CachedCustomersTableTableManager(_db, _db.cachedCustomers);
  $$PendingSalesTableTableManager get pendingSales =>
      $$PendingSalesTableTableManager(_db, _db.pendingSales);
  $$PendingLaundryActionsTableTableManager get pendingLaundryActions =>
      $$PendingLaundryActionsTableTableManager(_db, _db.pendingLaundryActions);
  $$CachedSessionsTableTableManager get cachedSessions =>
      $$CachedSessionsTableTableManager(_db, _db.cachedSessions);
  $$SyncMetaTableTableManager get syncMeta =>
      $$SyncMetaTableTableManager(_db, _db.syncMeta);
}
