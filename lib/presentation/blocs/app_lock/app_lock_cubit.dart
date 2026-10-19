import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/security/app_lock_service.dart';

class AppLockState extends Equatable {
  const AppLockState({
    this.enabled = false,
    this.locked = false,
    this.failedAttempts = 0,
    this.retryAfter,
    this.checking = false,
  });

  final bool enabled;
  final bool locked;
  final int failedAttempts;

  /// Set after too many wrong PINs; entry is refused until then.
  final DateTime? retryAfter;
  final bool checking;

  AppLockState copyWith({
    bool? enabled,
    bool? locked,
    int? failedAttempts,
    DateTime? retryAfter,
    bool clearRetry = false,
    bool? checking,
  }) {
    return AppLockState(
      enabled: enabled ?? this.enabled,
      locked: locked ?? this.locked,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      retryAfter: clearRetry ? null : (retryAfter ?? this.retryAfter),
      checking: checking ?? this.checking,
    );
  }

  @override
  List<Object?> get props => [enabled, locked, failedAttempts, retryAfter, checking];
}

/// Device app lock: locks on cold start and after the app has been in the
/// background for longer than the configured timeout.
class AppLockCubit extends Cubit<AppLockState> {
  AppLockCubit(this._service, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now,
        super(const AppLockState());

  final AppLockService _service;
  final DateTime Function() _clock;
  DateTime? _backgroundedAt;

  static const maxAttempts = 5;
  static const cooldown = Duration(seconds: 30);

  /// Called at start-up with the persisted on/off flag.
  Future<void> init({required bool enabled}) async {
    final active = enabled && await _service.hasPin();
    emit(AppLockState(enabled: active, locked: active));
  }

  void onBackgrounded() {
    if (state.enabled) _backgroundedAt ??= _clock();
  }

  void onResumed({required int lockAfterMinutes}) {
    final since = _backgroundedAt;
    _backgroundedAt = null;
    if (!state.enabled || since == null || state.locked) return;
    if (_clock().difference(since) >= Duration(minutes: lockAfterMinutes)) {
      emit(state.copyWith(locked: true));
    }
  }

  /// Returns true when the PIN was right and the app is unlocked.
  Future<bool> unlock(String pin) async {
    final until = state.retryAfter;
    if (until != null && _clock().isBefore(until)) return false;
    emit(state.copyWith(checking: true));
    final ok = await _service.verify(pin);
    if (ok) {
      emit(state.copyWith(locked: false, failedAttempts: 0, clearRetry: true, checking: false));
      return true;
    }
    final attempts = state.failedAttempts + 1;
    if (attempts >= maxAttempts) {
      emit(state.copyWith(failedAttempts: 0, retryAfter: _clock().add(cooldown), checking: false));
    } else {
      emit(state.copyWith(failedAttempts: attempts, clearRetry: true, checking: false));
    }
    return false;
  }

  Future<void> enable(String pin) async {
    await _service.setPin(pin);
    emit(const AppLockState(enabled: true));
  }

  Future<void> disable() async {
    await _service.clearPin();
    emit(const AppLockState());
  }

  /// "Forgot PIN": the caller signs the user out; the PIN is removed so the
  /// next person to log in is not locked out.
  Future<void> reset() => disable();
}
