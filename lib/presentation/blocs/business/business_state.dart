import 'package:equatable/equatable.dart';

import '../../../data/models/business_models.dart';

enum BusinessStatus { initial, loading, loaded, selecting, selected, error }

class BusinessState extends Equatable {
  final BusinessStatus status;
  final List<Business> businesses;
  final Business? selected;
  final String? errorMessage;

  const BusinessState({
    this.status = BusinessStatus.initial,
    this.businesses = const [],
    this.selected,
    this.errorMessage,
  });

  BusinessState copyWith({
    BusinessStatus? status,
    List<Business>? businesses,
    Business? selected,
    String? errorMessage,
    bool clearError = false,
  }) {
    return BusinessState(
      status: status ?? this.status,
      businesses: businesses ?? this.businesses,
      selected: selected ?? this.selected,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, businesses, selected, errorMessage];
}
