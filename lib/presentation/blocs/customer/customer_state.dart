import 'package:equatable/equatable.dart';

import '../../../data/models/customer_models.dart';

enum CustomerStatus { initial, loading, loaded, creating, updating, error }

class CustomerState extends Equatable {
  final CustomerStatus status;
  final List<Customer> customers;
  final Customer? selected;
  final String query;
  final String? errorMessage;

  const CustomerState({
    this.status = CustomerStatus.initial,
    this.customers = const [],
    this.selected,
    this.query = '',
    this.errorMessage,
  });

  CustomerState copyWith({
    CustomerStatus? status,
    List<Customer>? customers,
    Customer? selected,
    String? query,
    String? errorMessage,
    bool clearError = false,
    bool clearSelected = false,
  }) {
    return CustomerState(
      status: status ?? this.status,
      customers: customers ?? this.customers,
      selected: clearSelected ? null : (selected ?? this.selected),
      query: query ?? this.query,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, customers, selected, query, errorMessage];
}
