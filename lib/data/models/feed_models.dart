import 'package:equatable/equatable.dart';

/// Models for the redesign's server feeds: transactions, parties, transfers,
/// report summary and receivables (see the API contracts in README).

double _d(Object? v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
DateTime? _dt(Object? v) => v == null ? null : DateTime.tryParse('$v')?.toLocal();

/// One page of a Spring `Page<T>` (or a bare list).
class PageResult<T> {
  const PageResult({required this.items, this.page = 0, this.totalPages = 1, this.totalElements});

  final List<T> items;
  final int page;
  final int totalPages;
  final int? totalElements;

  bool get hasMore => page + 1 < totalPages;

  static PageResult<T> parse<T>(Object? data, T Function(Map<String, dynamic>) fromJson) {
    if (data is List) {
      return PageResult(items: data.map((e) => fromJson(e as Map<String, dynamic>)).toList());
    }
    final map = (data as Map?)?.cast<String, dynamic>() ?? const {};
    final content = (map['content'] as List?) ?? const [];
    return PageResult(
      items: content.map((e) => fromJson(e as Map<String, dynamic>)).toList(),
      page: (map['number'] as num?)?.toInt() ?? 0,
      totalPages: (map['totalPages'] as num?)?.toInt() ?? 1,
      totalElements: (map['totalElements'] as num?)?.toInt(),
    );
  }
}

/// Transaction kinds in the unified feed, in hub order.
enum TxType {
  sale('SALE'),
  paymentIn('PAYMENT_IN'),
  saleReturn('SALE_RETURN'),
  quotation('QUOTATION'),
  purchase('PURCHASE'),
  paymentOut('PAYMENT_OUT'),
  purchaseReturn('PURCHASE_RETURN'),
  expense('EXPENSE'),
  partyTransfer('PARTY_TRANSFER');

  const TxType(this.code);
  final String code;

  static TxType? fromCode(String? code) {
    for (final t in values) {
      if (t.code == code) return t;
    }
    return null;
  }

  /// Money flowing out of the business (shown in orange).
  bool get isOutflow =>
      this == purchase || this == paymentOut || this == expense || this == saleReturn;
}

class TransactionItem extends Equatable {
  const TransactionItem({
    required this.type,
    required this.id,
    this.number,
    this.date,
    this.partyName,
    this.partyType,
    this.amount = 0,
    this.status,
    this.paymentMethod,
  });

  /// Raw type code (kept even when this app version does not know it).
  final String type;
  final String id;
  final String? number;
  final DateTime? date;
  final String? partyName;
  final String? partyType;
  final double amount;
  final String? status;
  final String? paymentMethod;

  TxType? get kind => TxType.fromCode(type);

  factory TransactionItem.fromJson(Map<String, dynamic> json) => TransactionItem(
        type: '${json['type'] ?? ''}',
        id: '${json['id'] ?? ''}',
        number: json['number'] as String?,
        date: _dt(json['date']),
        partyName: json['partyName'] as String?,
        partyType: json['partyType'] as String?,
        amount: _d(json['amount']),
        status: json['status'] as String?,
        paymentMethod: json['paymentMethod'] as String?,
      );

  @override
  List<Object?> get props => [type, id, number, date, partyName, partyType, amount, status, paymentMethod];
}

enum PartyType {
  customer('CUSTOMER'),
  supplier('SUPPLIER');

  const PartyType(this.code);
  final String code;

  static PartyType fromCode(String? code) => code == 'SUPPLIER' ? supplier : customer;
}

enum BalanceDirection { receivable, payable, settled }

class PartySummary extends Equatable {
  const PartySummary({
    required this.type,
    required this.id,
    required this.name,
    this.phone,
    this.balance = 0,
    this.direction = BalanceDirection.settled,
    this.lastActivityAt,
  });

  final PartyType type;
  final String id;
  final String name;
  final String? phone;
  final double balance;
  final BalanceDirection direction;
  final DateTime? lastActivityAt;

  factory PartySummary.fromJson(Map<String, dynamic> json) => PartySummary(
        type: PartyType.fromCode(json['type'] as String?),
        id: '${json['id'] ?? ''}',
        name: (json['name'] as String?) ?? '',
        phone: json['phone'] as String?,
        balance: _d(json['balance']),
        direction: switch (json['balanceDirection']) {
          'RECEIVABLE' => BalanceDirection.receivable,
          'PAYABLE' => BalanceDirection.payable,
          _ => BalanceDirection.settled,
        },
        lastActivityAt: _dt(json['lastActivityAt']),
      );

  @override
  List<Object?> get props => [type, id, name, phone, balance, direction, lastActivityAt];
}

class ReportFigures extends Equatable {
  const ReportFigures({
    this.salesCount = 0,
    this.salesAmount = 0,
    this.receivedAmount = 0,
    this.unpaidAmount = 0,
    this.purchasesAmount = 0,
    this.expensesAmount = 0,
  });

  final int salesCount;
  final double salesAmount;
  final double receivedAmount;
  final double unpaidAmount;
  final double purchasesAmount;
  final double expensesAmount;

  factory ReportFigures.fromJson(Map<String, dynamic> json) => ReportFigures(
        salesCount: (json['salesCount'] as num?)?.toInt() ?? 0,
        salesAmount: _d(json['salesAmount']),
        receivedAmount: _d(json['receivedAmount']),
        unpaidAmount: _d(json['unpaidAmount']),
        purchasesAmount: _d(json['purchasesAmount']),
        expensesAmount: _d(json['expensesAmount']),
      );

  @override
  List<Object?> get props =>
      [salesCount, salesAmount, receivedAmount, unpaidAmount, purchasesAmount, expensesAmount];
}

class ReportSummary extends Equatable {
  const ReportSummary({required this.current, this.previous});

  final ReportFigures current;
  final ReportFigures? previous;

  factory ReportSummary.fromJson(Map<String, dynamic> json) => ReportSummary(
        current: ReportFigures.fromJson(json),
        previous: json['previous'] is Map
            ? ReportFigures.fromJson((json['previous'] as Map).cast<String, dynamic>())
            : null,
      );

  /// Percentage change vs the previous period, or null when there is none.
  static double? change(double now, double? before) {
    if (before == null || before == 0) return null;
    return (now - before) / before * 100;
  }

  @override
  List<Object?> get props => [current, previous];
}

/// An open customer receivable (Payment In applies to one of these).
class ReceivableItem extends Equatable {
  const ReceivableItem({
    required this.id,
    this.saleId,
    this.amount = 0,
    this.balance = 0,
    this.dueDate,
    this.status,
  });

  final String id;
  final String? saleId;
  final double amount;
  final double balance;
  final DateTime? dueDate;
  final String? status;

  factory ReceivableItem.fromJson(Map<String, dynamic> json) => ReceivableItem(
        id: '${json['id'] ?? ''}',
        saleId: json['saleId']?.toString(),
        amount: _d(json['amount']),
        balance: _d(json['balance']),
        dueDate: _dt(json['dueDate']),
        status: json['status'] as String?,
      );

  @override
  List<Object?> get props => [id, saleId, amount, balance, dueDate, status];
}
