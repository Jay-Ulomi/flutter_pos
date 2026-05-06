import 'package:equatable/equatable.dart';

import '../../../data/models/customer_models.dart';

abstract class CustomerEvent extends Equatable {
  const CustomerEvent();
  @override
  List<Object?> get props => [];
}

class CustomerSearchChanged extends CustomerEvent {
  final String query;
  const CustomerSearchChanged(this.query);
  @override
  List<Object?> get props => [query];
}

class CustomerLoadRequested extends CustomerEvent {
  const CustomerLoadRequested();
}

class CustomerByIdRequested extends CustomerEvent {
  final String id;
  const CustomerByIdRequested(this.id);
  @override
  List<Object?> get props => [id];
}

class CustomerCreateRequested extends CustomerEvent {
  final Customer customer;
  const CustomerCreateRequested(this.customer);
  @override
  List<Object?> get props => [customer];
}

class CustomerUpdateRequested extends CustomerEvent {
  final String id;
  final Customer customer;
  const CustomerUpdateRequested(this.id, this.customer);
  @override
  List<Object?> get props => [id, customer];
}

class CustomerLoyaltyAdjusted extends CustomerEvent {
  final String id;
  final int delta;
  const CustomerLoyaltyAdjusted(this.id, this.delta);
  @override
  List<Object?> get props => [id, delta];
}

class CustomerBalanceAdjusted extends CustomerEvent {
  final String id;
  final double delta;
  const CustomerBalanceAdjusted(this.id, this.delta);
  @override
  List<Object?> get props => [id, delta];
}
