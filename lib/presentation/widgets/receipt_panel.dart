import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:printing/printing.dart';

import '../../core/utils/formatters.dart';
import '../../core/utils/receipt_pdf.dart';
import '../../data/models/business_models.dart';
import '../../data/models/sale_models.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/business/business_bloc.dart';
import '../blocs/sale/sale_bloc.dart';
import '../blocs/sale/sale_event.dart';
import '../blocs/sale/sale_state.dart';

/// Inline receipt panel styled like a real paper receipt.
class ReceiptPanel extends StatefulWidget {
  final VoidCallback onNewSale;
  const ReceiptPanel({super.key, required this.onNewSale});

  @override
  State<ReceiptPanel> createState() => _ReceiptPanelState();
}

class _ReceiptPanelState extends State<ReceiptPanel> {
  bool _busy = false;

  String? get _cashierName {
    final user = context.read<AuthBloc>().state.user;
    if (user == null) return null;
    final full = '${user.firstName} ${user.lastName}'.trim();
    return full.isEmpty ? user.email : full;
  }

  Future<Uint8List> _buildPdfBytes(Sale sale) async {
    final businessState = context.read<BusinessBloc>().state;
    final authState = context.read<AuthBloc>().state;
    final business = businessState.selected;
    final branchId = authState.branchId;
    Branch? branch;
    if (business != null && branchId != null) {
      for (final b in business.branches) {
        if (b.id == branchId) {
          branch = b;
          break;
        }
      }
    }
    return buildReceiptPdf(
      sale,
      businessName: business?.name,
      branchName: branch?.name,
      businessAddress: business?.address,
      businessPhone: business?.phone,
      tinNumber: business?.tinNumber,
      cashierName: _cashierName,
      customerName: sale.customerName,
    );
  }

