import 'package:equatable/equatable.dart';

import '../../../data/models/sale_models.dart';

abstract class SaleEvent extends Equatable {
  const SaleEvent();
  @override
  List<Object?> get props => [];
}

class SaleCheckoutRequested extends SaleEvent {
  final Sale sale;
  const SaleCheckoutRequested(this.sale);
  @override
  List<Object?> get props => [sale];
}

class SaleReceiptRequested extends SaleEvent {
  final String saleId;
  const SaleReceiptRequested(this.saleId);
  @override
  List<Object?> get props => [saleId];
}

class SaleRecentLoadRequested extends SaleEvent {
  const SaleRecentLoadRequested();
}

class SaleReturnRequested extends SaleEvent {
  final String saleId;
  final List<Map<String, dynamic>> returnItems;
  final String reason;
  const SaleReturnRequested({
    required this.saleId,
    required this.returnItems,
    required this.reason,
  });
  @override
  List<Object?> get props => [saleId, returnItems, reason];
}

class SaleCleared extends SaleEvent {
  const SaleCleared();
}
