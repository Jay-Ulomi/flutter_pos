import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../data/datasources/remote/password_reset_remote.dart';
import '../../../di/injection.dart';
import '../../blocs/password_reset/password_reset_cubit.dart';
import '../../widgets/aduinola/otp_boxes.dart';
import '../../widgets/aduinola/ui.dart';

/// Forgot password: email → 6-digit code (with resend timer) → new password.
class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key, this.cubit});

  /// Injected in tests; otherwise built from the DI remote.
  final PasswordResetCubit? cubit;

  @override
  Widget build(BuildContext context) {
    final existing = cubit;
    if (existing != null) {
      return BlocProvider.value(value: existing, child: const _ForgotPasswordView());
    }
    return BlocProvider(
      create: (_) => PasswordResetCubit(sl<PasswordResetRemoteDataSource>()),
      child: const _ForgotPasswordView(),
    );
  }
}

class _ForgotPasswordView extends StatelessWidget {
  const _ForgotPasswordView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PasswordResetCubit, PasswordResetState>(
      builder: (context, state) {
        final cubit = context.read<PasswordResetCubit>();
        final title = switch (state.step) {
          ResetStep.email => context.tr('auth.forgot_title'),
          ResetStep.code => context.tr('auth.otp_title'),
          ResetStep.password || ResetStep.done => context.tr('auth.new_password_title'),
        };
        return PopScope(
          canPop: state.step == ResetStep.email || state.step == ResetStep.done,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) cubit.back();
          },
          child: GradientScaffold(
            title: title,
            leading: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Center(
                child: RoundIconButton(
                  icon: Icons.arrow_back_rounded,
                  tooltip: 'Back',
                  size: 40,
                  onPressed: () {
                    if (state.step == ResetStep.email || state.step == ResetStep.done) {
                      _leave(context);
                    } else {
                      cubit.back();
                    }
                  },
                ),
              ),
            ),
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: switch (state.step) {
                        ResetStep.email => _EmailStep(key: const ValueKey('email'), state: state),
                        ResetStep.code => _CodeStep(key: const ValueKey('code'), state: state),
                        ResetStep.password => _PasswordStep(key: const ValueKey('pw'), state: state),
                        ResetStep.done => const _DoneStep(key: ValueKey('done')),
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

void _leave(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go('/login');
  }
}

String _errorText(BuildContext context, String error) =>
    error.startsWith('auth.') ? context.tr(error) : error;

Widget _errorLine(BuildContext context, String? error) {
  if (error == null) return const SizedBox(height: 8);
  return Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Text(
      _errorText(context, error),
      key: const ValueKey('reset-error'),
      textAlign: TextAlign.center,
      style: TextStyle(color: Theme.of(context).colorScheme.error),
    ),
  );
}

Widget _stepIcon(BuildContext context, IconData icon) {
  final cs = Theme.of(context).colorScheme;
  return Center(
    child: Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(color: cs.primaryContainer, shape: BoxShape.circle),
      child: Icon(icon, size: 34, color: cs.primary),
    ),
  );
}

Widget _busyChild(bool busy, String label) => busy
    ? const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
      )
    : Text(label);

class _EmailStep extends StatefulWidget {
  const _EmailStep({super.key, required this.state});
  final PasswordResetState state;

  @override
  State<_EmailStep> createState() => _EmailStepState();
}

class _EmailStepState extends State<_EmailStep> {
  late final _ctrl = TextEditingController(text: widget.state.email);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _send() => context.read<PasswordResetCubit>().requestCode(_ctrl.text);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _stepIcon(context, Icons.mark_email_unread_outlined),
        const SizedBox(height: 20),
        Text(
          context.tr('auth.forgot_body'),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
        TextField(
          key: const ValueKey('reset-email'),
          controller: _ctrl,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          autofillHints: const [AutofillHints.email],
          textInputAction: TextInputAction.send,
          onSubmitted: (_) => _send(),
          decoration: InputDecoration(
            hintText: context.tr('auth.email'),
            prefixIcon: const Icon(Icons.mail_outline_rounded),
          ),
        ),
        _errorLine(context, widget.state.error),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: widget.state.busy ? null : _send,
          child: _busyChild(widget.state.busy, context.tr('auth.send_code')),
        ),
      ],
    );
  }
}