  Future<void> _onPrint(Sale sale) async {
    setState(() => _busy = true);
    try {
      await Printing.layoutPdf(
        onLayout: (format) async => _buildPdfBytes(sale),
        name: 'receipt-${sale.saleNumber ?? sale.id ?? 'pending'}',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Print failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _onShare(Sale sale) async {
    setState(() => _busy = true);
    try {
      final bytes = await _buildPdfBytes(sale);
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'receipt-${sale.saleNumber ?? sale.id ?? 'pending'}.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Share failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return BlocBuilder<SaleBloc, SaleState>(
      builder: (context, state) {
        final sale = state.lastSale;
        if (sale == null) {
          return const Center(child: Text('No sale data'));
        }
        final offline = state.status == SaleStatus.queuedOffline;

        return Column(
          children: [
            // ═══ Success banner ═══
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              color: colors.primaryContainer.withValues(alpha: 0.3),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: colors.primary, size: 28),
                  const SizedBox(width: 10),
                  Text(
                    'Sale Completed',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            if (offline)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                color: colors.tertiaryContainer,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_off, size: 14, color: colors.tertiary),
                    const SizedBox(width: 6),
                    Text(
                      'Queued offline',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onTertiaryContainer,
                      ),
                    ),
                  ],
                ),
              ),

            // ═══ Receipt paper ═══
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 360),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 20,
                      ),
                      child: _receiptContent(sale, theme),
                    ),
                  ),
                ),
              ),
            ),

            // ═══ Actions ═══
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border(top: BorderSide(color: colors.outlineVariant)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _busy || offline
                              ? null
                              : () => _onPrint(sale),
                          icon: _busy
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.print_outlined, size: 20),
                          label: const Text('Print'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _busy ? null : () => _onShare(sale),
                          icon: const Icon(Icons.share_outlined, size: 20),
                          label: const Text('Share'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 52,
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        context.read<SaleBloc>().add(const SaleCleared());
                        widget.onNewSale();
                      },
                      icon: const Icon(Icons.add_shopping_cart, size: 20),
                      label: const Text(
                        'New Sale',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// The receipt content styled like paper — all text is dark on white.
  Widget _receiptContent(Sale sale, ThemeData theme) {
    const black = Color(0xFF1A1A1A);
    const grey = Color(0xFF666666);
    const headerStyle = TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: black,
      letterSpacing: 1.2,
    );
    const labelStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.bold,
      color: black,
    );
    const valueStyle = TextStyle(fontSize: 13, color: black);
    const itemNameStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.bold,
      color: black,
    );
    const itemDetailStyle = TextStyle(fontSize: 12, color: grey);
    const totalLabelStyle = TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.bold,
      color: black,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        const Center(child: Text('RECEIPT', style: headerStyle)),
        const SizedBox(height: 2),
        const Divider(color: black, thickness: 1.5),
        const SizedBox(height: 8),

        // Sale info
        if (sale.saleNumber != null)
          _infoRow(
            'Sale #',
            Formatters.saleNumber(sale.saleNumber),
            labelStyle,
            valueStyle,
          ),
        if (sale.createdAt != null)
          _infoRow(
            'Date',
            Formatters.dateTime(sale.createdAt!),
            labelStyle,
            valueStyle,
          ),
        if (_cashierName != null)
          _infoRow('Cashier', _cashierName!, labelStyle, valueStyle),
        if (sale.customerName != null)
          _infoRow('Customer', sale.customerName!, labelStyle, valueStyle),

        const SizedBox(height: 8),
        _dottedDivider(),
        const SizedBox(height: 8),

        // Items
        for (final item in sale.items) ...[
          Text(item.productName, style: itemNameStyle),
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${Formatters.quantity(item.quantity)} x TZS ${Formatters.money(item.unitPrice)}',
                  style: itemDetailStyle,
                ),
                Text(
                  'TZS ${Formatters.money(item.totalPrice)}',
                  style: valueStyle,
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 4),
        _dottedDivider(),
        const SizedBox(height: 8),

        // Totals
        _amountRow('Subtotal', sale.subtotal, valueStyle),
        _amountRow('Tax', sale.taxAmount, valueStyle),
        if (sale.discountAmount > 0)
          _amountRow('Discount', -sale.discountAmount, valueStyle),

        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('TOTAL', style: totalLabelStyle),
            Text(
              'TZS ${Formatters.money(sale.totalAmount)}',
              style: totalLabelStyle.copyWith(fontSize: 16),
            ),
          ],
        ),

        const SizedBox(height: 8),
        _dottedDivider(),
        const SizedBox(height: 8),

        // Payment methods
        for (final p in sale.payments)
          _amountRow(p.method, p.amount, valueStyle),
        if (sale.changeAmount > 0)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Change',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: black,
                ),
              ),
              Text(
                'TZS ${Formatters.money(sale.changeAmount)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: black,
                ),
              ),
            ],
          ),

        if (sale.notes != null && sale.notes!.isNotEmpty) ...[
          const SizedBox(height: 8),
          _dottedDivider(),
          const SizedBox(height: 8),
          Text(
            'Note: ${sale.notes!}',
            style: const TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: grey,
            ),
          ),
        ],

        const SizedBox(height: 12),
        _dottedDivider(),
        const SizedBox(height: 12),

        // Footer
        Center(
          child: Text(
            'Thank you for your business!',
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(
    String label,
    String value,
    TextStyle labelStyle,
    TextStyle valueStyle,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: labelStyle),
          Text(value, style: valueStyle),
        ],
      ),
    );
  }

  Widget _amountRow(String label, double amount, TextStyle style) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text('TZS ${Formatters.money(amount)}', style: style),
        ],
      ),
    );
  }

  Widget _dottedDivider() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 4.0;
        const dashSpace = 3.0;
        final count = (constraints.maxWidth / (dashWidth + dashSpace)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            count,
            (_) => SizedBox(
              width: dashWidth,
              height: 1,
              child: const DecoratedBox(
                decoration: BoxDecoration(color: Color(0xFFAAAAAA)),
              ),
            ),
          ),
        );
      },
    );
  }
}
