import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/exceptions.dart';
import '../../../data/datasources/remote/password_reset_remote.dart';

enum ResetStep { email, code, password, done }

class PasswordResetState extends Equatable {
  const PasswordResetState({
    this.step = ResetStep.email,
    this.email = '',
    this.resetToken,
    this.busy = false,
    this.error,
    this.codesSent = 0,
    this.resendAvailableAt,
  });

  final ResetStep step;
  final String email;
  final String? resetToken;
  final bool busy;

  /// A server message, or an `auth.*` string key for local validation.
  final String? error;

  /// Codes requested in this flow; after a few we suggest waiting (the
  /// server allows 5 an hour and stays silent past that).
  final int codesSent;
  final DateTime? resendAvailableAt;

  PasswordResetState copyWith({
    ResetStep? step,
    String? email,
    String? resetToken,
    bool? busy,
    String? error,
    bool clearError = false,
    int? codesSent,
    DateTime? resendAvailableAt,
  }) {
    return PasswordResetState(
      step: step ?? this.step,
      email: email ?? this.email,
      resetToken: resetToken ?? this.resetToken,
      busy: busy ?? this.busy,
      error: clearError ? null : (error ?? this.error),
      codesSent: codesSent ?? this.codesSent,
      resendAvailableAt: resendAvailableAt ?? this.resendAvailableAt,
    );
  }

  @override
  List<Object?> get props => [step, email, resetToken, busy, error, codesSent, resendAvailableAt];
}

/// Forgot password: email → 6-digit code → new password.
class PasswordResetCubit extends Cubit<PasswordResetState> {
  PasswordResetCubit(this._remote, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now,
        super(const PasswordResetState());

  final PasswordResetRemoteDataSource _remote;
  final DateTime Function() _clock;

  static const resendDelay = Duration(seconds: 60);

  /// Past this many codes the screen shows the "try again later" hint.
  static const rateLimitHintAfter = 3;

  static final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static bool isEmail(String v) => _emailRe.hasMatch(v.trim());

  Future<void> requestCode(String email) async {
    if (!isEmail(email)) {
      emit(state.copyWith(error: 'auth.invalid_email'));
      return;
    }
    emit(state.copyWith(busy: true, clearError: true, email: email.trim()));
    try {
      await _remote.requestCode(email);
      emit(state.copyWith(
        busy: false,
        step: ResetStep.code,
        codesSent: state.codesSent + 1,
        resendAvailableAt: _clock().add(resendDelay),
      ));
    } on ServerException catch (e) {
      emit(state.copyWith(busy: false, error: e.message));
    } catch (_) {
      emit(state.copyWith(busy: false, error: 'Could not send the code. Check your connection.'));
    }
  }

  Future<void> resend() async {
    final at = state.resendAvailableAt;
    if (at != null && _clock().isBefore(at)) return;
    await requestCode(state.email);
  }

  Future<void> verify(String code) async {
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      emit(state.copyWith(error: 'auth.enter_code'));
      return;
    }
    emit(state.copyWith(busy: true, clearError: true));
    try {
      final token = await _remote.verifyCode(state.email, code);
      emit(state.copyWith(busy: false, resetToken: token, step: ResetStep.password));
    } on ServerException catch (e) {
      emit(state.copyWith(busy: false, error: e.message));
    } catch (_) {
      emit(state.copyWith(busy: false, error: 'Could not verify the code. Check your connection.'));
    }
  }

  Future<void> setPassword(String password, String confirm) async {
    if (password.length < 8) {
      emit(state.copyWith(error: 'auth.password_short'));
      return;
    }
    if (password != confirm) {
      emit(state.copyWith(error: 'auth.passwords_mismatch'));
      return;
    }
    emit(state.copyWith(busy: true, clearError: true));
    try {
      await _remote.resetPassword(state.resetToken!, password);
      emit(state.copyWith(busy: false, step: ResetStep.done));
    } on ServerException catch (e) {
      emit(state.copyWith(busy: false, error: e.message));
    } catch (_) {
      emit(state.copyWith(busy: false, error: 'Could not change the password. Check your connection.'));
    }
  }

  void back() {
    switch (state.step) {
      case ResetStep.code:
        emit(state.copyWith(step: ResetStep.email, clearError: true));
      case ResetStep.password:
        emit(state.copyWith(step: ResetStep.code, clearError: true));
      default:
        break;
    }
  }
}
