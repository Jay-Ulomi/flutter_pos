import 'package:equatable/equatable.dart';

enum LaundryOrderStatus {
  received,
  washing,
  ironing,
  ready,
  collected,
  canceled,
}

enum LaundryPaymentMethod { cash, card, mobileMoney, bankTransfer }

String laundryPaymentMethodToApi(LaundryPaymentMethod method) {
  switch (method) {
    case LaundryPaymentMethod.cash:
      return 'CASH';
    case LaundryPaymentMethod.card:
      return 'CARD';
    case LaundryPaymentMethod.mobileMoney:
      return 'MOBILE_MONEY';
    case LaundryPaymentMethod.bankTransfer:
      return 'BANK_TRANSFER';
  }
}

LaundryOrderStatus laundryStatusFromString(String raw) {
  switch (raw.toUpperCase()) {
    case 'RECEIVED':
      return LaundryOrderStatus.received;
    case 'WASHING':
      return LaundryOrderStatus.washing;
    case 'IRONING':
      return LaundryOrderStatus.ironing;
    case 'READY':
      return LaundryOrderStatus.ready;
    case 'COLLECTED':
      return LaundryOrderStatus.collected;
    case 'CANCELED':
      return LaundryOrderStatus.canceled;
    default:
      return LaundryOrderStatus.received;
  }
}

String laundryStatusToApi(LaundryOrderStatus status) {
  switch (status) {
    case LaundryOrderStatus.received:
      return 'RECEIVED';
    case LaundryOrderStatus.washing:
      return 'WASHING';
    case LaundryOrderStatus.ironing:
      return 'IRONING';
    case LaundryOrderStatus.ready:
      return 'READY';
    case LaundryOrderStatus.collected:
      return 'COLLECTED';
    case LaundryOrderStatus.canceled:
      return 'CANCELED';
  }
}

class LaundryOrderItem extends Equatable {
  final String id;
  final String? productId;
  final String itemName;
  final double quantity;
  final double unitPrice;
  final double lineTotal;
  final String? notes;

  const LaundryOrderItem({
    required this.id,
    this.productId,
    required this.itemName,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    this.notes,
  });

  factory LaundryOrderItem.fromJson(Map<String, dynamic> json) {
    return LaundryOrderItem(
      id: json['id']?.toString() ?? '',
      productId: json['productId']?.toString(),
      itemName: json['itemName']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
      lineTotal: (json['lineTotal'] as num?)?.toDouble() ?? 0,
      notes: json['notes']?.toString(),
    );
  }

  @override
  List<Object?> get props => [
    id,
    productId,
    itemName,
    quantity,
    unitPrice,
    lineTotal,
    notes,
  ];
}

class LaundryOrderPayment extends Equatable {
  final String id;
  final double amount;
  final LaundryPaymentMethod paymentMethod;
  final String? reference;
  final String? notes;
  final DateTime? paymentDate;
  final DateTime? createdAt;

  const LaundryOrderPayment({
    required this.id,
    required this.amount,
    required this.paymentMethod,
    this.reference,
    this.notes,
    this.paymentDate,
    this.createdAt,
  });

  factory LaundryOrderPayment.fromJson(Map<String, dynamic> json) {
    LaundryPaymentMethod parsePaymentMethod(dynamic value) {
      switch ((value?.toString() ?? '').toUpperCase()) {
        case 'CARD':
          return LaundryPaymentMethod.card;
        case 'MOBILE_MONEY':
          return LaundryPaymentMethod.mobileMoney;
        case 'BANK_TRANSFER':
          return LaundryPaymentMethod.bankTransfer;
        case 'CASH':
        default:
          return LaundryPaymentMethod.cash;
      }
    }

    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      final raw = value.toString().trim();
      if (raw.isEmpty) return null;
      return DateTime.tryParse(raw);
    }

    return LaundryOrderPayment(
      id: json['id']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      paymentMethod: parsePaymentMethod(json['paymentMethod']),
      reference: json['reference']?.toString(),
      notes: json['notes']?.toString(),
      paymentDate: parseDateTime(json['paymentDate']),
      createdAt: parseDateTime(json['createdAt']),
    );
  }

  @override
  List<Object?> get props => [
    id,
    amount,
    paymentMethod,
    reference,
    notes,
    paymentDate,
    createdAt,
  ];
}

class LaundryOrder extends Equatable {
  final String id;
  final String? clientId;
  final String branchId;
  final String? customerId;
  final String? customerName;
  final String? customerPhone;
  final String ticketNumber;
  final DateTime? dueDate;
  final LaundryOrderStatus status;
  final double totalAmount;
  final double paidAmount;
  final double balanceAmount;
  final String? notes;
  final List<LaundryOrderItem> items;
  final List<LaundryOrderPayment> payments;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const LaundryOrder({
    required this.id,
    this.clientId,
    required this.branchId,
    this.customerId,
    this.customerName,
    this.customerPhone,
    required this.ticketNumber,
    required this.dueDate,
    required this.status,
    required this.totalAmount,
    required this.paidAmount,
    required this.balanceAmount,
    this.notes,
    this.items = const [],
    this.payments = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory LaundryOrder.fromJson(Map<String, dynamic> json) {
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      final raw = value.toString().trim();
      if (raw.isEmpty) return null;
      return DateTime.tryParse(raw);
    }

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      final raw = value.toString().trim();
      if (raw.isEmpty) return null;
      return DateTime.tryParse(raw);
    }

    return LaundryOrder(
      id: json['id']?.toString() ?? '',
      clientId: json['clientId']?.toString(),
      branchId: json['branchId']?.toString() ?? '',
      customerId: json['customerId']?.toString(),
      customerName: json['customerName']?.toString(),
      customerPhone: json['customerPhone']?.toString(),
      ticketNumber: json['ticketNumber']?.toString() ?? '',
      dueDate: parseDate(json['dueDate']),
      status: laundryStatusFromString(json['status']?.toString() ?? 'RECEIVED'),
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0,
      balanceAmount: (json['balanceAmount'] as num?)?.toDouble() ?? 0,
      notes: json['notes']?.toString(),
      items:
          (json['items'] as List?)
              ?.map((e) => LaundryOrderItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      payments:
          (json['payments'] as List?)
              ?.map(
                (e) => LaundryOrderPayment.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      createdAt: parseDateTime(json['createdAt']),
      updatedAt: parseDateTime(json['updatedAt']),
    );
  }

  @override
  List<Object?> get props => [
    id,
    clientId,
    branchId,
    customerId,
    customerName,
    customerPhone,
    ticketNumber,
    dueDate,
    status,
    totalAmount,
    paidAmount,
    balanceAmount,
    notes,
    items,
    payments,
    createdAt,
    updatedAt,
  ];
}

class LaundryPage extends Equatable {
  final List<LaundryOrder> content;
  final int number;
  final int size;
  final int totalPages;
  final int totalElements;

  const LaundryPage({
    this.content = const [],
    this.number = 0,
    this.size = 0,
    this.totalPages = 0,
    this.totalElements = 0,
  });

  factory LaundryPage.fromJson(Map<String, dynamic> json) {
    return LaundryPage(
      content:
          (json['content'] as List?)
              ?.map((e) => LaundryOrder.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      number: (json['number'] as num?)?.toInt() ?? 0,
      size: (json['size'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
      totalElements: (json['totalElements'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [content, number, size, totalPages, totalElements];
}
