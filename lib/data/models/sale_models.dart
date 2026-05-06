import 'package:equatable/equatable.dart';

class SaleItem extends Equatable {
  final String? id;
  final String productId;
  final String productName;
  final double quantity;
  final double unitPrice;
  final double discount;
  final double taxAmount;
  final double totalPrice;
  /// For SERIAL-tracked products — sent to backend at checkout.
  final String? serialNumber;
  /// For LOT-tracked products — sent to backend at checkout.
  final String? lotNumber;

  const SaleItem({
    this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    this.discount = 0,
    this.taxAmount = 0,
    required this.totalPrice,
    this.serialNumber,
    this.lotNumber,
  });

  double get subtotal => quantity * unitPrice;
  double get discountedTotal => subtotal - discount;

  SaleItem copyWith({
    String? id,
    String? productId,
    String? productName,
    double? quantity,
    double? unitPrice,
    double? discount,
    double? taxAmount,
    double? totalPrice,
    String? serialNumber,
    String? lotNumber,
  }) {
    return SaleItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      discount: discount ?? this.discount,
      taxAmount: taxAmount ?? this.taxAmount,
      totalPrice: totalPrice ?? this.totalPrice,
      serialNumber: serialNumber ?? this.serialNumber,
      lotNumber: lotNumber ?? this.lotNumber,
    );
  }

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'quantity': quantity,
    'unitPrice': unitPrice,
    'discountAmount': discount, // backend expects discountAmount
    if (serialNumber != null) 'serialNumber': serialNumber,
    if (lotNumber != null) 'lotNumber': lotNumber,
  };

  factory SaleItem.fromJson(Map<String, dynamic> json) {
    return SaleItem(
      id: json['id']?.toString(),
      productId: json['productId']?.toString() ?? '',
      productName: json['productName'] ?? '',
      quantity: (json['quantity'] ?? 0).toDouble(),
      unitPrice: (json['unitPrice'] ?? 0).toDouble(),
      discount: (json['discountAmount'] ?? json['discount'] ?? 0).toDouble(),
      taxAmount: (json['taxAmount'] ?? 0).toDouble(),
      totalPrice: (json['lineTotal'] ?? json['totalPrice'] ?? 0).toDouble(),
    );
  }

  @override
  List<Object?> get props => [
    productId,
    quantity,
    unitPrice,
    discount,
    totalPrice,
  ];
}

class SalePayment extends Equatable {
  final String method;
  final double amount;
  final String? reference;

  const SalePayment({
    required this.method,
    required this.amount,
    this.reference,
  });

  Map<String, dynamic> toJson() => {
    'paymentMethod': method,
    'amount': amount,
    'reference': reference,
  };

  factory SalePayment.fromJson(Map<String, dynamic> json) {
    return SalePayment(
      method: json['paymentMethod'] ?? json['method'] ?? 'CASH',
      amount: (json['amount'] ?? 0).toDouble(),
      reference: json['reference'],
    );
  }

  @override
  List<Object?> get props => [method, amount, reference];
}

class Sale extends Equatable {
  final String? id;
  final String? clientId;
  final String? sessionId; // links sale to open cash session
  final String? saleNumber;
  final List<SaleItem> items;
  final List<SalePayment> payments;
  final double subtotal;
  final double taxAmount;
  final double discountAmount;
  final double totalAmount;
  final double paidAmount;
  final double changeAmount;
  final String? customerId;
  final String? customerName;
  final String? notes;
  final String? couponCode;
  final String status;
  final DateTime? createdAt;

  const Sale({
    this.id,
    this.clientId,
    this.sessionId,
    this.saleNumber,
    this.items = const [],
    this.payments = const [],
    this.subtotal = 0,
    this.taxAmount = 0,
    this.discountAmount = 0,
    this.totalAmount = 0,
    this.paidAmount = 0,
    this.changeAmount = 0,
    this.customerId,
    this.customerName,
    this.notes,
    this.couponCode,
    this.status = 'COMPLETED',
    this.createdAt,
  });

