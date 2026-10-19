import 'package:equatable/equatable.dart';

import '../../../data/models/product_models.dart';
import '../../../data/models/sale_models.dart';

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
  /// Named price tier (e.g. WHOLESALE); null = normal selling price.
  final String? priceTier;

  const CartLine({
    required this.product,
    required this.quantity,
    this.discount = 0,
    this.isPercentDiscount = false,
    this.priceOverride,
    this.serialNumber,
    this.lotNumber,
    this.priceTier,
  });

  double get effectivePrice => priceOverride ?? product.priceForTier(priceTier);

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

  // Exempt products carry no tax whatever their rate, as on the backend.
  double get lineTax => product.taxable
      ? (lineSubtotal - lineDiscount) * ((product.taxRate ?? 0) / 100)
      : 0;

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
    String? priceTier,
    bool clearPriceTier = false,
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
    priceTier: clearPriceTier ? null : (priceTier ?? this.priceTier),
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
    priceTier,
  ];
}

class CartState extends Equatable {
  final List<CartLine> lines;
  final double discount;
  final String? selectedCustomerId;
  final String? selectedCustomerName;
  final double customerBalance;
  /// Loyalty points of the selected customer (spendable at checkout).
  final int customerLoyaltyPoints;
  /// Delivery, packaging… added at Confirm Sale.
  final List<SaleCharge> charges;

  const CartState({
    this.lines = const [],
    this.discount = 0,
    this.selectedCustomerId,
    this.selectedCustomerName,
    this.customerBalance = 0,
    this.customerLoyaltyPoints = 0,
    this.charges = const [],
  });

  double get subtotal => lines.fold(0, (sum, l) => sum + l.lineSubtotal);

  /// Sum of per-line discounts — must be subtracted from the total.
  double get lineDiscountTotal =>
      lines.fold(0, (sum, l) => sum + l.lineDiscount);

  double get taxAmount => lines.fold(0, (sum, l) => sum + l.lineTax);

  /// Additional charges including their tax.
  double get chargesTotal => charges.fold(0, (sum, c) => sum + c.total);

  double get total {
    // = Σ lineTotal − sale-level discount + charges. Mirrors the backend's
    // authoritative computation and, crucially, includes per-line discounts.
    // The discount never eats into the charges.
    final goods = subtotal - lineDiscountTotal + taxAmount - discount;
    return (goods < 0 ? 0 : goods) + chargesTotal;
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
    int? customerLoyaltyPoints,
    List<SaleCharge>? charges,
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
      customerLoyaltyPoints: clearCustomer
          ? 0
          : (customerLoyaltyPoints ?? this.customerLoyaltyPoints),
      charges: charges ?? this.charges,
    );
  }

  @override
  List<Object?> get props => [
    lines,
    discount,
    selectedCustomerId,
    selectedCustomerName,
    customerBalance,
    customerLoyaltyPoints,
    charges,
  ];
}
