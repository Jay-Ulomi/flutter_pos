import 'package:equatable/equatable.dart';

import '../../../data/models/session_models.dart';

enum SessionStatus { initial, loading, open, closed, error }

class SessionState extends Equatable {
  final SessionStatus status;
  final CashSession? current;
  final ShiftSummary? summary;
  final String? errorMessage;

  const SessionState({
    this.status = SessionStatus.initial,
    this.current,
    this.summary,
    this.errorMessage,
  });

  SessionState copyWith({
    SessionStatus? status,
    CashSession? current,
    ShiftSummary? summary,
    String? errorMessage,
    bool clearCurrent = false,
    bool clearSummary = false,
    bool clearError = false,
  }) {
    return SessionState(
      status: status ?? this.status,
      current: clearCurrent ? null : (current ?? this.current),
      summary: clearSummary ? null : (summary ?? this.summary),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, current, summary, errorMessage];
}
