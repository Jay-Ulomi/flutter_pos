import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/error_message.dart';
import '../../../data/models/customer_models.dart';
import '../../../domain/repositories/customer_repository.dart';
import 'customer_event.dart';
import 'customer_state.dart';

class CustomerBloc extends Bloc<CustomerEvent, CustomerState> {
  final CustomerRepository _repository;
  Timer? _debounce;
  Completer<void>? _debounceCompleter;

  CustomerBloc(this._repository) : super(const CustomerState()) {
    on<CustomerLoadRequested>(_onLoadRequested);
    on<CustomerSearchChanged>(_onSearchChanged);
    on<CustomerByIdRequested>(_onByIdRequested);
    on<CustomerCreateRequested>(_onCreateRequested);
    on<CustomerUpdateRequested>(_onUpdateRequested);
    on<CustomerLoyaltyAdjusted>(_onLoyaltyAdjusted);
    on<CustomerBalanceAdjusted>(_onBalanceAdjusted);
  }

  Future<void> _onLoadRequested(
    CustomerLoadRequested event,
    Emitter<CustomerState> emit,
  ) async {
    emit(state.copyWith(status: CustomerStatus.loading, clearError: true));
    try {
      final customers = await _repository.getCustomers();
      emit(state.copyWith(status: CustomerStatus.loaded, customers: customers));
    } catch (e) {
      emit(
        state.copyWith(
          status: CustomerStatus.error,
          errorMessage: humanizeError(e),
        ),
      );
    }
  }

  Future<void> _onSearchChanged(
    CustomerSearchChanged event,
    Emitter<CustomerState> emit,
  ) async {
    emit(state.copyWith(query: event.query));
    _debounce?.cancel();
    if (_debounceCompleter?.isCompleted == false) {
      _debounceCompleter!.complete();
    }
    final completer = Completer<void>();
    _debounceCompleter = completer;
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        final customers = await _repository.getCustomers(search: event.query);
        if (!emit.isDone) {
          emit(
            state.copyWith(
              status: CustomerStatus.loaded,
              customers: customers,
              query: event.query,
            ),
          );
        }
      } catch (e) {
        if (!emit.isDone) {
          emit(
            state.copyWith(
              status: CustomerStatus.error,
              errorMessage: humanizeError(e),
            ),
          );
        }
      } finally {
        if (!completer.isCompleted) completer.complete();
      }
    });
    await completer.future;
  }

  Future<void> _onByIdRequested(
    CustomerByIdRequested event,
    Emitter<CustomerState> emit,
  ) async {
    emit(state.copyWith(status: CustomerStatus.loading, clearError: true));
    try {
      final customer = await _repository.getCustomerById(event.id);
      emit(state.copyWith(status: CustomerStatus.loaded, selected: customer));
    } catch (e) {
      emit(
        state.copyWith(
          status: CustomerStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onCreateRequested(
    CustomerCreateRequested event,
    Emitter<CustomerState> emit,
  ) async {
    emit(state.copyWith(status: CustomerStatus.creating, clearError: true));
    try {
      final created = await _repository.createCustomer(event.customer);
      final updatedList = [created, ...state.customers];
      emit(
        state.copyWith(
          status: CustomerStatus.loaded,
          customers: updatedList,
          selected: created,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: CustomerStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onUpdateRequested(
    CustomerUpdateRequested event,
    Emitter<CustomerState> emit,
  ) async {
    emit(state.copyWith(status: CustomerStatus.updating, clearError: true));
    try {
      final updated = await _repository.updateCustomer(
        event.id,
        event.customer,
      );
      emit(
        state.copyWith(
          status: CustomerStatus.loaded,
          selected: updated,
          customers: _replaceInList(state.customers, updated),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: CustomerStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onLoyaltyAdjusted(
    CustomerLoyaltyAdjusted event,
    Emitter<CustomerState> emit,
  ) async {
    emit(state.copyWith(status: CustomerStatus.updating, clearError: true));
    try {
      final updated = await _repository.adjustLoyaltyPoints(
        event.id,
        event.delta,
      );
      emit(
        state.copyWith(
          status: CustomerStatus.loaded,
          selected: updated,
          customers: _replaceInList(state.customers, updated),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: CustomerStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onBalanceAdjusted(
    CustomerBalanceAdjusted event,
    Emitter<CustomerState> emit,
  ) async {
    emit(state.copyWith(status: CustomerStatus.updating, clearError: true));
    try {
      final updated = await _repository.adjustBalance(event.id, event.delta);
      emit(
        state.copyWith(
          status: CustomerStatus.loaded,
          selected: updated,
          customers: _replaceInList(state.customers, updated),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: CustomerStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  List<Customer> _replaceInList(List<Customer> list, Customer updated) {
    return list.map((e) => e.id == updated.id ? updated : e).toList();
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    if (_debounceCompleter?.isCompleted == false) {
      _debounceCompleter!.complete();
    }
    return super.close();
  }
}
