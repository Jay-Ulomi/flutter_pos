import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/brand_colors.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _emailFocus = FocusNode();
  final _passFocus = FocusNode();
  bool _obscure = true;
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeIn = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    context.read<AuthBloc>().add(
      AuthLoginRequested(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF183e0a),
      resizeToAvoidBottomInset: true,
      body: BlocConsumer<AuthBloc, AuthState>(
        listenWhen: (p, c) => p.errorMessage != c.errorMessage,
        listener: (context, state) {
          if (state.status == AuthStatus.error && state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(state.errorMessage!)),
                  ],
                ),
                backgroundColor: BrandColors.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                margin: const EdgeInsets.all(16),
              ),
            );
          }
        },
        builder: (context, state) {
          final loading = state.status == AuthStatus.loading;
          // Same desktop breakpoint as ResponsiveShell — below it, the
          // full-bleed mobile sheet; at/above it, a centered bounded card.
          final isDesktop = MediaQuery.sizeOf(context).width >= 720;

          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF183e0a), Color(0xFF225412)],
              ),
            ),
            child: isDesktop ? _buildDesktop(loading) : _buildMobile(loading),
          );
        },
      ),
    );
  }

  // ── Mobile: green header + full-bleed white sheet ──
  Widget _buildMobile(bool loading) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          // ── Green brand header ──────────────────────────────────
          FadeTransition(
            opacity: _fadeIn,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 44, 28, 36),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/app_icon.png',
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Aduinola',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── White form card ─────────────────────────────────────
          Expanded(
            child: FadeTransition(
              opacity: _fadeIn,
              child: SlideTransition(
                position: _slideUp,
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 32, 28, 32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: _formFields(loading),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Desktop/PC: centered, bounded-width card on the brand gradient —
  // the mobile full-bleed sheet stretches ugly on a wide window. ──
  Widget _buildDesktop(bool loading) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: FadeTransition(
              opacity: _fadeIn,
              child: SlideTransition(
                position: _slideUp,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 40,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(36, 40, 36, 32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.asset(
                                    'assets/app_icon.png',
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                const Text(
                                  'Aduinola',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF111827),
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),
                          ..._formFields(loading),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Shared form contents (heading through footer), used by both layouts ──
  List<Widget> _formFields(bool loading) {
    return [
      // Heading
      const Text(
        'Welcome back',
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: Color(0xFF111827),
          letterSpacing: -0.5,
        ),
      ),
      const SizedBox(height: 6),
      const Text(
        'Sign in to access your POS terminal.',
        style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
      ),
      const SizedBox(height: 32),

      // Email
      _fieldLabel('Email address'),
      const SizedBox(height: 8),
      TextFormField(
        controller: _emailCtrl,
        focusNode: _emailFocus,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        onFieldSubmitted: (_) => _passFocus.requestFocus(),
        style: const TextStyle(fontSize: 15, color: Color(0xFF111827)),
        decoration: _inputDeco(
          hint: 'you@example.com',
          icon: Icons.mail_outline_rounded,
        ),
        validator: (v) {
          if (v == null || v.trim().isEmpty) {
            return 'Email is required';
          }
          if (!v.contains('@')) {
            return 'Enter a valid email';
          }
          return null;
        },
      ),

      const SizedBox(height: 20),

      // Password
      _fieldLabel('Password'),
      const SizedBox(height: 8),
      TextFormField(
        controller: _passCtrl,
        focusNode: _passFocus,
        obscureText: _obscure,
        textInputAction: TextInputAction.done,
        onFieldSubmitted: (_) => _submit(),
        style: const TextStyle(fontSize: 15, color: Color(0xFF111827)),
        decoration: _inputDeco(
          hint: '••••••••',
          icon: Icons.lock_outline_rounded,
          suffix: IconButton(
            tooltip: 'Toggle password visibility',
            icon: Icon(
              _obscure
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 20,
              color: const Color(0xFF9CA3AF),
            ),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
        ),
        validator: (v) =>
            v == null || v.isEmpty ? 'Password is required' : null,
      ),

      const SizedBox(height: 28),

      // Sign in button
      SizedBox(
        height: 52,
        child: FilledButton(
          onPressed: loading ? null : _submit,
          style: FilledButton.styleFrom(
            backgroundColor: BrandColors.primary,
            disabledBackgroundColor: BrandColors.primary.withValues(alpha: 0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
          child: loading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Sign in',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
        ),
      ),

      const SizedBox(height: 28),

      // Feature pills
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _FeaturePill(Icons.wifi_off_rounded, 'Offline'),
          const SizedBox(width: 8),
          _FeaturePill(Icons.sync_rounded, 'Auto-sync'),
          const SizedBox(width: 8),
          _FeaturePill(Icons.shield_outlined, 'Secure'),
        ],
      ),

      const SizedBox(height: 24),
      const Center(
        child: Text(
          'Powered by Aduinola',
          style: TextStyle(
            fontSize: 11,
            color: Color(0xFF9CA3AF),
            letterSpacing: 0.5,
          ),
        ),
      ),
    ];
  }

  Widget _fieldLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
        color: Color(0xFF9CA3AF),
      ),
    );
  }

  InputDecoration _inputDeco({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFD1D5DB), fontSize: 14),
      prefixIcon: Icon(icon, size: 20, color: const Color(0xFF9CA3AF)),
      prefixIconConstraints: const BoxConstraints(minWidth: 48),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: BrandColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: BrandColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: BrandColors.error, width: 1.5),
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeaturePill(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: BrandColors.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}
