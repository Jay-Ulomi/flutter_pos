import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/receipt_pdf.dart';
import '../../../data/models/business_models.dart';
import '../../../data/models/sale_models.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/business/business_bloc.dart';
import '../../blocs/sale/sale_bloc.dart';
import '../../blocs/sale/sale_event.dart';
import '../../blocs/sale/sale_state.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/money_text.dart';

class ReceiptScreen extends StatefulWidget {
  const ReceiptScreen({super.key});

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  bool _busy = false;

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
    final branchName = branch?.name;

    final user = authState.user;
    final cashierName = user != null
        ? ('${user.firstName} ${user.lastName}'.trim().isEmpty
              ? user.email
              : '${user.firstName} ${user.lastName}'.trim())
        : null;

    return buildReceiptPdf(
      sale,
      businessName: business?.name,
      branchName: branchName,
      businessAddress: business?.address,
      businessPhone: business?.phone,
      tinNumber: business?.tinNumber,
      cashierName: cashierName,
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
    return Scaffold(
      appBar: AppBar(title: const Text('Receipt')),
      body: BlocBuilder<SaleBloc, SaleState>(
        builder: (context, state) {
          final sale = state.lastSale;
          if (sale == null) {
            return const EmptyState(
              title: 'No recent sale',
              subtitle: 'Complete a sale to see its receipt.',
              icon: Icons.receipt_long_outlined,
            );
          }
          final offline = state.status == SaleStatus.queuedOffline;
          final theme = Theme.of(context);
          return Column(
            children: [
              if (offline)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  color: theme.colorScheme.tertiaryContainer,
                  child: const Text(
                    'Sale queued offline. It will sync automatically when online.',
                    textAlign: TextAlign.center,
                  ),
                ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: theme.colorScheme.primary,
                            size: 56,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Sale Completed',
                            style: theme.textTheme.titleLarge,
                          ),
                          if (sale.saleNumber != null)
                            Text(
                              '#${Formatters.saleNumber(sale.saleNumber)}',
                              style: theme.textTheme.bodyMedium,
                            ),
                          if (sale.createdAt != null)
                            Text(
                              Formatters.dateTime(sale.createdAt!),
                              style: theme.textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            for (final item in sale.items)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${item.productName} × ${Formatters.quantity(item.quantity)}',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    MoneyText(item.totalPrice),
                                  ],
                                ),
                              ),
                            const Divider(),
                            _row('Subtotal', sale.subtotal),
                            _row('Tax', sale.taxAmount),
                            if (sale.discountAmount > 0)
                              _row('Discount', -sale.discountAmount),
                            _row('Total', sale.totalAmount, emphasize: true),
                            const SizedBox(height: 8),
                            _row('Paid', sale.paidAmount),
                            _row('Change', sale.changeAmount),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
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
                                : const Icon(Icons.print_outlined),
                            label: const Text('Print'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _busy ? null : () => _onShare(sale),
                            icon: _busy
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.share_outlined),
                            label: const Text('Share'),
                          ),
                        ),
                      ],
                    ),
                    if (offline)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Printing is disabled for queued offline sales. '
                          'Share will still generate a PDF.',
                          style: theme.textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  onPressed: () {
                    context.read<SaleBloc>().add(const SaleCleared());
                    context.go('/pos');
                  },
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('New Sale'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _row(String label, double amount, {bool emphasize = false}) {
    final style = emphasize
        ? const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
        : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          MoneyText(amount, style: style),
        ],
      ),
    );
  }
}
