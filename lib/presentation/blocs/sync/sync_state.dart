import 'package:equatable/equatable.dart';

import '../../../data/models/sync_models.dart';

enum SyncPhase { idle, loading, syncing, success, error }

class SyncBlocState extends Equatable {
  final SyncPhase phase;
  final SyncStatus status;
  final String? errorMessage;

  const SyncBlocState({
    this.phase = SyncPhase.idle,
    this.status = const SyncStatus(),
    this.errorMessage,
  });

  SyncBlocState copyWith({
    SyncPhase? phase,
    SyncStatus? status,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SyncBlocState(
      phase: phase ?? this.phase,
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [phase, status, errorMessage];
}
