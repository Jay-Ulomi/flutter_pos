import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/card_terminal_service.dart';
import '../../data/models/sale_models.dart';
import '../../di/injection.dart';
import '../blocs/cart/cart_bloc.dart';
import '../blocs/cart/cart_event.dart';
import '../blocs/cart/cart_state.dart';
import '../blocs/sale/sale_bloc.dart';
import '../blocs/sale/sale_event.dart';
import '../blocs/sale/sale_state.dart';
import '../blocs/session/session_bloc.dart';
import 'customer_picker_sheet.dart';
import 'money_text.dart';

enum PaymentMethod { cash, card, mobile, bankTransfer, credit, giftCard }

extension PaymentMethodX on PaymentMethod {
  String get apiName {
    switch (this) {
      case PaymentMethod.cash:
        return 'CASH';
      case PaymentMethod.card:
        return 'CARD';
      case PaymentMethod.mobile:
        return 'MOBILE_MONEY';
      case PaymentMethod.bankTransfer:
        return 'BANK_TRANSFER';
      case PaymentMethod.credit:
        return 'CREDIT';
      case PaymentMethod.giftCard:
        return 'GIFT_CARD';
    }
  }

  String get label {
    switch (this) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.card:
        return 'Card';
      case PaymentMethod.mobile:
        return 'Mobile';
      case PaymentMethod.bankTransfer:
        return 'Bank';
      case PaymentMethod.credit:
        return 'Credit';
      case PaymentMethod.giftCard:
        return 'Gift Card';
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentMethod.cash:
        return Icons.payments_outlined;
      case PaymentMethod.card:
        return Icons.credit_card;
      case PaymentMethod.mobile:
        return Icons.phone_android;
      case PaymentMethod.bankTransfer:
        return Icons.account_balance;
      case PaymentMethod.credit:
        return Icons.account_balance_wallet_outlined;
      case PaymentMethod.giftCard:
        return Icons.card_giftcard;
    }
  }

  bool get requiresReference {
    switch (this) {
      case PaymentMethod.card:
      case PaymentMethod.mobile:
      case PaymentMethod.bankTransfer:
      case PaymentMethod.giftCard:
        return true;
      case PaymentMethod.cash:
      case PaymentMethod.credit:
        return false;
    }
  }
}

class _PaymentEntry {
  PaymentMethod method;
  double amount;
  String? reference;
  _PaymentEntry({required this.method, required this.amount, this.reference});
}

/// Inline checkout panel for the POS screen (desktop) or standalone (mobile).
class CheckoutPanel extends StatefulWidget {
  final VoidCallback? onBack;

  /// Called on desktop when sale completes — show receipt inline instead of navigating.
  final VoidCallback? onSaleCompleted;
  const CheckoutPanel({super.key, this.onBack, this.onSaleCompleted});

  @override
  State<CheckoutPanel> createState() => _CheckoutPanelState();
}

class _CheckoutPanelState extends State<CheckoutPanel> {
  final List<_PaymentEntry> _payments = [];
  final _notesCtrl = TextEditingController();
  PaymentMethod _addMethod = PaymentMethod.cash;
  final _addAmountCtrl = TextEditingController();
  final _addReferenceCtrl = TextEditingController();
  final _couponCtrl = TextEditingController();
  bool _showNotes = false;

  // Coupon / promotion state
  String? _appliedCoupon;
  String? _couponError;
  bool _couponValidating = false;
  // discount as absolute amount (calculated after apply)
  double _couponDiscount = 0;

  // Card terminal state
  bool _terminalProcessing = false;
  String? _terminalError;

  @override
  void dispose() {
    _notesCtrl.dispose();
    _addAmountCtrl.dispose();
    _addReferenceCtrl.dispose();
    _couponCtrl.dispose();
    super.dispose();
  }

