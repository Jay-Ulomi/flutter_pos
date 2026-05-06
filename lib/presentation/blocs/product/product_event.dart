import 'package:equatable/equatable.dart';

abstract class ProductEvent extends Equatable {
  const ProductEvent();
  @override
  List<Object?> get props => [];
}

class ProductLoadRequested extends ProductEvent {
  final String? search;
  final String? categoryId;
  const ProductLoadRequested({this.search, this.categoryId});
  @override
  List<Object?> get props => [search, categoryId];
}

class ProductSearchChanged extends ProductEvent {
  final String query;
  const ProductSearchChanged(this.query);
  @override
  List<Object?> get props => [query];
}

class ProductBarcodeScanned extends ProductEvent {
  final String barcode;
  const ProductBarcodeScanned(this.barcode);
  @override
  List<Object?> get props => [barcode];
}

class ProductCategoryChanged extends ProductEvent {
  final String? categoryId;
  const ProductCategoryChanged(this.categoryId);
  @override
  List<Object?> get props => [categoryId];
}

class ProductSyncRequested extends ProductEvent {
  const ProductSyncRequested();
}
