import 'package:equatable/equatable.dart';

import '../../../data/models/product_models.dart';

enum ProductStatus { initial, loading, loaded, syncing, error }

class ProductState extends Equatable {
  final ProductStatus status;
  final List<Product> products;
  final List<Category> categories;
  final String searchQuery;
  final String? selectedCategoryId;
  final String? errorMessage;
  final Product? scannedProduct;

  const ProductState({
    this.status = ProductStatus.initial,
    this.products = const [],
    this.categories = const [],
    this.searchQuery = '',
    this.selectedCategoryId,
    this.errorMessage,
    this.scannedProduct,
  });

  ProductState copyWith({
    ProductStatus? status,
    List<Product>? products,
    List<Category>? categories,
    String? searchQuery,
    String? selectedCategoryId,
    String? errorMessage,
    Product? scannedProduct,
    bool clearError = false,
    bool clearScanned = false,
    bool clearCategory = false,
  }) {
    return ProductState(
      status: status ?? this.status,
      products: products ?? this.products,
      categories: categories ?? this.categories,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategoryId: clearCategory
          ? null
          : (selectedCategoryId ?? this.selectedCategoryId),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      scannedProduct: clearScanned
          ? null
          : (scannedProduct ?? this.scannedProduct),
    );
  }

  @override
  List<Object?> get props => [
    status,
    products,
    categories,
    searchQuery,
    selectedCategoryId,
    errorMessage,
    scannedProduct,
  ];
}
