import 'package:equatable/equatable.dart';

abstract class BusinessEvent extends Equatable {
  const BusinessEvent();
  @override
  List<Object?> get props => [];
}

class BusinessLoadRequested extends BusinessEvent {
  const BusinessLoadRequested();
}

class BusinessSelected extends BusinessEvent {
  final String businessId;
  const BusinessSelected(this.businessId);
  @override
  List<Object?> get props => [businessId];
}
