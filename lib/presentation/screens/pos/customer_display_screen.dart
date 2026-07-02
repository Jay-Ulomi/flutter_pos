import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../blocs/cart/cart_bloc.dart';
import '../../blocs/cart/cart_state.dart';
import '../../blocs/session/session_bloc.dart';
import '../../widgets/money_text.dart';

/// A customer-facing full-screen display that shows the current cart.
///
/// Open this screen on the second monitor to give customers a live view of
/// items being rung up. It reads from the same [CartBloc] that the POS uses.
class CustomerDisplayScreen extends StatelessWidget {
  const CustomerDisplayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(
        child: BlocBuilder<CartBloc, CartState>(
          builder: (context, cart) {
            return Column(
              children: [
                _Header(cart: cart),
                Expanded(
                  child: cart.isEmpty
                      ? const _IdleView()
                      : _ItemList(cart: cart),
                ),
                _Totals(cart: cart),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.cart});
  final CartState cart;

  @override
  Widget build(BuildContext context) {
    final session = context.read<SessionBloc>().state.current;
    final now = DateFormat('EEE, d MMM yyyy  HH:mm').format(DateTime.now());

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF161B22),
        border: Border(bottom: BorderSide(color: Color(0xFF30363D))),
      ),
      child: Row(
        children: [
          // Store branding
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF238636),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.storefront, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Point of Sale',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  session != null
                      ? '$now  ·  Cashier: ${session.userName ?? 'Staff'}'
                      : now,
                  style: const TextStyle(color: Color(0xFF8B949E), fontSize: 12),
                ),
              ],
            ),
          ),
          // Item count badge
          if (cart.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF238636).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF238636)),
              ),
              child: Text(
                '${cart.lines.length} item${cart.lines.length == 1 ? '' : 's'}',
                style: const TextStyle(
                  color: Color(0xFF3FB950),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Idle view (empty cart)
// ─────────────────────────────────────────────────────────────────────────────

class _IdleView extends StatelessWidget {
  const _IdleView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: Colors.white.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 20),
          Text(
            'Welcome!',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 32,
              fontWeight: FontWeight.w300,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your items will appear here as they are scanned.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Item list
// ─────────────────────────────────────────────────────────────────────────────

class _ItemList extends StatelessWidget {
  const _ItemList({required this.cart});
  final CartState cart;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      itemCount: cart.lines.length,
      separatorBuilder: (_, i) =>
          const Divider(color: Color(0xFF30363D), height: 1),
      itemBuilder: (context, i) {
        final line = cart.lines[i];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              // Index
              SizedBox(
                width: 28,
                child: Text(
                  '${i + 1}',
                  style: const TextStyle(
                    color: Color(0xFF8B949E),
                    fontSize: 13,
                  ),
                ),
              ),
              // Product name
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      line.product.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (line.serialNumber != null)
                      Text(
                        'S/N: ${line.serialNumber}',
                        style: const TextStyle(
                          color: Color(0xFF8B949E),
                          fontSize: 11,
                        ),
                      ),
                    if (line.lotNumber != null)
                      Text(
                        'Lot: ${line.lotNumber}',
                        style: const TextStyle(
                          color: Color(0xFF8B949E),
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
              // Qty × price
              Expanded(
                flex: 3,
                child: Text(
                  '${line.quantity % 1 == 0 ? line.quantity.toInt() : line.quantity} × ${_fmt(line.effectivePrice)}',
                  style: const TextStyle(
                    color: Color(0xFF8B949E),
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              // Discount
              if (line.hasDiscount)
                Expanded(
                  flex: 2,
                  child: Text(
                    '−${_fmt(line.lineDiscount)}',
                    style: const TextStyle(
                      color: Color(0xFFF85149),
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              // Line total
              Expanded(
                flex: 2,
                child: Text(
                  _fmt(line.lineTotal),
                  style: const TextStyle(
                    color: Color(0xFF3FB950),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _fmt(double v) {
    final f = NumberFormat('#,##0.00');
    return f.format(v);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Totals footer
// ─────────────────────────────────────────────────────────────────────────────

class _Totals extends StatelessWidget {
  const _Totals({required this.cart});
  final CartState cart;

  @override
  Widget build(BuildContext context) {
    if (cart.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: const BoxDecoration(
        color: Color(0xFF161B22),
        border: Border(top: BorderSide(color: Color(0xFF30363D))),
      ),
      child: Column(
        children: [
          _TotalRow(label: 'Subtotal', value: cart.subtotal),
          if (cart.discount > 0)
            _TotalRow(
              label: 'Discount',
              value: cart.discount,
              negative: true,
              color: const Color(0xFFF85149),
            ),
          if (cart.taxAmount > 0)
            _TotalRow(label: 'Tax', value: cart.taxAmount),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF238636).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF238636)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TOTAL',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                MoneyText(
                  cart.total,
                  style: const TextStyle(
                    color: Color(0xFF3FB950),
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          if (cart.hasCustomer) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person, size: 14, color: Color(0xFF8B949E)),
                const SizedBox(width: 4),
                Text(
                  cart.selectedCustomerName ?? 'Customer',
                  style: const TextStyle(
                    color: Color(0xFF8B949E),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.value,
    this.negative = false,
    this.color,
  });
  final String label;
  final double value;
  final bool negative;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final textColor = color ?? const Color(0xFF8B949E);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: textColor, fontSize: 14)),
          Row(
            children: [
              if (negative) Text('−', style: TextStyle(color: textColor, fontSize: 14)),
              MoneyText(value, style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}
