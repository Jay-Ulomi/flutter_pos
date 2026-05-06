import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/repositories/customer_repository.dart';
import 'customer_group_event.dart';
import 'customer_group_state.dart';

class CustomerGroupBloc extends Bloc<CustomerGroupEvent, CustomerGroupState> {
  final CustomerRepository _repository;

  CustomerGroupBloc(this._repository) : super(const CustomerGroupState()) {
    on<CustomerGroupsLoadRequested>(_onLoad);
    on<CustomerGroupCreateRequested>(_onCreate);
    on<CustomerGroupUpdateRequested>(_onUpdate);
    on<CustomerGroupDeleteRequested>(_onDelete);
  }

  Future<void> _onLoad(
    CustomerGroupsLoadRequested event,
    Emitter<CustomerGroupState> emit,
  ) async {
    emit(state.copyWith(status: CustomerGroupStatus.loading, clearError: true));
    try {
      final groups = await _repository.getCustomerGroups();
      emit(state.copyWith(status: CustomerGroupStatus.loaded, groups: groups));
    } catch (e) {
      emit(
        state.copyWith(
          status: CustomerGroupStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onCreate(
    CustomerGroupCreateRequested event,
    Emitter<CustomerGroupState> emit,
  ) async {
    emit(
      state.copyWith(status: CustomerGroupStatus.mutating, clearError: true),
    );
    try {
      final created = await _repository.createCustomerGroup(event.group);
      emit(
        state.copyWith(
          status: CustomerGroupStatus.loaded,
          groups: [created, ...state.groups],
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: CustomerGroupStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onUpdate(
    CustomerGroupUpdateRequested event,
    Emitter<CustomerGroupState> emit,
  ) async {
    emit(
      state.copyWith(status: CustomerGroupStatus.mutating, clearError: true),
    );
    try {
      final updated = await _repository.updateCustomerGroup(
        event.id,
        event.group,
      );
      emit(
        state.copyWith(
          status: CustomerGroupStatus.loaded,
          groups: state.groups
              .map((g) => g.id == updated.id ? updated : g)
              .toList(),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: CustomerGroupStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onDelete(
    CustomerGroupDeleteRequested event,
    Emitter<CustomerGroupState> emit,
  ) async {
    emit(
      state.copyWith(status: CustomerGroupStatus.mutating, clearError: true),
    );
    try {
      await _repository.deleteCustomerGroup(event.id);
      emit(
        state.copyWith(
          status: CustomerGroupStatus.loaded,
          groups: state.groups.where((g) => g.id != event.id).toList(),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: CustomerGroupStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
