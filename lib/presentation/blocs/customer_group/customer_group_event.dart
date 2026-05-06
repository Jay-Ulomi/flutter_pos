import 'package:equatable/equatable.dart';

import '../../../data/models/customer_models.dart';

abstract class CustomerGroupEvent extends Equatable {
  const CustomerGroupEvent();
  @override
  List<Object?> get props => [];
}

class CustomerGroupsLoadRequested extends CustomerGroupEvent {
  const CustomerGroupsLoadRequested();
}

class CustomerGroupCreateRequested extends CustomerGroupEvent {
  final CustomerGroup group;
  const CustomerGroupCreateRequested(this.group);
  @override
  List<Object?> get props => [group];
}

class CustomerGroupUpdateRequested extends CustomerGroupEvent {
  final String id;
  final CustomerGroup group;
  const CustomerGroupUpdateRequested(this.id, this.group);
  @override
  List<Object?> get props => [id, group];
}

class CustomerGroupDeleteRequested extends CustomerGroupEvent {
  final String id;
  const CustomerGroupDeleteRequested(this.id);
  @override
  List<Object?> get props => [id];
}