  Sale copyWith({
    String? id,
    String? clientId,
    String? sessionId,
    String? saleNumber,
    List<SaleItem>? items,
    List<SalePayment>? payments,
    double? subtotal,
    double? taxAmount,
    double? discountAmount,
    double? totalAmount,
    double? paidAmount,
    double? changeAmount,
    String? customerId,
    String? customerName,
    String? notes,
    String? couponCode,
    String? status,
    DateTime? createdAt,
  }) {
    return Sale(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      sessionId: sessionId ?? this.sessionId,
      saleNumber: saleNumber ?? this.saleNumber,
      items: items ?? this.items,
      payments: payments ?? this.payments,
      subtotal: subtotal ?? this.subtotal,
      taxAmount: taxAmount ?? this.taxAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      changeAmount: changeAmount ?? this.changeAmount,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      notes: notes ?? this.notes,
      couponCode: couponCode ?? this.couponCode,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    if (clientId != null) 'clientId': clientId,
    if (sessionId != null) 'sessionId': sessionId,
    if (customerId != null) 'customerId': customerId,
    'items': items.map((e) => e.toJson()).toList(),
    'payments': payments.map((e) => e.toJson()).toList(),
    'discountAmount': discountAmount,
    if (couponCode != null) 'couponCode': couponCode,
    if (notes != null) 'notes': notes,
  };

  // Full representation used for local pending-sale persistence.
  Map<String, dynamic> toLocalJson() => {
    if (id != null) 'id': id,
    if (clientId != null) 'clientId': clientId,
    if (sessionId != null) 'sessionId': sessionId,
    if (saleNumber != null) 'saleNumber': saleNumber,
    if (customerId != null) 'customerId': customerId,
    if (customerName != null) 'customerName': customerName,
    if (notes != null) 'notes': notes,
    if (couponCode != null) 'couponCode': couponCode,
    'items': items.map((e) => e.toJson()).toList(),
    'payments': payments.map((e) => e.toJson()).toList(),
    'subtotal': subtotal,
    'taxAmount': taxAmount,
    'discountAmount': discountAmount,
    'totalAmount': totalAmount,
    'paidAmount': paidAmount,
    'changeAmount': changeAmount,
    'status': status,
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
  };

  factory Sale.fromJson(Map<String, dynamic> json) {
    return Sale(
      id: json['id']?.toString(),
      clientId: json['clientId']?.toString(),
      sessionId: json['sessionId']?.toString(),
      saleNumber: json['saleNumber'],
      items:
          (json['items'] as List?)
              ?.map((e) => SaleItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      payments:
          (json['payments'] as List?)
              ?.map((e) => SalePayment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      taxAmount: (json['taxAmount'] ?? 0).toDouble(),
      discountAmount: (json['discountAmount'] ?? 0).toDouble(),
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      paidAmount: (json['paidAmount'] ?? 0).toDouble(),
      changeAmount: (json['changeAmount'] ?? 0).toDouble(),
      customerId: json['customerId']?.toString(),
      customerName: json['customerName'],
      notes: json['notes'],
      couponCode: json['couponCode'],
      status: json['status'] ?? 'COMPLETED',
      createdAt: (json['createdAt'] ?? json['saleDate']) != null
          ? DateTime.tryParse(
              (json['createdAt'] ?? json['saleDate']).toString(),
            )
          : null,
    );
  }

  @override
  List<Object?> get props => [id, clientId, saleNumber, totalAmount, status];
}

class Receipt {
  final String saleNumber;
  final String businessName;
  final String branchName;
  final String? businessAddress;
  final String? businessPhone;
  final String? tinNumber;
  final String cashierName;
  final List<SaleItem> items;
  final List<SalePayment> payments;
  final double subtotal;
  final double taxAmount;
  final double discountAmount;
  final double totalAmount;
  final double paidAmount;
  final double changeAmount;
  final DateTime dateTime;
  final String? traReceiptNumber;

  Receipt({
    required this.saleNumber,
    required this.businessName,
    required this.branchName,
    this.businessAddress,
    this.businessPhone,
    this.tinNumber,
    required this.cashierName,
    required this.items,
    required this.payments,
    required this.subtotal,
    required this.taxAmount,
    required this.discountAmount,
    required this.totalAmount,
    required this.paidAmount,
    required this.changeAmount,
    required this.dateTime,
    this.traReceiptNumber,
  });

  factory Receipt.fromJson(Map<String, dynamic> json) {
    return Receipt(
      saleNumber: json['saleNumber'] ?? '',
      businessName: json['businessName'] ?? '',
      branchName: json['branchName'] ?? '',
      businessAddress: json['businessAddress'],
      businessPhone: json['businessPhone'],
      tinNumber: json['tinNumber'],
      cashierName: json['cashierName'] ?? '',
      items:
          (json['items'] as List?)
              ?.map((e) => SaleItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      payments:
          (json['payments'] as List?)
              ?.map((e) => SalePayment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      taxAmount: (json['taxAmount'] ?? 0).toDouble(),
      discountAmount: (json['discountAmount'] ?? 0).toDouble(),
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      paidAmount: (json['paidAmount'] ?? 0).toDouble(),
      changeAmount: (json['changeAmount'] ?? 0).toDouble(),
      dateTime: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      traReceiptNumber: json['traReceiptNumber'],
    );
  }
}
