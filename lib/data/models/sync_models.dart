import 'package:equatable/equatable.dart';
import 'customer_models.dart';
import 'product_models.dart';
import 'sale_models.dart';

enum SyncItemStatus { pending, syncing, synced, failed }

enum LaundrySyncActionType { createOrder, updateStatus, recordPayment }

String laundrySyncActionTypeApi(LaundrySyncActionType type) {
  switch (type) {
    case LaundrySyncActionType.createOrder:
      return 'CREATE_ORDER';
    case LaundrySyncActionType.updateStatus:
      return 'UPDATE_STATUS';
    case LaundrySyncActionType.recordPayment:
      return 'RECORD_PAYMENT';
  }
}

LaundrySyncActionType laundrySyncActionTypeFromApi(String value) {
  switch (value.toUpperCase()) {
    case 'CREATE_ORDER':
      return LaundrySyncActionType.createOrder;
    case 'UPDATE_STATUS':
      return LaundrySyncActionType.updateStatus;
    case 'RECORD_PAYMENT':
      return LaundrySyncActionType.recordPayment;
    default:
      return LaundrySyncActionType.createOrder;
  }
}

class PendingSale extends Equatable {
  final String localId;
  final String? clientId;
  final Sale sale;
  final DateTime createdAt;
  final SyncItemStatus status;
  final String? errorMessage;
  final int retryCount;

  const PendingSale({
    required this.localId,
    this.clientId,
    required this.sale,
    required this.createdAt,
    this.status = SyncItemStatus.pending,
    this.errorMessage,
    this.retryCount = 0,
  });

  PendingSale copyWith({
    SyncItemStatus? status,
    String? errorMessage,
    int? retryCount,
    String? clientId,
  }) {
    return PendingSale(
      localId: localId,
      clientId: clientId ?? this.clientId,
      sale: sale,
      createdAt: createdAt,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  Map<String, dynamic> toJson() => {
    'localId': localId,
    'clientId': clientId,
    'sale': sale.toJson(),
    'createdAt': createdAt.toIso8601String(),
    'status': status.name,
    'errorMessage': errorMessage,
    'retryCount': retryCount,
  };

  factory PendingSale.fromJson(Map<String, dynamic> json) {
    return PendingSale(
      localId: json['localId'] ?? '',
      clientId: json['clientId']?.toString(),
      sale: Sale.fromJson(json['sale'] as Map<String, dynamic>),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      status: SyncItemStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => SyncItemStatus.pending,
      ),
      errorMessage: json['errorMessage'],
      retryCount: json['retryCount'] ?? 0,
    );
  }

  @override
  List<Object?> get props => [localId, status, retryCount, clientId];
}

class PendingLaundrySyncAction extends Equatable {
  final String localId;
  final String clientOpId;
  final LaundrySyncActionType actionType;
  final String? orderId;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final SyncItemStatus status;
  final String? errorMessage;
  final int retryCount;

  const PendingLaundrySyncAction({
    required this.localId,
    required this.clientOpId,
    required this.actionType,
    this.orderId,
    required this.payload,
    required this.createdAt,
    this.status = SyncItemStatus.pending,
    this.errorMessage,
    this.retryCount = 0,
  });

  @override
  List<Object?> get props => [
    localId,
    clientOpId,
    actionType,
    orderId,
    status,
    retryCount,
    errorMessage,
  ];
}

class SyncStatus extends Equatable {
  final int pendingCount;
  final int syncingCount;
  final int failedCount;
  final int pendingSalesCount;
  final int failedSalesCount;
  final int pendingLaundryCount;
  final int failedLaundryCount;
  final bool isOnline;
  final DateTime? lastSyncTime;
  final int lastAcceptedCount;
  final int lastRejectedCount;

  const SyncStatus({
    this.pendingCount = 0,
    this.syncingCount = 0,
    this.failedCount = 0,
    this.pendingSalesCount = 0,
    this.failedSalesCount = 0,
    this.pendingLaundryCount = 0,
    this.failedLaundryCount = 0,
    this.isOnline = true,
    this.lastSyncTime,
    this.lastAcceptedCount = 0,
    this.lastRejectedCount = 0,
  });

  bool get hasPending => pendingCount > 0 || syncingCount > 0;
  int get totalPending => pendingCount + syncingCount + failedCount;

  SyncStatus copyWith({
    int? pendingCount,
    int? syncingCount,
    int? failedCount,
    int? pendingSalesCount,
    int? failedSalesCount,
    int? pendingLaundryCount,
    int? failedLaundryCount,
    bool? isOnline,
    DateTime? lastSyncTime,
    int? lastAcceptedCount,
    int? lastRejectedCount,
  }) {
    return SyncStatus(
      pendingCount: pendingCount ?? this.pendingCount,
      syncingCount: syncingCount ?? this.syncingCount,
      failedCount: failedCount ?? this.failedCount,
      pendingSalesCount: pendingSalesCount ?? this.pendingSalesCount,
      failedSalesCount: failedSalesCount ?? this.failedSalesCount,
      pendingLaundryCount: pendingLaundryCount ?? this.pendingLaundryCount,
      failedLaundryCount: failedLaundryCount ?? this.failedLaundryCount,
      isOnline: isOnline ?? this.isOnline,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      lastAcceptedCount: lastAcceptedCount ?? this.lastAcceptedCount,
      lastRejectedCount: lastRejectedCount ?? this.lastRejectedCount,
    );
  }

  @override
  List<Object?> get props => [
    pendingCount,
    syncingCount,
    failedCount,
    pendingSalesCount,
    failedSalesCount,
    pendingLaundryCount,
    failedLaundryCount,
    isOnline,
    lastSyncTime,
    lastAcceptedCount,
    lastRejectedCount,
  ];
}

class SyncBootstrap extends Equatable {
  final List<Product> products;
  final List<Category> categories;
  final List<Customer> customers;
  final DateTime serverTime;

