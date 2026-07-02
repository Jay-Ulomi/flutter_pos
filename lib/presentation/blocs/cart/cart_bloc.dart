import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/product_models.dart';
import 'cart_event.dart';
import 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc() : super(const CartState()) {
    on<CartItemAdded>(_onItemAdded);
    on<CartItemRemoved>(_onItemRemoved);
    on<CartItemQtyChanged>(_onQtyChanged);
    on<CartItemDiscountApplied>(_onItemDiscountApplied);
    on<CartCustomItemAdded>(_onCustomItemAdded);
    on<CartDiscountApplied>(_onDiscountApplied);
    on<CartCleared>(_onCleared);
    on<CartRestored>(_onRestored);
    on<CartCustomerSelected>(_onCustomerSelected);
    on<CartCustomerCleared>(_onCustomerCleared);
    on<CartItemPriceChanged>(_onPriceChanged);
  }

  void _onRestored(CartRestored event, Emitter<CartState> emit) {
    emit(
      CartState(
        lines: event.lines,
        discount: event.discount,
        selectedCustomerId: event.customerId,
        selectedCustomerName: event.customerName,
      ),
    );
  }

  void _onCustomerSelected(
    CartCustomerSelected event,
    Emitter<CartState> emit,
  ) {
    emit(
      state.copyWith(
        selectedCustomerId: event.customerId,
        selectedCustomerName: event.customerName,
        customerBalance: event.customerBalance,
      ),
    );
  }

  void _onCustomerCleared(CartCustomerCleared event, Emitter<CartState> emit) {
    emit(state.copyWith(clearCustomer: true));
  }

  void _onItemAdded(CartItemAdded event, Emitter<CartState> emit) {
    // Serial/lot-tracked items are always a new line (each serial is unique).
    final isTracked = event.serialNumber != null || event.lotNumber != null;
    final existing = isTracked
        ? -1
        : state.lines.indexWhere((l) => l.product.id == event.product.id);
    final lines = [...state.lines];
    if (existing >= 0) {
      // Re-added: bump quantity and move to the top so the just-added item is
      // visible.
      final line = lines.removeAt(existing);
      lines.insert(
        0,
        line.copyWith(quantity: line.quantity + event.quantity),
      );
    } else {
      // New product goes to the top of the cart.
      lines.insert(
        0,
        CartLine(
          product: event.product,
          quantity: event.quantity,
          serialNumber: event.serialNumber,
          lotNumber: event.lotNumber,
        ),
      );
    }
    emit(state.copyWith(lines: lines));
  }

  void _onItemRemoved(CartItemRemoved event, Emitter<CartState> emit) {
    final lines = state.lines
        .where((l) => l.product.id != event.productId)
        .toList();
    emit(state.copyWith(lines: lines));
  }

  void _onQtyChanged(CartItemQtyChanged event, Emitter<CartState> emit) {
    if (event.quantity <= 0) {
      add(CartItemRemoved(event.productId));
      return;
    }
    final lines = state.lines.map((l) {
      if (l.product.id == event.productId) {
        return l.copyWith(quantity: event.quantity);
      }
      return l;
    }).toList();
    emit(state.copyWith(lines: lines));
  }

  static int _customCounter = 0;

  void _onCustomItemAdded(CartCustomItemAdded event, Emitter<CartState> emit) {
    _customCounter++;
    final product = Product(
      id: '_custom_$_customCounter',
      name: event.name,
      sellingPrice: event.price,
    );
    final lines = [
      CartLine(product: product, quantity: event.quantity),
      ...state.lines,
    ];
    emit(state.copyWith(lines: lines));
  }

  void _onItemDiscountApplied(
    CartItemDiscountApplied event,
    Emitter<CartState> emit,
  ) {
    final lines = state.lines.map((l) {
      if (l.product.id == event.productId) {
        return l.copyWith(
          discount: event.discount,
          isPercentDiscount: event.isPercent,
          clearDiscount: event.discount <= 0,
        );
      }
      return l;
    }).toList();
    emit(state.copyWith(lines: lines));
  }

  void _onDiscountApplied(CartDiscountApplied event, Emitter<CartState> emit) {
    emit(state.copyWith(discount: event.discount));
  }

  void _onPriceChanged(CartItemPriceChanged event, Emitter<CartState> emit) {
    final lines = state.lines.map((l) {
      if (l.product.id == event.productId) {
        return l.copyWith(priceOverride: event.price);
      }
      return l;
    }).toList();
    emit(state.copyWith(lines: lines));
  }

  void _onCleared(CartCleared event, Emitter<CartState> emit) {
    emit(const CartState());
  }
}
