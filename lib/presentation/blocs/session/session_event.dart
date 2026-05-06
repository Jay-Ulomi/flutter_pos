import 'package:equatable/equatable.dart';

abstract class SessionEvent extends Equatable {
  const SessionEvent();
  @override
  List<Object?> get props => [];
}

class SessionLoadRequested extends SessionEvent {
  const SessionLoadRequested();
}

class SessionOpenRequested extends SessionEvent {
  final double openingCash;
  final String? notes;
  const SessionOpenRequested({required this.openingCash, this.notes});
  @override
  List<Object?> get props => [openingCash, notes];
}

class SessionCloseRequested extends SessionEvent {
  final String sessionId;
  final double closingCash;
  final String? notes;
  const SessionCloseRequested({
    required this.sessionId,
    required this.closingCash,
    this.notes,
  });
  @override
  List<Object?> get props => [sessionId, closingCash, notes];
}

class SessionSummaryRequested extends SessionEvent {
  final String sessionId;
  const SessionSummaryRequested(this.sessionId);
  @override
  List<Object?> get props => [sessionId];
}