  const SyncBootstrap({
    this.products = const [],
    this.categories = const [],
    this.customers = const [],
    required this.serverTime,
  });

  factory SyncBootstrap.fromJson(Map<String, dynamic> json) {
    return SyncBootstrap(
      products: ((json['products'] as List?) ?? const [])
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList(),
      categories: ((json['categories'] as List?) ?? const [])
          .map((e) => Category.fromJson(e as Map<String, dynamic>))
          .toList(),
      customers: ((json['customers'] as List?) ?? const [])
          .map((e) => Customer.fromJson(e as Map<String, dynamic>))
          .toList(),
      serverTime: json['serverTime'] != null
          ? DateTime.tryParse(json['serverTime'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [products, categories, customers, serverTime];
}

class SyncDelta extends Equatable {
  final List<Product> products;
  final List<Category> categories;
  final List<Customer> customers;
  final List<String> deletedProductIds;
  final List<String> deletedCustomerIds;
  final DateTime serverTime;

  const SyncDelta({
    this.products = const [],
    this.categories = const [],
    this.customers = const [],
    this.deletedProductIds = const [],
    this.deletedCustomerIds = const [],
    required this.serverTime,
  });

  factory SyncDelta.fromJson(Map<String, dynamic> json) {
    return SyncDelta(
      products: ((json['products'] as List?) ?? const [])
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList(),
      categories: ((json['categories'] as List?) ?? const [])
          .map((e) => Category.fromJson(e as Map<String, dynamic>))
          .toList(),
      customers: ((json['customers'] as List?) ?? const [])
          .map((e) => Customer.fromJson(e as Map<String, dynamic>))
          .toList(),
      deletedProductIds: ((json['deletedProductIds'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      deletedCustomerIds: ((json['deletedCustomerIds'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      serverTime: json['serverTime'] != null
          ? DateTime.tryParse(json['serverTime'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
    products,
    categories,
    customers,
    deletedProductIds,
    deletedCustomerIds,
    serverTime,
  ];
}

class AcceptedSale extends Equatable {
  final String clientId;
  final String serverId;
  final String? saleNumber;

  const AcceptedSale({
    required this.clientId,
    required this.serverId,
    this.saleNumber,
  });

  factory AcceptedSale.fromJson(Map<String, dynamic> json) {
    return AcceptedSale(
      clientId: json['clientId']?.toString() ?? '',
      serverId: json['id']?.toString() ?? json['serverId']?.toString() ?? '',
      saleNumber: json['saleNumber']?.toString(),
    );
  }

  @override
  List<Object?> get props => [clientId, serverId, saleNumber];
}

class RejectedSale extends Equatable {
  final String clientId;
  final String error;

  const RejectedSale({required this.clientId, required this.error});

  factory RejectedSale.fromJson(Map<String, dynamic> json) {
    return RejectedSale(
      clientId: json['clientId']?.toString() ?? '',
      error:
          json['error']?.toString() ??
          json['message']?.toString() ??
          'Unknown error',
    );
  }

  @override
  List<Object?> get props => [clientId, error];
}

class SyncPushResult extends Equatable {
  final List<AcceptedSale> accepted;
  final List<RejectedSale> rejected;

  const SyncPushResult({this.accepted = const [], this.rejected = const []});

  factory SyncPushResult.fromJson(Map<String, dynamic> json) {
    return SyncPushResult(
      accepted: ((json['accepted'] as List?) ?? const [])
          .map((e) => AcceptedSale.fromJson(e as Map<String, dynamic>))
          .toList(),
      rejected: ((json['rejected'] as List?) ?? const [])
          .map((e) => RejectedSale.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [accepted, rejected];
}

class AcceptedLaundryAction extends Equatable {
  final String clientOpId;
  final String? orderId;
  final String? ticketNumber;

  const AcceptedLaundryAction({
    required this.clientOpId,
    this.orderId,
    this.ticketNumber,
  });

  factory AcceptedLaundryAction.fromJson(Map<String, dynamic> json) {
    return AcceptedLaundryAction(
      clientOpId: json['clientOpId']?.toString() ?? '',
      orderId: json['orderId']?.toString(),
      ticketNumber: json['ticketNumber']?.toString(),
    );
  }

  @override
  List<Object?> get props => [clientOpId, orderId, ticketNumber];
}

class RejectedLaundryAction extends Equatable {
  final String clientOpId;
  final String error;

  const RejectedLaundryAction({required this.clientOpId, required this.error});

  factory RejectedLaundryAction.fromJson(Map<String, dynamic> json) {
    return RejectedLaundryAction(
      clientOpId: json['clientOpId']?.toString() ?? '',
      error:
          json['error']?.toString() ??
          json['message']?.toString() ??
          'Unknown error',
    );
  }

  @override
  List<Object?> get props => [clientOpId, error];
}

class LaundrySyncPushResult extends Equatable {
  final List<AcceptedLaundryAction> accepted;
  final List<RejectedLaundryAction> rejected;

  const LaundrySyncPushResult({
    this.accepted = const [],
    this.rejected = const [],
  });

  factory LaundrySyncPushResult.fromJson(Map<String, dynamic> json) {
    return LaundrySyncPushResult(
      accepted: ((json['accepted'] as List?) ?? const [])
          .map((e) => AcceptedLaundryAction.fromJson(e as Map<String, dynamic>))
          .toList(),
      rejected: ((json['rejected'] as List?) ?? const [])
          .map((e) => RejectedLaundryAction.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [accepted, rejected];
}
