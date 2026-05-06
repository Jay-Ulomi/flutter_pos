import 'package:equatable/equatable.dart';

import '../../../data/models/business_models.dart';

enum BranchStatus { initial, loading, loaded, selected, error }

class BranchState extends Equatable {
  final BranchStatus status;
  final List<Branch> branches;
  final Branch? selected;
  final String? errorMessage;

  const BranchState({
    this.status = BranchStatus.initial,
    this.branches = const [],
    this.selected,
    this.errorMessage,
  });

  BranchState copyWith({
    BranchStatus? status,
    List<Branch>? branches,
    Branch? selected,
    String? errorMessage,
    bool clearError = false,
  }) {
    return BranchState(
      status: status ?? this.status,
      branches: branches ?? this.branches,
      selected: selected ?? this.selected,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, branches, selected, errorMessage];
}
