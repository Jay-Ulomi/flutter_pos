import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/l10n/app_strings.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../widgets/aduinola/ui.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  /// SharedPreferences key holding the remembered email/username.
  static const rememberedLoginKey = 'login.remembered';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _passFocus = FocusNode();
  bool _obscure = true;
  bool _remember = false;

  @override
  void initState() {
    super.initState();
    _loadRemembered();
  }

  Future<void> _loadRemembered() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(LoginScreen.rememberedLoginKey);
    if (!mounted || saved == null) return;
    setState(() {
      _remember = true;
      if (_emailCtrl.text.isEmpty) _emailCtrl.text = saved;
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;
    final login = _emailCtrl.text.trim();
    // Only the email/username is remembered — never the password.
    final prefs = await SharedPreferences.getInstance();
    if (_remember) {
      await prefs.setString(LoginScreen.rememberedLoginKey, login);
    } else {
      await prefs.remove(LoginScreen.rememberedLoginKey);
    }
    if (!mounted) return;
    context.read<AuthBloc>().add(
          AuthLoginRequested(email: login, password: _passCtrl.text),
        );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GradientScaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listenWhen: (p, c) => p.errorMessage != c.errorMessage,
        listener: (context, state) {
          if (state.status == AuthStatus.error && state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: cs.error,
              ),
            );
          }
        },
        builder: (context, state) {
          final loading = state.status == AuthStatus.loading;
          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Form(
                    key: _formKey,
                    child: AutofillGroup(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: _form(loading),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _form(bool loading) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return [
      const Center(child: BrandWordmark(height: 48)),
      const SizedBox(height: 40),
      Text(context.tr('auth.welcome'),
          textAlign: TextAlign.center, style: theme.textTheme.headlineMedium),
      const SizedBox(height: 6),
      Text(
        context.tr('auth.subtitle'),
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
      ),
      const SizedBox(height: 32),
      TextFormField(
        key: const ValueKey('login-field'),
        controller: _emailCtrl,
        keyboardType: TextInputType.emailAddress,
        autocorrect: false,
        textInputAction: TextInputAction.next,
        autofillHints: const [AutofillHints.username, AutofillHints.email],
        onFieldSubmitted: (_) => _passFocus.requestFocus(),
        decoration: InputDecoration(
          hintText: context.tr('auth.login_field'),
          prefixIcon: const Icon(Icons.person_outline_rounded),
        ),
        validator: (v) =>
            v == null || v.trim().isEmpty ? context.tr('auth.login_field') : null,
      ),
      const SizedBox(height: 14),
      TextFormField(
        key: const ValueKey('password-field'),
        controller: _passCtrl,
        focusNode: _passFocus,
        obscureText: _obscure,
        textInputAction: TextInputAction.done,
        autofillHints: const [AutofillHints.password],
        onFieldSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          hintText: context.tr('auth.password'),
          prefixIcon: const Icon(Icons.lock_outline_rounded),
          suffixIcon: IconButton(
            tooltip: _obscure ? 'Show password' : 'Hide password',
            icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
        ),
        validator: (v) => v == null || v.isEmpty ? context.tr('auth.password') : null,
      ),
      const SizedBox(height: 6),
      Row(
        children: [
          Checkbox(
            value: _remember,
            onChanged: (v) => setState(() => _remember = v ?? false),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          ),
          GestureDetector(
            onTap: () => setState(() => _remember = !_remember),
            child: Text(context.tr('auth.remember_me')),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => context.push('/forgot-password'),
            child: Text(context.tr('auth.forgot')),
          ),
        ],
      ),
      const SizedBox(height: 18),
      FilledButton(
        onPressed: loading ? null : _submit,
        child: loading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
              )
            : Text(context.tr('auth.sign_in')),
      ),
      const SizedBox(height: 32),
      Center(
        child: Text(
          'Aduinola POS',
          style: theme.textTheme.bodySmall?.copyWith(letterSpacing: 0.5),
        ),
      ),
    ];
  }
}
