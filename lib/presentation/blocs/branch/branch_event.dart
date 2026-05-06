import 'package:equatable/equatable.dart';

abstract class BranchEvent extends Equatable {
  const BranchEvent();
  @override
  List<Object?> get props => [];
}

class BranchLoadRequested extends BranchEvent {
  final String businessId;
  const BranchLoadRequested(this.businessId);
  @override
  List<Object?> get props => [businessId];
}

class BranchSelected extends BranchEvent {
  final String branchId;
  const BranchSelected(this.branchId);
  @override
  List<Object?> get props => [branchId];
}
