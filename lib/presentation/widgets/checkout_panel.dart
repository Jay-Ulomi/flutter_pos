import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/card_terminal_service.dart';
import '../../data/datasources/remote/promotion_remote.dart';
import '../../data/models/sale_models.dart';
import '../../di/injection.dart';
import '../../core/error/exceptions.dart';
import '../blocs/cart/cart_bloc.dart';
import '../blocs/cart/cart_event.dart';
import '../blocs/cart/cart_state.dart';
import '../blocs/sale/sale_bloc.dart';
import '../blocs/sale/sale_event.dart';
import '../blocs/sale/sale_state.dart';
import '../blocs/session/session_bloc.dart';
import 'customer_picker_sheet.dart';
import 'keyboard_done_bar.dart';
import 'money_text.dart';

enum PaymentMethod { cash, card, mobile, bankTransfer, credit, giftCard, storeCredit }

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
      case PaymentMethod.storeCredit:
        return 'STORE_CREDIT';
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
      case PaymentMethod.storeCredit:
        return 'Store Credit';
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
      case PaymentMethod.storeCredit:
        return Icons.wallet;
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
      case PaymentMethod.storeCredit:
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

  // Coupon / promotion state — UI hidden, logic kept for re-enable
  String? _appliedCoupon;
  // ignore: unused_field
  String? _couponError;
  // ignore: unused_field
  bool _couponValidating = false;
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

  // ignore: unused_element
  Future<void> _applyCoupon(double cartSubtotal) async {
    final code = _couponCtrl.text.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() {
      _couponValidating = true;
      _couponError = null;
    });
    try {
      final result = await sl<PromotionRemoteDataSource>().validateCoupon(code);

      if (result.minimumOrderAmount != null &&
          cartSubtotal < result.minimumOrderAmount!) {
        if (!mounted) return;
        setState(() {
          _couponError =
              'Minimum order of ${result.minimumOrderAmount!.toStringAsFixed(0)} required';
          _couponValidating = false;
        });
        return;
      }

      final discount = result.calculateDiscount(cartSubtotal);
      if (!mounted) return;
      setState(() {
        _appliedCoupon = code;
        _couponDiscount = discount;
        _couponValidating = false;
      });

      final discountLabel = result.discountType == 'PERCENTAGE'
          ? '${result.discountValue.toStringAsFixed(0)}% off'
          : 'TZS ${result.discountValue.toStringAsFixed(0)} off';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Coupon "${result.name.isNotEmpty ? result.name : code}" applied — $discountLabel',
          ),
        ),
      );
    } on ServerException catch (e) {
      if (!mounted) return;
      setState(() {
        _couponError = e.message;
        _couponValidating = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _couponError = 'Could not validate coupon. Try again.';
        _couponValidating = false;
      });
    }
  }

  // ignore: unused_element
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

  double _storeCreditUsed() =>
      _payments.where((p) => p.method == PaymentMethod.storeCredit).fold(0.0, (s, p) => s + p.amount);

  void _complete(CartState cart) {
    final sessionId = context.read<SessionBloc>().state.current?.id;
    if (sessionId == null || sessionId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active session found. Open a session first.')),
      );
      return;
    }
    if (_hasCreditPayment && !cart.hasCustomer) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A customer is required for credit payments.')),
      );
      return;
    }
    final effectiveTotal = cart.total - _couponDiscount;
    final remaining = _remaining(effectiveTotal);
    // Allow underpayment only when a customer is selected (remainder goes on account).
    if (remaining > 0 && !cart.hasCustomer) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a customer to put the balance on account, or add more payment.')),
      );
      return;
    }
    // Validate store credit doesn't exceed available balance.
    final creditUsed = _storeCreditUsed();
    if (creditUsed > cart.customerBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Store credit used exceeds available balance.')),
      );
      return;
    }
    context.read<SaleBloc>().add(
      SaleCheckoutRequested(_buildSale(cart, sessionId)),
    );
  }

  Sale _buildSale(CartState cart, String sessionId) {
    final effectiveTotal = cart.total - _couponDiscount;
    final items = cart.lines
        .map(
          (l) => SaleItem(
            productId: l.product.id,
            productName: l.product.name,
            quantity: l.quantity,
            unitPrice: l.effectivePrice,
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
    final change = (_totalPaid - effectiveTotal).clamp(0, double.infinity).toDouble();
    return Sale(
      sessionId: sessionId,
      items: items,
      payments: payments,
      subtotal: cart.subtotal,
      taxAmount: cart.taxAmount,
      discountAmount:
          cart.discount +
          _couponDiscount +
          cart.lines.fold(0.0, (sum, l) => sum + l.lineDiscount),
      totalAmount: effectiveTotal,
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
        CartCustomerSelected(
          customerId: c.id,
          customerName: c.name,
          customerBalance: c.currentBalance,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        }
      },
      builder: (context, saleState) {
        return BlocBuilder<CartBloc, CartState>(
          builder: (context, cart) {
            final processing = saleState.status == SaleStatus.processing;
            final effectiveTotal = cart.total - _couponDiscount;
            final remaining = _remaining(effectiveTotal);
            final change =
                (_totalPaid - effectiveTotal).clamp(0, double.infinity).toDouble();
            final availableCredit = cart.customerBalance > 0 ? cart.customerBalance : 0.0;
            // Can complete if: fully paid, OR customer is set and remaining goes on account.
            final canComplete = cart.isNotEmpty &&
                (_totalPaid >= effectiveTotal || (remaining > 0 && cart.hasCustomer));
            // Visible payment methods — store credit only when customer has positive balance.
            final visibleMethods = PaymentMethod.values
                .where((m) => m != PaymentMethod.storeCredit || availableCredit > 0)
                .toList();

            final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;
            return Stack(
              children: [
                Positioned.fill(
                  child: Column(
                    children: [
                // ── Header ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
                  child: Row(
                    children: [
                      if (widget.onBack != null) ...[
                        GestureDetector(
                          onTap: widget.onBack,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.arrow_back,
                                size: 18, color: Color(0xFF6B7280)),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      const Text(
                        'Checkout',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _pickCustomer,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: cart.hasCustomer
                                ? const Color(0xFFDCFCE7)
                                : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: cart.hasCustomer
                                  ? const Color(0xFFBBF7D0)
                                  : const Color(0xFFE5E7EB),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                cart.hasCustomer
                                    ? Icons.person_rounded
                                    : Icons.person_outline,
                                size: 13,
                                color: cart.hasCustomer
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFF9CA3AF),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                cart.hasCustomer
                                    ? (cart.selectedCustomerName ?? 'Customer')
                                    : 'Walk-in',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: cart.hasCustomer
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: cart.hasCustomer
                                      ? const Color(0xFF166534)
                                      : const Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),

                // ── Body ──
                Expanded(
                  child: ListView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Order summary card
                      _sectionLabel('Order Summary'),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ...cart.lines.map((line) {
                              final qty = line.quantity ==
                                      line.quantity.floorToDouble()
                                  ? line.quantity.toInt().toString()
                                  : line.quantity.toStringAsFixed(2);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text.rich(
                                        TextSpan(
                                          text: line.product.name,
                                          style: const TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFF374151)),
                                          children: [
                                            TextSpan(
                                              text: ' ×$qty',
                                              style: const TextStyle(
                                                  color: Color(0xFF9CA3AF)),
                                            ),
                                          ],
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    MoneyText(
                                      line.lineTotal,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF111827),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            const Divider(height: 16, color: Color(0xFFE5E7EB)),
                            _summaryRow('Subtotal', cart.subtotal),
                            if (cart.taxAmount > 0) ...[
                              const SizedBox(height: 4),
                              _summaryRow('Tax', cart.taxAmount),
                            ],
                            if (cart.discount > 0) ...[
                              const SizedBox(height: 4),
                              _summaryRow('Discount', -cart.discount,
                                  valueColor: const Color(0xFF16A34A)),
                            ],
                            if (_couponDiscount > 0) ...[
                              const SizedBox(height: 4),
                              _summaryRow(
                                  'Coupon ($_appliedCoupon)', -_couponDiscount,
                                  valueColor: const Color(0xFF16A34A)),
                            ],
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child:
                                  Divider(height: 1, color: Color(0xFFE5E7EB)),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF111827))),
                                MoneyText(
                                  effectiveTotal,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF468432),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // TODO: re-enable coupon section when ready

                      // Payment section header
                      _sectionLabel('Payment Method'),
                      const SizedBox(height: 10),

                      // Store credit banner — shown when customer has a positive balance.
                      if (availableCredit > 0) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFBBF7D0)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.wallet, size: 16, color: Color(0xFF16A34A)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Store credit available: TZS ${availableCredit.toStringAsFixed(0)}',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF166534), fontWeight: FontWeight.w600),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  final apply = [availableCredit, remaining].reduce((a, b) => a < b ? a : b);
                                  if (apply <= 0) return;
                                  setState(() {
                                    _payments.add(_PaymentEntry(method: PaymentMethod.storeCredit, amount: apply));
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF16A34A),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text('Apply', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Payment method cards — 3-column grid
                      GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 6,
                        crossAxisSpacing: 6,
                        childAspectRatio: 2.4,
                        children: visibleMethods.map((m) {
                          final selected = m == _addMethod;
                          return GestureDetector(
                            onTap: () => setState(() {
                              _addMethod = m;
                              if (!m.requiresReference) {
                                _addReferenceCtrl.clear();
                              }
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 140),
                              decoration: BoxDecoration(
                                color: selected
                                    ? const Color(0xFF468432)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: selected
                                      ? const Color(0xFF468432)
                                      : const Color(0xFFE5E7EB),
                                  width: selected ? 1.5 : 1,
                                ),
                                boxShadow: selected
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF468432)
                                              .withValues(alpha: 0.20),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    m.icon,
                                    size: 14,
                                    color: selected
                                        ? Colors.white
                                        : const Color(0xFF6B7280),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    m.label,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: selected
                                          ? Colors.white
                                          : const Color(0xFF374151),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),

                      // Reference input (when required)
                      if (_addMethod.requiresReference && remaining > 0) ...[
                        TextField(
                          controller: _addReferenceCtrl,
                          keyboardAppearance: Brightness.light,
                          textInputAction: TextInputAction.next,
                          textCapitalization:
                              _addMethod == PaymentMethod.giftCard
                                  ? TextCapitalization.characters
                                  : TextCapitalization.none,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: _addMethod == PaymentMethod.giftCard
                                ? 'Gift card code'
                                : 'Reference / Transaction ID',
                            hintStyle: const TextStyle(
                                color: Color(0xFFD1D5DB), fontSize: 14),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            filled: true,
                            fillColor: const Color(0xFFF9FAFB),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: Color(0xFFE5E7EB))),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: Color(0xFFE5E7EB))),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: Color(0xFF468432), width: 1.5)),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],

                      // Amount input
                      if (remaining > 0) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Amount',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF9CA3AF),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Remaining  ',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFFEF4444),
                                    ),
                                  ),
                                  MoneyText(
                                    remaining,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFDC2626),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _addAmountCtrl,
                          keyboardAppearance: Brightness.light,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          textInputAction: TextInputAction.done,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.]'))
                          ],
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111827)),
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            hintText: '0',
                            hintStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFD1D5DB)),
                            prefixText: 'TZS  ',
                            prefixStyle: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF9CA3AF),
                                fontWeight: FontWeight.w500),
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 10),
                            filled: true,
                            fillColor: const Color(0xFFF9FAFB),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: Color(0xFFE5E7EB))),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: Color(0xFFE5E7EB))),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: Color(0xFF468432), width: 1.5)),
                          ),
                          onChanged: (_) => setState(() {}),
                          onSubmitted: (_) => _addPayment(cart.total),
                        ),
                        const SizedBox(height: 10),

                        // Quick buttons — Full + cash denominations in 2 rows
                        if (_addMethod == PaymentMethod.cash) ...[
                          Row(
                            children: [
                              _quickBtn('Full',
                                  () => _addFullPayment(cart.total)),
                              const SizedBox(width: 6),
                              _quickBtn('1K', () {
                                _addAmountCtrl.text = '1000';
                                _addPayment(cart.total);
                              }),
                              const SizedBox(width: 6),
                              _quickBtn('2K', () {
                                _addAmountCtrl.text = '2000';
                                _addPayment(cart.total);
                              }),
                              const SizedBox(width: 6),
                              _quickBtn('5K', () {
                                _addAmountCtrl.text = '5000';
                                _addPayment(cart.total);
                              }),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _quickBtn('10K', () {
                                _addAmountCtrl.text = '10000';
                                _addPayment(cart.total);
                              }),
                              const SizedBox(width: 6),
                              _quickBtn('20K', () {
                                _addAmountCtrl.text = '20000';
                                _addPayment(cart.total);
                              }),
                              const SizedBox(width: 6),
                              _quickBtn('50K', () {
                                _addAmountCtrl.text = '50000';
                                _addPayment(cart.total);
                              }),
                              const SizedBox(width: 6),
                              _quickBtn('100K', () {
                                _addAmountCtrl.text = '100000';
                                _addPayment(cart.total);
                              }),
                            ],
                          ),
                        ] else
                          Row(
                            children: [
                              _quickBtn('Full',
                                  () => _addFullPayment(cart.total)),
                            ],
                          ),
                        const SizedBox(height: 10),

                        // Add / Charge button
                        if (_addMethod == PaymentMethod.card) ...[
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: FilledButton.icon(
                              onPressed: _terminalProcessing
                                  ? null
                                  : () => _chargeTerminal(cart.total),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF468432),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              icon: _terminalProcessing
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white))
                                  : const Icon(Icons.contactless, size: 18),
                              label: Text(
                                _terminalProcessing
                                    ? 'Waiting for card…'
                                    : 'Charge Terminal',
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w600),
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
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(_terminalError!,
                                  style: const TextStyle(
                                      fontSize: 11, color: Color(0xFFDC2626)),
                                  textAlign: TextAlign.center),
                            ),
                          const SizedBox(height: 6),
                          SizedBox(
                            width: double.infinity,
                            height: 40,
                            child: OutlinedButton.icon(
                              onPressed: () => _addPayment(cart.total),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFE5E7EB)),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const Icon(Icons.keyboard_alt_outlined,
                                  size: 16),
                              label: const Text('Manual Entry',
                                  style: TextStyle(fontSize: 13)),
                            ),
                          ),
                        ] else
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: FilledButton.icon(
                              onPressed: () => _addPayment(cart.total),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF468432),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add Payment',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ),
                        const SizedBox(height: 16),
                      ],

                      // Added payments
                      if (_payments.isNotEmpty) ...[
                        for (var i = 0; i < _payments.length; i++)
                          Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF468432)
                                        .withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(_payments[i].method.icon,
                                      size: 16, color: const Color(0xFF468432)),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _payments[i].method.label,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF111827)),
                                      ),
                                      if ((_payments[i].reference ?? '')
                                          .isNotEmpty)
                                        Text(
                                          '#${_payments[i].reference}',
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF9CA3AF)),
                                        ),
                                    ],
                                  ),
                                ),
                                MoneyText(
                                  _payments[i].amount,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF111827)),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => _removePayment(i),
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEE2E2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(Icons.close,
                                        size: 13, color: Color(0xFFDC2626)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 4),
                      ],

                      // Payment summary card
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Column(
                          children: [
                            _summaryRow('Total due', effectiveTotal),
                            const SizedBox(height: 4),
                            _summaryRow('Paid', _totalPaid,
                                valueColor: _totalPaid > 0 ? const Color(0xFF16A34A) : null),
                            const SizedBox(height: 4),
                            if (remaining > 0 && cart.hasCustomer)
                              _summaryRow('On Account', remaining,
                                  valueColor: const Color(0xFFD97706), bold: true)
                            else if (remaining > 0)
                              _summaryRow('Remaining', remaining,
                                  valueColor: const Color(0xFFDC2626), bold: true)
                            else
                              _summaryRow('Change', change,
                                  valueColor: const Color(0xFF16A34A), bold: true),
                          ],
                        ),
                      ),

                      // Notes
                      const SizedBox(height: 16),
                      if (!_showNotes)
                        GestureDetector(
                          onTap: () => setState(() => _showNotes = true),
                          child: const Row(
                            children: [
                              Icon(Icons.note_add_outlined,
                                  size: 15, color: Color(0xFF9CA3AF)),
                              SizedBox(width: 6),
                              Text('Add note',
                                  style: TextStyle(
                                      fontSize: 13, color: Color(0xFF6B7280))),
                            ],
                          ),
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _sectionLabel('Note'),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () {
                                    _notesCtrl.clear();
                                    setState(() => _showNotes = false);
                                  },
                                  child: const Icon(Icons.close,
                                      size: 14, color: Color(0xFF9CA3AF)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _notesCtrl,
                              keyboardAppearance: Brightness.light,
                              autofocus: true,
                              maxLines: 2,
                              style: const TextStyle(fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'e.g. Gift wrap, table 3',
                                hintStyle: const TextStyle(
                                    color: Color(0xFFD1D5DB)),
                                contentPadding: const EdgeInsets.all(12),
                                filled: true,
                                fillColor: const Color(0xFFF9FAFB),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: Color(0xFFE5E7EB))),
                                enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: Color(0xFFE5E7EB))),
                                focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: Color(0xFF468432), width: 1.5)),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),

                // ── Complete Sale button ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: SizedBox(
                    height: 52,
                    width: double.infinity,
                    child: FilledButton(
                      onPressed:
                          (processing || !canComplete) ? null : () => _complete(cart),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF468432),
                        disabledBackgroundColor: const Color(0xFFD1D5DB),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: processing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: Colors.white))
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  canComplete
                                      ? (remaining > 0 ? 'Complete — Put on Account' : 'Complete Sale')
                                      : 'Add payment to continue',
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white),
                                ),
                                if (canComplete && remaining == 0) ...[
                                  const SizedBox(width: 10),
                                  Container(
                                    width: 1,
                                    height: 16,
                                    color: Colors.white.withValues(alpha: 0.4),
                                  ),
                                  const SizedBox(width: 10),
                                  MoneyText(
                                    effectiveTotal,
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white),
                                  ),
                                ],
                              ],
                            ),
                    ),
                  ),
                ),
                    ],
                  ),
                ),
                // "Done" bar above the keyboard — the numeric amount keypad has
                // no return key, so this gives an explicit way to dismiss it.
                if (keyboardHeight > 0)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: keyboardHeight,
                    child: const KeyboardDoneBar(),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _sectionLabel(String text) {
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

  Widget _summaryRow(String label, double amount,
      {Color? valueColor, bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            color: bold ? const Color(0xFF111827) : const Color(0xFF6B7280),
          ),
        ),
        MoneyText(
          amount,
          style: TextStyle(
            fontSize: bold ? 14 : 13,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
            color: valueColor ?? const Color(0xFF374151),
          ),
        ),
      ],
    );
  }

  Widget _quickBtn(String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF468432).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: const Color(0xFF468432).withValues(alpha: 0.2)),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF468432),
            ),
          ),
        ),
      ),
    );
  }
}
