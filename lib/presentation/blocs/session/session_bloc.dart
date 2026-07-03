import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/error_message.dart';
import '../../../data/models/session_models.dart';
import '../../../domain/repositories/sale_repository.dart';
import '../../../domain/repositories/session_repository.dart';
import 'session_event.dart';
import 'session_state.dart';

class SessionBloc extends Bloc<SessionEvent, SessionState> {
  final SessionRepository _repository;
  final SaleRepository _saleRepository;

  SessionBloc(this._repository, this._saleRepository)
      : super(const SessionState()) {
    on<SessionLoadRequested>(_onLoadRequested);
    on<SessionOpenRequested>(_onOpenRequested);
    on<SessionCloseRequested>(_onCloseRequested);
    on<SessionSummaryRequested>(_onSummaryRequested);
  }

  Future<void> _onLoadRequested(
    SessionLoadRequested event,
    Emitter<SessionState> emit,
  ) async {
    emit(state.copyWith(status: SessionStatus.loading, clearError: true));
    try {
      final session = await _repository.getCurrentSession();
      if (session != null && session.isOpen) {
        emit(state.copyWith(status: SessionStatus.open, current: session));
      } else {
        emit(state.copyWith(status: SessionStatus.closed, clearCurrent: true));
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: SessionStatus.error,
          errorMessage: humanizeError(e),
        ),
      );
    }
  }

  Future<void> _onOpenRequested(
    SessionOpenRequested event,
    Emitter<SessionState> emit,
  ) async {
    emit(state.copyWith(status: SessionStatus.loading, clearError: true));
    try {
      final session = await _repository.openSession(
        OpenSessionRequest(openingCash: event.openingCash, notes: event.notes),
      );
      emit(state.copyWith(status: SessionStatus.open, current: session));
    } catch (e) {
      emit(
        state.copyWith(
          status: SessionStatus.error,
          errorMessage: humanizeError(e),
        ),
      );
    }
  }

  Future<void> _onCloseRequested(
    SessionCloseRequested event,
    Emitter<SessionState> emit,
  ) async {
    // Block closing while sales are still queued locally — the server would
    // finalize the shift summary before those sales arrive, corrupting the
    // reported cash/totals (and the sales could post into a closed session).
    final pending = await _saleRepository.getPendingSaleCount();
    if (pending > 0) {
      emit(
        state.copyWith(
          status: SessionStatus.error,
          errorMessage:
              'Cannot close: $pending sale${pending == 1 ? '' : 's'} still '
              'waiting to sync. Sync them first (Sync → Push Queue), then close.',
        ),
      );
      return;
    }
    emit(state.copyWith(status: SessionStatus.loading, clearError: true));
    try {
      await _repository.closeSession(
        CloseSessionRequest(
          sessionId: event.sessionId,
          closingCash: event.closingCash,
          notes: event.notes,
        ),
      );
      emit(
        state.copyWith(
          status: SessionStatus.closed,
          clearCurrent: true,
          clearSummary: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: SessionStatus.error,
          errorMessage: humanizeError(e),
        ),
      );
    }
  }

  Future<void> _onSummaryRequested(
    SessionSummaryRequested event,
    Emitter<SessionState> emit,
  ) async {
    try {
      final summary = await _repository.getSessionSummary(event.sessionId);
      emit(state.copyWith(summary: summary));
    } catch (e) {
      emit(state.copyWith(errorMessage: humanizeError(e)));
    }
  }
}
