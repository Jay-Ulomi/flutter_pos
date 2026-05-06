import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/error_message.dart';
import '../../../core/network/network_info.dart';
import '../../../data/models/sale_models.dart';
import '../../../domain/repositories/sale_repository.dart';
import 'sale_event.dart';
import 'sale_state.dart';

class SaleBloc extends Bloc<SaleEvent, SaleState> {
  final SaleRepository _repository;
  final NetworkInfo _networkInfo;

  SaleBloc(this._repository, this._networkInfo) : super(const SaleState()) {
    on<SaleCheckoutRequested>(_onCheckout);
    on<SaleReceiptRequested>(_onReceiptRequested);
    on<SaleRecentLoadRequested>(_onRecentRequested);
    on<SaleReturnRequested>(_onReturnRequested);
    on<SaleCleared>(_onCleared);
  }

  Future<void> _onCheckout(
    SaleCheckoutRequested event,
    Emitter<SaleState> emit,
  ) async {
    emit(state.copyWith(status: SaleStatus.processing, clearError: true));
    final isOnline = _networkInfo.isConnected;
    try {
      final completed = await _repository.completeSale(event.sale);
      emit(
        state.copyWith(
          status: isOnline ? SaleStatus.completed : SaleStatus.queuedOffline,
          lastSale: completed,
        ),
      );
    } catch (e) {
      // If offline / remote failed but repo queued it, still mark queued
      emit(
        state.copyWith(
          status: isOnline ? SaleStatus.error : SaleStatus.queuedOffline,
          lastSale: event.sale,
          errorMessage: isOnline ? humanizeError(e) : null,
        ),
      );
    }
  }

  Future<void> _onReceiptRequested(
    SaleReceiptRequested event,
    Emitter<SaleState> emit,
  ) async {
    try {
      final receipt = await _repository.getReceipt(event.saleId);
      emit(state.copyWith(receipt: receipt));
    } catch (e) {
      emit(state.copyWith(errorMessage: humanizeError(e)));
    }
  }

  Future<void> _onRecentRequested(
    SaleRecentLoadRequested event,
    Emitter<SaleState> emit,
  ) async {
    emit(state.copyWith(status: SaleStatus.loadingRecent, clearError: true));
    try {
      final pending = await _repository.getPendingSales();
      List<Sale> recent = const [];
      if (_networkInfo.isConnected) {
        recent = await _repository.getRecentSales(size: 50);
      }
      emit(
        state.copyWith(
          status: SaleStatus.loadedRecent,
          pending: pending,
          recent: recent,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: SaleStatus.error,
          errorMessage: humanizeError(e),
        ),
      );
    }
  }

  Future<void> _onReturnRequested(
    SaleReturnRequested event,
    Emitter<SaleState> emit,
  ) async {
    emit(state.copyWith(status: SaleStatus.returning, clearError: true));
    try {
      final result = await _repository.processReturn(
        saleId: event.saleId,
        returnItems: event.returnItems,
        reason: event.reason,
      );
      emit(state.copyWith(status: SaleStatus.returned, lastSale: result));
    } catch (e) {
      emit(
        state.copyWith(
          status: SaleStatus.error,
          errorMessage: humanizeError(e),
        ),
      );
    }
  }

  void _onCleared(SaleCleared event, Emitter<SaleState> emit) {
    emit(
      state.copyWith(
        status: SaleStatus.initial,
        clearLast: true,
        clearError: true,
      ),
    );
  }
}