class _CodeStep extends StatefulWidget {
  const _CodeStep({super.key, required this.state});
  final PasswordResetState state;

  @override
  State<_CodeStep> createState() => _CodeStepState();
}

class _CodeStepState extends State<_CodeStep> {
  final _otpKey = GlobalKey<OtpBoxesState>();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cubit = context.read<PasswordResetCubit>();
    final state = widget.state;
    final at = state.resendAvailableAt;
    final wait = at == null ? 0 : at.difference(DateTime.now()).inSeconds + 1;
    final canResend = wait <= 0 || at == null || DateTime.now().isAfter(at);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _stepIcon(context, Icons.pin_outlined),
        const SizedBox(height: 20),
        Text(
          context.tr('auth.otp_body', {'email': state.email}),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
        OtpBoxes(key: _otpKey, onCompleted: cubit.verify),
        _errorLine(context, state.error),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: state.busy ? null : () => cubit.verify(_otpKey.currentState?.value ?? ''),
          child: _busyChild(state.busy, context.tr('auth.verify')),
        ),
        const SizedBox(height: 12),
        Center(
          child: canResend
              ? TextButton(
                  key: const ValueKey('resend'),
                  onPressed: state.busy
                      ? null
                      : () {
                          _otpKey.currentState?.clear();
                          cubit.resend();
                        },
                  child: Text(context.tr('auth.resend')),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    context.tr('auth.resend_in', {'seconds': wait}),
                    key: const ValueKey('resend-timer'),
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
        ),
        Text(
          context.tr(state.codesSent >= PasswordResetCubit.rateLimitHintAfter
              ? 'auth.rate_limited'
              : 'auth.code_sent'),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _PasswordStep extends StatefulWidget {
  const _PasswordStep({super.key, required this.state});
  final PasswordResetState state;

  @override
  State<_PasswordStep> createState() => _PasswordStepState();
}

class _PasswordStepState extends State<_PasswordStep> {
  final _pw = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _pw.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _save() => context.read<PasswordResetCubit>().setPassword(_pw.text, _confirm.text);

  @override
  Widget build(BuildContext context) {
    final toggle = IconButton(
      tooltip: _obscure ? 'Show password' : 'Hide password',
      icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
      onPressed: () => setState(() => _obscure = !_obscure),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _stepIcon(context, Icons.lock_reset_rounded),
        const SizedBox(height: 24),
        TextField(
          key: const ValueKey('new-password'),
          controller: _pw,
          obscureText: _obscure,
          autofillHints: const [AutofillHints.newPassword],
          decoration: InputDecoration(
            hintText: context.tr('auth.new_password'),
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: toggle,
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          key: const ValueKey('confirm-password'),
          controller: _confirm,
          obscureText: _obscure,
          onSubmitted: (_) => _save(),
          decoration: InputDecoration(
            hintText: context.tr('auth.confirm_password'),
            prefixIcon: const Icon(Icons.lock_outline_rounded),
          ),
        ),
        _errorLine(context, widget.state.error),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: widget.state.busy ? null : _save,
          child: _busyChild(widget.state.busy, context.tr('auth.set_password')),
        ),
      ],
    );
  }
}

class _DoneStep extends StatelessWidget {
  const _DoneStep({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _stepIcon(context, Icons.check_rounded),
        const SizedBox(height: 20),
        Text(
          context.tr('auth.password_changed'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => _leave(context),
          child: Text(context.tr('auth.back_to_login')),
        ),
      ],
    );
  }
}
