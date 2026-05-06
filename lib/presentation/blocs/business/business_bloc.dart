import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/repositories/auth_repository.dart';
import 'business_event.dart';
import 'business_state.dart';

class BusinessBloc extends Bloc<BusinessEvent, BusinessState> {
  final AuthRepository _authRepository;

  BusinessBloc(this._authRepository) : super(const BusinessState()) {
    on<BusinessLoadRequested>(_onLoadRequested);
    on<BusinessSelected>(_onBusinessSelected);
  }

  Future<void> _onLoadRequested(
    BusinessLoadRequested event,
    Emitter<BusinessState> emit,
  ) async {
    emit(state.copyWith(status: BusinessStatus.loading, clearError: true));
    try {
      final businesses = await _authRepository.getBusinesses();
      emit(
        state.copyWith(status: BusinessStatus.loaded, businesses: businesses),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: BusinessStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onBusinessSelected(
    BusinessSelected event,
    Emitter<BusinessState> emit,
  ) async {
    final business = state.businesses.firstWhere(
      (b) => b.id == event.businessId,
      orElse: () => state.businesses.isNotEmpty
          ? state.businesses.first
          : throw StateError('No businesses available'),
    );
    emit(state.copyWith(status: BusinessStatus.selected, selected: business));
  }
}
