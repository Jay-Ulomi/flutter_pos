import 'package:equatable/equatable.dart';

import '../../../data/models/product_models.dart';
import 'cart_state.dart';

abstract class CartEvent extends Equatable {
  const CartEvent();
  @override
  List<Object?> get props => [];
}

class CartItemAdded extends CartEvent {
  final Product product;
  final double quantity;
  final String? serialNumber;
  final String? lotNumber;
  const CartItemAdded(this.product, {this.quantity = 1, this.serialNumber, this.lotNumber});
  @override
  List<Object?> get props => [product, quantity, serialNumber, lotNumber];
}

class CartItemRemoved extends CartEvent {
  final String productId;
  const CartItemRemoved(this.productId);
  @override
  List<Object?> get props => [productId];
}

class CartItemQtyChanged extends CartEvent {
  final String productId;
  final double quantity;
  const CartItemQtyChanged(this.productId, this.quantity);
  @override
  List<Object?> get props => [productId, quantity];
}

class CartDiscountApplied extends CartEvent {
  final double discount;
  const CartDiscountApplied(this.discount);
  @override
  List<Object?> get props => [discount];
}

class CartItemDiscountApplied extends CartEvent {
  final String productId;
  final double discount;
  final bool isPercent;
  const CartItemDiscountApplied(
    this.productId, {
    required this.discount,
    required this.isPercent,
  });
  @override
  List<Object?> get props => [productId, discount, isPercent];
}

class CartCustomItemAdded extends CartEvent {
  final String name;
  final double price;
  final double quantity;
  const CartCustomItemAdded({
    required this.name,
    required this.price,
    this.quantity = 1,
  });
  @override
  List<Object?> get props => [name, price, quantity];
}

class CartCleared extends CartEvent {
  const CartCleared();
}

class CartCustomerSelected extends CartEvent {
  final String customerId;
  final String customerName;
  const CartCustomerSelected({
    required this.customerId,
    required this.customerName,
  });
  @override
  List<Object?> get props => [customerId, customerName];
}

class CartRestored extends CartEvent {
  final List<CartLine> lines;
  final double discount;
  final String? customerId;
  final String? customerName;
  const CartRestored({
    required this.lines,
    this.discount = 0,
    this.customerId,
    this.customerName,
  });
  @override
  List<Object?> get props => [lines, discount, customerId, customerName];
}

class CartCustomerCleared extends CartEvent {
  const CartCustomerCleared();
}

class CartItemPriceChanged extends CartEvent {
  final String productId;
  final double price;
  const CartItemPriceChanged(this.productId, this.price);
  @override
  List<Object?> get props => [productId, price];
}
