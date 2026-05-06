import 'package:equatable/equatable.dart';

import '../../../data/models/product_models.dart';

class CartLine extends Equatable {
  final Product product;
  final double quantity;
  final double discount;
  final bool isPercentDiscount;
  /// Serial number for SERIAL-tracked products.
  final String? serialNumber;
  /// Lot number for LOT-tracked products.
  final String? lotNumber;

  const CartLine({
    required this.product,
    required this.quantity,
    this.discount = 0,
    this.isPercentDiscount = false,
    this.serialNumber,
    this.lotNumber,
  });

  double get lineSubtotal => product.sellingPrice * quantity;

  double get lineDiscount {
    if (discount <= 0) return 0;
    if (isPercentDiscount) return lineSubtotal * (discount / 100);
    return discount * quantity;
  }

  double get lineTax =>
      (lineSubtotal - lineDiscount) * ((product.taxRate ?? 0) / 100);

  double get lineTotal => lineSubtotal - lineDiscount + lineTax;

  bool get hasDiscount => discount > 0;

  CartLine copyWith({
    Product? product,
    double? quantity,
    double? discount,
    bool? isPercentDiscount,
    bool clearDiscount = false,
    String? serialNumber,
    String? lotNumber,
  }) => CartLine(
    product: product ?? this.product,
    quantity: quantity ?? this.quantity,
    discount: clearDiscount ? 0 : (discount ?? this.discount),
    isPercentDiscount: clearDiscount
        ? false
        : (isPercentDiscount ?? this.isPercentDiscount),
    serialNumber: serialNumber ?? this.serialNumber,
    lotNumber: lotNumber ?? this.lotNumber,
  );

  @override
  List<Object?> get props => [
    product.id,
    quantity,
    discount,
    isPercentDiscount,
    serialNumber,
    lotNumber,
  ];
}

class CartState extends Equatable {
  final List<CartLine> lines;
  final double discount;
  final String? selectedCustomerId;
  final String? selectedCustomerName;

  const CartState({
    this.lines = const [],
    this.discount = 0,
    this.selectedCustomerId,
    this.selectedCustomerName,
  });

  double get subtotal => lines.fold(0, (sum, l) => sum + l.lineSubtotal);

  double get taxAmount => lines.fold(0, (sum, l) => sum + l.lineTax);

  double get total {
    final value = subtotal + taxAmount - discount;
    return value < 0 ? 0 : value;
  }

  int get itemCount => lines.fold(0, (sum, l) => sum + l.quantity.toInt());
  bool get isEmpty => lines.isEmpty;
  bool get isNotEmpty => lines.isNotEmpty;
  bool get hasCustomer => selectedCustomerId != null;

  CartState copyWith({
    List<CartLine>? lines,
    double? discount,
    String? selectedCustomerId,
    String? selectedCustomerName,
    bool clearCustomer = false,
  }) {
    return CartState(
      lines: lines ?? this.lines,
      discount: discount ?? this.discount,
      selectedCustomerId: clearCustomer
          ? null
          : (selectedCustomerId ?? this.selectedCustomerId),
      selectedCustomerName: clearCustomer
          ? null
          : (selectedCustomerName ?? this.selectedCustomerName),
    );
  }

  @override
  List<Object?> get props => [
    lines,
    discount,
    selectedCustomerId,
    selectedCustomerName,
  ];
}
