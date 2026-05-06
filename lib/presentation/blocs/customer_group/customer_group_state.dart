import 'package:equatable/equatable.dart';

import '../../../data/models/customer_models.dart';

enum CustomerGroupStatus { initial, loading, loaded, mutating, error }

class CustomerGroupState extends Equatable {
  final CustomerGroupStatus status;
  final List<CustomerGroup> groups;
  final String? errorMessage;

  const CustomerGroupState({
    this.status = CustomerGroupStatus.initial,
    this.groups = const [],
    this.errorMessage,
  });

  CustomerGroupState copyWith({
    CustomerGroupStatus? status,
    List<CustomerGroup>? groups,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CustomerGroupState(
      status: status ?? this.status,
      groups: groups ?? this.groups,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, groups, errorMessage];
}
