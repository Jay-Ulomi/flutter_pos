import 'package:equatable/equatable.dart';

import '../../../data/models/sale_models.dart';
import '../../../data/models/sync_models.dart';

enum SaleStatus {
  initial,
  processing,
  completed,
  queuedOffline,
  loadingRecent,
  loadedRecent,
  returning,
  returned,
  error,
}

class SaleState extends Equatable {
  final SaleStatus status;
  final Sale? lastSale;
  final Receipt? receipt;
  final List<Sale> recent;
  final List<PendingSale> pending;
  final String? errorMessage;

  const SaleState({
    this.status = SaleStatus.initial,
    this.lastSale,
    this.receipt,
    this.recent = const [],
    this.pending = const [],
    this.errorMessage,
  });

  SaleState copyWith({
    SaleStatus? status,
    Sale? lastSale,
    Receipt? receipt,
    List<Sale>? recent,
    List<PendingSale>? pending,
    String? errorMessage,
    bool clearError = false,
    bool clearLast = false,
  }) {
    return SaleState(
      status: status ?? this.status,
      lastSale: clearLast ? null : (lastSale ?? this.lastSale),
      receipt: clearLast ? null : (receipt ?? this.receipt),
      recent: recent ?? this.recent,
      pending: pending ?? this.pending,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    status,
    lastSale,
    receipt,
    recent,
    pending,
    errorMessage,
  ];
}
