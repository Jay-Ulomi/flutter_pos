import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/error_message.dart';
import '../../../domain/repositories/product_repository.dart';
import 'product_event.dart';
import 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductRepository _repository;
  Timer? _debounce;

  ProductBloc(this._repository) : super(const ProductState()) {
    on<ProductLoadRequested>(_onLoad);
    on<ProductSearchChanged>(_onSearchChanged);
    on<ProductCategoryChanged>(_onCategoryChanged);
    on<ProductBarcodeScanned>(_onBarcodeScanned);
    on<ProductSyncRequested>(_onSyncRequested);
  }

  Future<void> _onLoad(
    ProductLoadRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(state.copyWith(status: ProductStatus.loading, clearError: true));
    try {
      final productsFuture = _repository.getProducts(
        search: event.search,
        categoryId: event.categoryId,
      );
      final categoriesFuture = state.categories.isEmpty
          ? _repository.getCategories()
          : Future.value(state.categories);
      final products = await productsFuture;
      final categories = await categoriesFuture;
      emit(
        state.copyWith(
          status: ProductStatus.loaded,
          products: products,
          categories: categories,
          searchQuery: event.search ?? '',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ProductStatus.error,
          errorMessage: humanizeError(e),
        ),
      );
    }
  }

  Future<void> _onCategoryChanged(
    ProductCategoryChanged event,
    Emitter<ProductState> emit,
  ) async {
    final categoryId = event.categoryId;
    emit(
      state.copyWith(
        status: ProductStatus.loading,
        selectedCategoryId: categoryId,
        clearCategory: categoryId == null,
        clearError: true,
      ),
    );
    try {
      final products = await _repository.getProducts(
        search: state.searchQuery.isEmpty ? null : state.searchQuery,
        categoryId: categoryId,
      );
      emit(state.copyWith(status: ProductStatus.loaded, products: products));
    } catch (e) {
      emit(
        state.copyWith(
          status: ProductStatus.error,
          errorMessage: humanizeError(e),
        ),
      );
    }
  }

  Future<void> _onSearchChanged(
    ProductSearchChanged event,
    Emitter<ProductState> emit,
  ) async {
    emit(state.copyWith(searchQuery: event.query));
    _debounce?.cancel();
    final completer = Completer<void>();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        final products = await _repository.getProducts(
          search: event.query.isEmpty ? null : event.query,
          categoryId: state.selectedCategoryId,
        );
        if (!emit.isDone) {
          emit(
            state.copyWith(
              status: ProductStatus.loaded,
              products: products,
              searchQuery: event.query,
            ),
          );
        }
      } catch (e) {
        if (!emit.isDone) {
          emit(
            state.copyWith(
              status: ProductStatus.loaded,
              errorMessage: humanizeError(e),
            ),
          );
        }
      } finally {
        completer.complete();
      }
    });
    await completer.future;
  }

  Future<void> _onBarcodeScanned(
    ProductBarcodeScanned event,
    Emitter<ProductState> emit,
  ) async {
    try {
      final product = await _repository.getProductByBarcode(event.barcode);
      emit(state.copyWith(scannedProduct: product));
    } catch (e) {
      emit(state.copyWith(errorMessage: humanizeError(e)));
    }
  }

  Future<void> _onSyncRequested(
    ProductSyncRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(state.copyWith(status: ProductStatus.syncing, clearError: true));
    try {
      await _repository.refreshProducts();
      final products = await _repository.getProducts();
      emit(state.copyWith(status: ProductStatus.loaded, products: products));
    } catch (e) {
      emit(
        state.copyWith(
          status: ProductStatus.error,
          errorMessage: humanizeError(e),
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
