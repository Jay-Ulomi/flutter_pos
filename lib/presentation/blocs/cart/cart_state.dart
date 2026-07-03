import 'package:equatable/equatable.dart';

import '../../../data/models/product_models.dart';

class CartLine extends Equatable {
  final Product product;
  final double quantity;
  final double discount;
  final bool isPercentDiscount;
  /// Override for the unit selling price (null = use product.sellingPrice).
  final double? priceOverride;
  /// Serial number for SERIAL-tracked products.
  final String? serialNumber;
  /// Lot number for LOT-tracked products.
  final String? lotNumber;

  const CartLine({
    required this.product,
    required this.quantity,
    this.discount = 0,
    this.isPercentDiscount = false,
    this.priceOverride,
    this.serialNumber,
    this.lotNumber,
  });

  double get effectivePrice => priceOverride ?? product.sellingPrice;

  double get lineSubtotal => effectivePrice * quantity;

  double get lineDiscount {
    if (discount <= 0) return 0;
    // Percent applies to the line; a fixed amount is the total off the line
    // (not per-unit). Never let a discount exceed the line value. Rounded to
    // cents so the value submitted to (and re-used by) the backend carries no
    // float drift.
    final raw = isPercentDiscount ? lineSubtotal * (discount / 100) : discount;
    final clamped = raw.clamp(0, lineSubtotal).toDouble();
    return (clamped * 100).roundToDouble() / 100;
  }

  double get lineTax =>
      (lineSubtotal - lineDiscount) * ((product.taxRate ?? 0) / 100);

  double get lineTotal => lineSubtotal - lineDiscount + lineTax;

  /// True when this line's quantity exceeds the product's available stock
  /// (only for inventory-tracked products with a known stock level).
  bool get exceedsStock {
    if (!product.trackInventory || product.stockQuantity == null) return false;
    return quantity > product.stockQuantity!;
  }

  bool get hasDiscount => discount > 0;
  bool get hasPriceOverride => priceOverride != null;

  CartLine copyWith({
    Product? product,
    double? quantity,
    double? discount,
    bool? isPercentDiscount,
    bool clearDiscount = false,
    double? priceOverride,
    bool clearPriceOverride = false,
    String? serialNumber,
    String? lotNumber,
  }) => CartLine(
    product: product ?? this.product,
    quantity: quantity ?? this.quantity,
    discount: clearDiscount ? 0 : (discount ?? this.discount),
    isPercentDiscount: clearDiscount
        ? false
        : (isPercentDiscount ?? this.isPercentDiscount),
    priceOverride: clearPriceOverride ? null : (priceOverride ?? this.priceOverride),
    serialNumber: serialNumber ?? this.serialNumber,
    lotNumber: lotNumber ?? this.lotNumber,
  );

  @override
  List<Object?> get props => [
    product.id,
    quantity,
    discount,
    isPercentDiscount,
    priceOverride,
    serialNumber,
    lotNumber,
  ];
}

class CartState extends Equatable {
  final List<CartLine> lines;
  final double discount;
  final String? selectedCustomerId;
  final String? selectedCustomerName;
  final double customerBalance;

  const CartState({
    this.lines = const [],
    this.discount = 0,
    this.selectedCustomerId,
    this.selectedCustomerName,
    this.customerBalance = 0,
  });

  double get subtotal => lines.fold(0, (sum, l) => sum + l.lineSubtotal);

  /// Sum of per-line discounts — must be subtracted from the total.
  double get lineDiscountTotal =>
      lines.fold(0, (sum, l) => sum + l.lineDiscount);

  double get taxAmount => lines.fold(0, (sum, l) => sum + l.lineTax);

  double get total {
    // = Σ lineTotal − sale-level discount. Mirrors the backend's authoritative
    // computation and, crucially, includes per-line discounts.
    final value = subtotal - lineDiscountTotal + taxAmount - discount;
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
    double? customerBalance,
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
      customerBalance: clearCustomer ? 0 : (customerBalance ?? this.customerBalance),
    );
  }

  @override
  List<Object?> get props => [
    lines,
    discount,
    selectedCustomerId,
    selectedCustomerName,
    customerBalance,
  ];
}
