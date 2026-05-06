import 'package:equatable/equatable.dart';

class CashSession extends Equatable {
  final String id;
  final String userId;
  final String? userName;
  final String branchId;
  final double openingCash;
  final double? closingCash;
  final double? expectedCash;
  final double? difference;
  final String status;
  final DateTime openedAt;
  final DateTime? closedAt;
  final String? notes;

  const CashSession({
    required this.id,
    required this.userId,
    this.userName,
    required this.branchId,
    required this.openingCash,
    this.closingCash,
    this.expectedCash,
    this.difference,
    required this.status,
    required this.openedAt,
    this.closedAt,
    this.notes,
  });

  bool get isOpen => status == 'OPEN';

  factory CashSession.fromJson(Map<String, dynamic> json) {
    return CashSession(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      userName: json['userName'],
      branchId: json['branchId']?.toString() ?? '',
      openingCash: (json['openingCash'] ?? 0).toDouble(),
      closingCash: json['closingCash']?.toDouble(),
      expectedCash: json['expectedCash']?.toDouble(),
      difference: (json['cashDifference'] ?? json['difference'])?.toDouble(),
      status: json['status'] ?? 'OPEN',
      openedAt: json['openedAt'] != null
          ? DateTime.tryParse(json['openedAt']) ?? DateTime.now()
          : DateTime.now(),
      closedAt: json['closedAt'] != null
          ? DateTime.tryParse(json['closedAt'])
          : null,
      notes: json['notes'],
    );
  }

  @override
  List<Object?> get props => [id, userId, branchId, status, openingCash];
}

class OpenSessionRequest {
  final double openingCash;
  final String? notes;

  OpenSessionRequest({required this.openingCash, this.notes});

  Map<String, dynamic> toJson() => {'openingCash': openingCash, 'notes': notes};
}

class CloseSessionRequest {
  final String sessionId;
  final double closingCash;
  final String? notes;

  CloseSessionRequest({
    required this.sessionId,
    required this.closingCash,
    this.notes,
  });

  Map<String, dynamic> toJson() => {'closingCash': closingCash, 'notes': notes};
}

class ShiftSummary extends Equatable {
  final String? sessionId;
  final String? userId;
  final String? branchId;
  final String? status;
  final DateTime? openedAt;
  final DateTime? closedAt;
  final double openingCash;
  final double? closingCash;
  final double cashDifference;
  final int voidedSalesCount;
  final double totalCashIn;
  final double totalCashOut;
  final int totalSales;
  final double totalRevenue;
  final double totalCashReceived;
  final double totalCardReceived;
  final double totalMobileReceived;
  final int totalReturns;
  final double totalRefunds;
  final double expectedCash;

  const ShiftSummary({
    this.sessionId,
    this.userId,
    this.branchId,
    this.status,
    this.openedAt,
    this.closedAt,
    this.openingCash = 0,
    this.closingCash,
    this.cashDifference = 0,
    this.voidedSalesCount = 0,
    this.totalCashIn = 0,
    this.totalCashOut = 0,
    this.totalSales = 0,
    this.totalRevenue = 0,
    this.totalCashReceived = 0,
    this.totalCardReceived = 0,
    this.totalMobileReceived = 0,
    this.totalReturns = 0,
    this.totalRefunds = 0,
    this.expectedCash = 0,
  });

  factory ShiftSummary.fromJson(Map<String, dynamic> json) {
    final totalSales =
        (json['completedSalesCount'] ?? json['totalSales'] ?? 0) as num;
    final totalRevenue = (json['totalSalesAmount'] ?? json['totalRevenue'] ?? 0)
        .toDouble();
    final totalCashReceived =
        (json['totalCashPayments'] ?? json['totalCashReceived'] ?? 0)
            .toDouble();
    return ShiftSummary(
      sessionId: json['sessionId']?.toString(),
      userId: json['userId']?.toString(),
      branchId: json['branchId']?.toString(),
      status: json['status']?.toString(),
      openedAt: json['openedAt'] != null
          ? DateTime.tryParse(json['openedAt'].toString())
          : null,
      closedAt: json['closedAt'] != null
          ? DateTime.tryParse(json['closedAt'].toString())
          : null,
      openingCash: (json['openingCash'] ?? 0).toDouble(),
      closingCash: (json['closingCash'] as num?)?.toDouble(),
      cashDifference: (json['cashDifference'] ?? 0).toDouble(),
      voidedSalesCount: (json['voidedSalesCount'] ?? 0) as int,
      totalCashIn: (json['totalCashIn'] ?? 0).toDouble(),
      totalCashOut: (json['totalCashOut'] ?? 0).toDouble(),
      totalSales: totalSales.toInt(),
      totalRevenue: totalRevenue,
      totalCashReceived: totalCashReceived,
      totalCardReceived: (json['totalCardReceived'] ?? 0).toDouble(),
      totalMobileReceived: (json['totalMobileReceived'] ?? 0).toDouble(),
      totalReturns: json['totalReturns'] ?? 0,
      totalRefunds: (json['totalRefunds'] ?? 0).toDouble(),
      expectedCash: (json['expectedCash'] ?? 0).toDouble(),
    );
  }

  @override
  List<Object?> get props => [
    sessionId,
    totalSales,
    totalRevenue,
    expectedCash,
    closingCash,
    cashDifference,
  ];
}
