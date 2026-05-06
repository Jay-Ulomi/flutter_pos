import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/repositories/auth_repository.dart';
import 'branch_event.dart';
import 'branch_state.dart';

class BranchBloc extends Bloc<BranchEvent, BranchState> {
  final AuthRepository _authRepository;

  BranchBloc(this._authRepository) : super(const BranchState()) {
    on<BranchLoadRequested>(_onLoadRequested);
    on<BranchSelected>(_onSelected);
  }

  Future<void> _onLoadRequested(
    BranchLoadRequested event,
    Emitter<BranchState> emit,
  ) async {
    emit(state.copyWith(status: BranchStatus.loading, clearError: true));
    try {
      final branches = await _authRepository.getBranches(event.businessId);
      emit(state.copyWith(status: BranchStatus.loaded, branches: branches));
    } catch (e) {
      emit(
        state.copyWith(status: BranchStatus.error, errorMessage: e.toString()),
      );
    }
  }

  Future<void> _onSelected(
    BranchSelected event,
    Emitter<BranchState> emit,
  ) async {
    final branch = state.branches.firstWhere(
      (b) => b.id == event.branchId,
      orElse: () => state.branches.isNotEmpty
          ? state.branches.first
          : throw StateError('No branches available'),
    );
    emit(state.copyWith(status: BranchStatus.selected, selected: branch));
  }
}