  Future<void> _applyCoupon(double cartSubtotal) async {
    final code = _couponCtrl.text.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() {
      _couponValidating = true;
      _couponError = null;
    });
    // Simple local validation — in production call /api/promotions/validate-coupon
    // For now, just store the code and let backend apply it; we show no preview discount.
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() {
      _appliedCoupon = code;
      _couponDiscount = 0; // backend will calculate final discount
      _couponValidating = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Coupon "$code" will be applied at checkout')),
    );
  }

  void _removeCoupon() {
    setState(() {
      _appliedCoupon = null;
      _couponDiscount = 0;
      _couponCtrl.clear();
      _couponError = null;
    });
  }

  double get _totalPaid => _payments.fold(0.0, (sum, p) => sum + p.amount);
  double _remaining(double total) => (total - _totalPaid).clamp(0, total);
  bool get _hasCreditPayment =>
      _payments.any((p) => p.method == PaymentMethod.credit);

  void _addPayment(double cartTotal) {
    final amount = double.tryParse(_addAmountCtrl.text) ?? 0;
    final reference = _addReferenceCtrl.text.trim();
    if (amount <= 0) return;
    if (_addMethod.requiresReference && reference.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_addMethod.label} reference is required')),
      );
      return;
    }
    setState(() {
      _payments.add(
        _PaymentEntry(
          method: _addMethod,
          amount: amount,
          reference: reference.isEmpty ? null : reference,
        ),
      );
      _addAmountCtrl.clear();
      _addReferenceCtrl.clear();
    });
  }

  Future<void> _chargeTerminal(double cartTotal) async {
    final amount = double.tryParse(_addAmountCtrl.text) ?? 0;
    final chargeAmount = amount > 0 ? amount : _remaining(cartTotal);
    if (chargeAmount <= 0) return;

    setState(() {
      _terminalProcessing = true;
      _terminalError = null;
    });

    final terminal = sl<CardTerminalService>();
    final amountInCents = (chargeAmount * 100).round();

    try {
      final result = await terminal.processPayment(amountInCents: amountInCents);
      if (!mounted) return;
      if (result.isApproved) {
        setState(() {
          _payments.add(_PaymentEntry(
            method: PaymentMethod.card,
            amount: chargeAmount,
            reference: result.reference,
          ));
          _addAmountCtrl.clear();
          _terminalProcessing = false;
          _terminalError = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Card approved — ref: ${result.reference}'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      } else {
        setState(() {
          _terminalProcessing = false;
          _terminalError = result.errorMessage ??
              (result.status == CardTerminalStatus.cancelled
                  ? 'Payment cancelled.'
                  : 'Card declined.');
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _terminalProcessing = false;
        _terminalError = 'Terminal error: $e';
      });
    }
  }

  void _addFullPayment(double cartTotal) {
    final remaining = _remaining(cartTotal);
    final reference = _addReferenceCtrl.text.trim();
    if (remaining <= 0) return;
    if (_addMethod.requiresReference && reference.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_addMethod.label} reference is required')),
      );
      return;
    }
    setState(() {
      _payments.add(
        _PaymentEntry(
          method: _addMethod,
          amount: remaining,
          reference: reference.isEmpty ? null : reference,
        ),
      );
      _addAmountCtrl.clear();
      _addReferenceCtrl.clear();
    });
  }

  void _removePayment(int index) {
    setState(() => _payments.removeAt(index));
  }

  void _complete(CartState cart) {
    final sessionId = context.read<SessionBloc>().state.current?.id;
    if (sessionId == null || sessionId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No active session found. Open a session first.'),
        ),
      );
      return;
    }
    if (_hasCreditPayment && !cart.hasCustomer) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A customer is required for credit payments.'),
        ),
      );
      return;
    }
    if (_totalPaid < cart.total) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment amount is less than total')),
      );
      return;
    }
    context.read<SaleBloc>().add(
      SaleCheckoutRequested(_buildSale(cart, sessionId)),
    );
  }

  Sale _buildSale(CartState cart, String sessionId) {
    final items = cart.lines
        .map(
          (l) => SaleItem(
            productId: l.product.id,
            productName: l.product.name,
            quantity: l.quantity,
            unitPrice: l.product.sellingPrice,
            discount: l.lineDiscount,
            taxAmount: l.lineTax,
            totalPrice: l.lineTotal,
            serialNumber: l.serialNumber,
            lotNumber: l.lotNumber,
          ),
        )
        .toList();
    final payments = _payments
        .map(
          (p) => SalePayment(
            method: p.method.apiName,
            amount: p.amount,
            reference: p.reference,
          ),
        )
        .toList();
    final change = (_totalPaid - cart.total)
        .clamp(0, double.infinity)
        .toDouble();
    return Sale(
      sessionId: sessionId,
      items: items,
      payments: payments,
      subtotal: cart.subtotal,
      taxAmount: cart.taxAmount,
      discountAmount:
          cart.discount +
          cart.lines.fold(0.0, (sum, l) => sum + l.lineDiscount),
      totalAmount: cart.total,
      paidAmount: _totalPaid,
      changeAmount: change,
      customerId: cart.selectedCustomerId,
      customerName: cart.selectedCustomerName,
      couponCode: _appliedCoupon,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );
  }

  Future<void> _pickCustomer() async {
    final picked = await showCustomerPickerSheet(context);
    if (picked == null || !mounted) return;
    if (picked.isWalkIn) {
      context.read<CartBloc>().add(const CartCustomerCleared());
    } else {
      final c = picked.customer!;
      context.read<CartBloc>().add(
        CartCustomerSelected(customerId: c.id, customerName: c.name),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return BlocConsumer<SaleBloc, SaleState>(
      listener: (context, state) {
        if (state.status == SaleStatus.completed ||
            state.status == SaleStatus.queuedOffline) {
          context.read<CartBloc>().add(const CartCleared());
          if (widget.onSaleCompleted != null) {
            widget.onSaleCompleted!();
          } else {
            context.go('/receipt');
          }
        } else if (state.status == SaleStatus.error &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        }
      },
      builder: (context, saleState) {
        return BlocBuilder<CartBloc, CartState>(
          builder: (context, cart) {
            final processing = saleState.status == SaleStatus.processing;
            final remaining = _remaining(cart.total);
            final change = (_totalPaid - cart.total)
                .clamp(0, double.infinity)
                .toDouble();
            final isPaid = _totalPaid >= cart.total && cart.isNotEmpty;

            return Column(
              children: [
                // ═══ Header with total ═══
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  color: colors.surfaceContainerLow,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          if (widget.onBack != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back),
                                onPressed: widget.onBack,
                                style: IconButton.styleFrom(
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ),
                          const Icon(Icons.payment),
                          const SizedBox(width: 8),
                          Text('Checkout', style: theme.textTheme.titleMedium),
                          const Spacer(),
                          // Customer chip
                          ActionChip(
                            avatar: Icon(
                              cart.hasCustomer
                                  ? Icons.person
                                  : Icons.person_outline,
                              size: 18,
                            ),
                            label: Text(
                              cart.hasCustomer
                                  ? cart.selectedCustomerName ?? 'Customer'
                                  : 'Walk-in',
                              overflow: TextOverflow.ellipsis,
                            ),
                            onPressed: _pickCustomer,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Big total display
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            'Total',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                          const Spacer(),
                          MoneyText(
                            cart.total,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colors.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ═══ Scrollable body ═══
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // ── Coupon code ──
                      if (_appliedCoupon == null) ...[
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _couponCtrl,
                                textCapitalization: TextCapitalization.characters,
                                decoration: InputDecoration(
                                  hintText: 'Coupon code (optional)',
                                  prefixIcon: const Icon(Icons.local_offer_outlined, size: 18),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  errorText: _couponError,
                                ),
                                onSubmitted: (_) => _applyCoupon(0),
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton.tonal(
                              onPressed: _couponValidating ? null : () => _applyCoupon(0),
                              child: _couponValidating
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text('Apply'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: colors.tertiaryContainer.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.local_offer, size: 18, color: colors.tertiary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Coupon: $_appliedCoupon',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: colors.onTertiaryContainer,
                                  ),
                                ),
                              ),
                              InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: _removeCoupon,
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(Icons.close, size: 16, color: colors.error),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // ── Payment method buttons ──
                      GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 1.8,
                        children: PaymentMethod.values.map((m) {
                          final selected = m == _addMethod;
                          return Material(
                            color: selected
                                ? colors.primaryContainer
                                : colors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => setState(() {
                                _addMethod = m;
                                if (!m.requiresReference) {
                                  _addReferenceCtrl.clear();
                                }
                              }),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    m.icon,
                                    size: 24,
                                    color: selected
                                        ? colors.onPrimaryContainer
                                        : colors.onSurfaceVariant,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    m.label,
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                          fontWeight: selected
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                          color: selected
                                              ? colors.onPrimaryContainer
                                              : colors.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      if (_addMethod == PaymentMethod.credit || _addMethod == PaymentMethod.giftCard)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 14,
                                color: colors.secondary,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _addMethod == PaymentMethod.giftCard
                                      ? 'Enter the gift card code as the reference. Balance will be deducted at checkout.'
                                      : 'Credit amount added to customer balance.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colors.secondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 16),

                      // ── Amount input ──
                      if (remaining > 0) ...[
                        if (_addMethod.requiresReference) ...[
                          TextField(
                            controller: _addReferenceCtrl,
                            textInputAction: TextInputAction.next,
                            textCapitalization: _addMethod == PaymentMethod.giftCard
                                ? TextCapitalization.characters
                                : TextCapitalization.none,
                            decoration: InputDecoration(
                              labelText: _addMethod == PaymentMethod.giftCard
                                  ? 'Gift Card Code'
                                  : '${_addMethod.label} Reference',
                              hintText: _addMethod == PaymentMethod.giftCard
                                  ? 'Enter card code'
                                  : 'Transaction/reference number',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        TextField(
                          controller: _addAmountCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.]'),
                            ),
                          ],
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            hintText: '0',
                            hintStyle: theme.textTheme.headlineSmall?.copyWith(
                              color: colors.onSurfaceVariant.withValues(
                                alpha: 0.4,
                              ),
                              fontWeight: FontWeight.w600,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          onChanged: (_) => setState(() {}),
                          onSubmitted: (_) => _addPayment(cart.total),
                        ),
                        const SizedBox(height: 12),

                        // ── Quick amount grid ──
                        GridView.count(
                          crossAxisCount: 4,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 2.2,
                          children: [
                            _quickBtn(
                              'Full',
                              () => _addFullPayment(cart.total),
                            ),
                            if (_addMethod == PaymentMethod.cash)
                              for (final amt in const [
                                5000,
                                10000,
                                20000,
                                50000,
                              ])
                                _quickBtn(
                                  '${(amt / 1000).toStringAsFixed(0)}K',
                                  () {
                                    _addAmountCtrl.text = amt.toString();
                                    _addPayment(cart.total);
                                  },
                                ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // ── Add payment button (or Charge Terminal for card) ──
                        if (_addMethod == PaymentMethod.card) ...[
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: FilledButton.icon(
                              onPressed: _terminalProcessing
                                  ? null
                                  : () => _chargeTerminal(cart.total),
                              style: FilledButton.styleFrom(
                                backgroundColor: colors.primary,
                                foregroundColor: colors.onPrimary,
                              ),
                              icon: _terminalProcessing
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.contactless),
                              label: Text(
                                _terminalProcessing
                                    ? 'Waiting for card…'
                                    : 'Charge Terminal',
                              ),
                            ),
                          ),
                          if (_terminalProcessing)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Center(
                                child: TextButton(
                                  onPressed: () =>
                                      sl<CardTerminalService>().cancelPayment(),
                                  child: const Text('Cancel'),
                                ),
                              ),
                            ),
                          if (_terminalError != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                _terminalError!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.error,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          const SizedBox(height: 8),
                          // Manual fallback for card-not-present / keyed-in
                          SizedBox(
                            width: double.infinity,
                            height: 40,
                            child: OutlinedButton.icon(
                              onPressed: () => _addPayment(cart.total),
                              icon: const Icon(Icons.keyboard_alt_outlined,
                                  size: 18),
                              label: const Text('Manual Entry'),
                            ),
                          ),
                        ] else
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: FilledButton.tonalIcon(
                              onPressed: () => _addPayment(cart.total),
                              icon: const Icon(Icons.add),
                              label: const Text('Add Payment'),
                            ),
                          ),
                      ],

                      // ── Added payments list ──
                      if (_payments.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        for (var i = 0; i < _payments.length; i++)
                          Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: colors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _payments[i].method.icon,
                                  size: 20,
                                  color: colors.onSurfaceVariant,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  _payments[i].method.label,
                                  style: theme.textTheme.bodyMedium,
                                ),
                                if ((_payments[i].reference ?? '').isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: Text(
                                      '#${_payments[i].reference}',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: colors.onSurfaceVariant,
                                          ),
                                    ),
                                  ),
                                const Spacer(),
                                MoneyText(
                                  _payments[i].amount,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () => _removePayment(i),
                                  child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: Icon(
                                      Icons.close,
                                      size: 16,
                                      color: colors.error,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (change > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: colors.primaryContainer.withValues(
                                alpha: 0.5,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.currency_exchange,
                                  size: 20,
                                  color: colors.primary,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Change',
                                  style: theme.textTheme.bodyMedium,
                                ),
                                const Spacer(),
                                MoneyText(
                                  change,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: colors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],

                      // ── Remaining balance ──
                      if (remaining > 0 && _payments.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colors.errorContainer.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Remaining',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: colors.error,
                                ),
                              ),
                              MoneyText(
                                remaining,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: colors.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // ── Notes toggle ──
                      const SizedBox(height: 12),
                      if (!_showNotes)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () => setState(() => _showNotes = true),
                            icon: const Icon(Icons.note_add_outlined, size: 18),
                            label: const Text('Add note'),
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        )
                      else
                        TextField(
                          controller: _notesCtrl,
                          autofocus: true,
                          decoration: InputDecoration(
                            labelText: 'Order notes',
                            hintText: 'e.g. Gift wrap, table 3',
                            prefixIcon: const Icon(Icons.note_alt_outlined),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () {
                                _notesCtrl.clear();
                                setState(() => _showNotes = false);
                              },
                            ),
                          ),
                          maxLines: 1,
                        ),
                    ],
                  ),
                ),

                // ═══ Complete Sale button ═══
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    border: Border(
                      top: BorderSide(color: colors.outlineVariant),
                    ),
                  ),
                  child: SizedBox(
                    height: 56,
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: (processing || !isPaid)
                          ? null
                          : () => _complete(cart),
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.secondary,
                        foregroundColor: colors.onSecondary,
                        disabledBackgroundColor:
                            colors.outline.withValues(alpha: 0.3),
                      ),
                      icon: processing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_circle_outline, size: 22),
                      label: Text(
                        isPaid ? 'Complete Sale' : 'Add payment to continue',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _quickBtn(String label, VoidCallback onTap) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
