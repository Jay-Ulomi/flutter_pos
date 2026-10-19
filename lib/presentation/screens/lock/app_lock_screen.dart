import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/l10n/app_strings.dart';
import '../../blocs/app_lock/app_lock_cubit.dart';
import '../../widgets/aduinola/pin_pad.dart';
import '../../widgets/aduinola/ui.dart';

/// Full-screen PIN prompt shown over the app while [AppLockCubit] is locked.
class AppLockScreen extends StatefulWidget {
  const AppLockScreen({super.key, required this.onForgot});

  /// Signs the user out and clears the PIN.
  final VoidCallback onForgot;

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  final _padKey = GlobalKey<PinPadState>();
  String? _error;
  Timer? _ticker;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _submit(String pin) async {
    final cubit = context.read<AppLockCubit>();
    final ok = await cubit.unlock(pin);
    if (!mounted || ok) return;
    _padKey.currentState?.clear();
    final s = cubit.state;
    setState(() {
      _error = s.retryAfter != null
          ? null
          : context.tr('lock.wrong_pin', {'left': AppLockCubit.maxAttempts - s.failedAttempts});
    });
    if (s.retryAfter != null) {
      _ticker?.cancel();
      _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) return t.cancel();
        setState(() {});
        if (DateTime.now().isAfter(s.retryAfter!)) t.cancel();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return BlocBuilder<AppLockCubit, AppLockState>(
      builder: (context, state) {
        final until = state.retryAfter;
        final waiting = until != null && DateTime.now().isBefore(until);
        final message = waiting
            ? context.tr('lock.too_many',
                {'seconds': until.difference(DateTime.now()).inSeconds + 1})
            : _error;
        return GradientScaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const BrandWordmark(height: 44),
                    const SizedBox(height: 28),
                    Icon(Icons.lock_rounded, color: cs.primary, size: 32),
                    const SizedBox(height: 8),
                    Text(context.tr('lock.enter_pin'),
                        style: Theme.of(context).textTheme.titleLarge),
                    SizedBox(
                      height: 28,
                      child: message == null
                          ? null
                          : Center(
                              child: Text(message,
                                  key: const ValueKey('lock-error'),
                                  style: TextStyle(color: cs.error)),
                            ),
                    ),
                    const SizedBox(height: 8),
                    PinPad(key: _padKey, onCompleted: _submit, enabled: !waiting && !state.checking),
                    const SizedBox(height: 16),
                    TextButton(onPressed: widget.onForgot, child: Text(context.tr('lock.forgot'))),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Two-step "create / confirm PIN" sheet. Returns the PIN, or null if dismissed.
Future<String?> showCreatePinSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _CreatePinSheet(),
  );
}

class _CreatePinSheet extends StatefulWidget {
  const _CreatePinSheet();

  @override
  State<_CreatePinSheet> createState() => _CreatePinSheetState();
}

class _CreatePinSheetState extends State<_CreatePinSheet> {
  final _padKey = GlobalKey<PinPadState>();
  String? _first;
  String? _error;

  void _onPin(String pin) {
    if (_first == null) {
      setState(() {
        _first = pin;
        _error = null;
      });
      _padKey.currentState?.clear();
    } else if (_first == pin) {
      Navigator.of(context).pop(pin);
    } else {
      setState(() {
        _first = null;
        _error = context.tr('lock.pins_mismatch');
      });
      _padKey.currentState?.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.tr(_first == null ? 'lock.create_pin' : 'lock.confirm_pin'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(
              height: 28,
              child: _error == null
                  ? null
                  : Center(
                      child: Text(_error!,
                          style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    ),
            ),
            PinPad(key: _padKey, onCompleted: _onPin),
          ],
        ),
      ),
    );
  }
}
