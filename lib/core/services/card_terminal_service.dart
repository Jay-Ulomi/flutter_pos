import 'dart:math';

/// Result returned after a card terminal payment attempt.
class CardTerminalResult {
  final CardTerminalStatus status;
  /// Authorization / transaction reference (populated on APPROVED).
  final String? reference;
  final String? errorMessage;

  const CardTerminalResult({
    required this.status,
    this.reference,
    this.errorMessage,
  });

  bool get isApproved => status == CardTerminalStatus.approved;
}

enum CardTerminalStatus { approved, declined, cancelled, error }

/// Abstract interface for card terminal communication.
///
/// Swap implementations in [setupDependencies] to use a real SDK
/// (Stripe Terminal, Adyen In-Person Payments, etc.).
abstract class CardTerminalService {
  /// Returns true if a reader is connected and ready to accept payments.
  Future<bool> get isReady;

  /// Initiate a payment for [amountInCents] (integer, smallest currency unit).
  ///
  /// Displays any required prompts on the terminal device and resolves once
  /// the customer has approved or declined.
  Future<CardTerminalResult> processPayment({required int amountInCents});

  /// Cancel an in-flight payment request.
  Future<void> cancelPayment();
}

// ─────────────────────────────────────────────────────────────────────────────
// Mock implementation — used in development / demo mode.
// ─────────────────────────────────────────────────────────────────────────────

class MockCardTerminalService implements CardTerminalService {
  bool _isCancelled = false;

  @override
  Future<bool> get isReady async => true;

  @override
  Future<CardTerminalResult> processPayment({required int amountInCents}) async {
    _isCancelled = false;
    // Simulate terminal processing delay (2–3 s).
    await Future.delayed(const Duration(milliseconds: 2500));
    if (_isCancelled) {
      return const CardTerminalResult(
        status: CardTerminalStatus.cancelled,
        errorMessage: 'Payment cancelled by cashier.',
      );
    }
    // Generate a fake auth code.
    final ref = 'AUTH${_randomHex(8).toUpperCase()}';
    return CardTerminalResult(
      status: CardTerminalStatus.approved,
      reference: ref,
    );
  }

  @override
  Future<void> cancelPayment() async {
    _isCancelled = true;
  }

  static String _randomHex(int length) {
    final rng = Random.secure();
    final bytes = List.generate(length ~/ 2, (_) => rng.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stripe Terminal stub — wire up stripe_terminal package here.
// ─────────────────────────────────────────────────────────────────────────────

/// Stub for Stripe Terminal integration.
///
/// To activate:
/// 1. Add `stripe_terminal: ^3.x.x` to pubspec.yaml
/// 2. Follow Stripe Terminal setup (connection token endpoint, reader discovery)
/// 3. Replace [MockCardTerminalService] with this class in [setupDependencies]
///
/// ```dart
/// sl.registerLazySingleton<CardTerminalService>(
///   () => StripeCardTerminalService(fetchConnectionToken: () async {
///     // Call your backend: POST /api/stripe/terminal/connection-token
///     final resp = await sl<ApiClient>().post('/api/stripe/terminal/connection-token');
///     return resp.data['secret'];
///   }),
/// );
/// ```
class StripeCardTerminalService implements CardTerminalService {
  // ignore: unused_field
  final Future<String> Function() fetchConnectionToken;

  StripeCardTerminalService({required this.fetchConnectionToken});

  @override
  Future<bool> get isReady async {
    // TODO: return StripeTerminal.instance.connectedReader != null;
    return false;
  }

  @override
  Future<CardTerminalResult> processPayment({required int amountInCents}) async {
    // TODO:
    // 1. Create PaymentIntent on backend: POST /api/stripe/payment-intents
    // 2. Collect payment: StripeTerminal.instance.collectPaymentMethod(...)
    // 3. Confirm: StripeTerminal.instance.confirmPaymentIntent(...)
    // 4. Map result to CardTerminalResult
    throw UnimplementedError('Wire up stripe_terminal package');
  }

  @override
  Future<void> cancelPayment() async {
    // TODO: StripeTerminal.instance.cancelCollectPaymentMethod()
  }
}
