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
import '../../blocs/sale/sale_state.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/money_text.dart';
import '../../widgets/responsive_shell.dart';

class SaleDetailScreen extends StatefulWidget {
  final String? saleId;
  const SaleDetailScreen({super.key, this.saleId});

  @override
  State<SaleDetailScreen> createState() => _SaleDetailScreenState();
}

class _SaleDetailScreenState extends State<SaleDetailScreen> {
  bool _busy = false;

  String? get saleId => widget.saleId;

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

    final user = authState.user;
    final cashierName = user != null
        ? ('${user.firstName} ${user.lastName}'.trim().isEmpty
              ? user.email
              : '${user.firstName} ${user.lastName}'.trim())
        : null;

    return buildReceiptPdf(
      sale,
      businessName: business?.name,
      branchName: branch?.name,
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
        name: 'receipt-${sale.saleNumber ?? sale.id ?? 'sale'}',
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
        filename: 'receipt-${sale.saleNumber ?? sale.id ?? 'sale'}.pdf',
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

  Sale? _find(SaleState state) {
    Sale? matched;
    for (final s in state.recent) {
      if (s.id == saleId || s.saleNumber == saleId) {
        matched = s;
        break;
      }
    }
    return matched ?? state.lastSale;
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveShell(
      appBar: AppBar(title: const Text('Sale Detail')),
      child: BlocBuilder<SaleBloc, SaleState>(
        builder: (context, state) {
          final sale = _find(state);
          if (sale == null || sale.items.isEmpty) {
            return const EmptyState(
              title: 'Sale not found',
              icon: Icons.receipt_long_outlined,
            );
          }

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sale.saleNumber ?? '#${sale.id ?? ''}',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          if (sale.createdAt != null)
                            Text(Formatters.dateTime(sale.createdAt!)),
                          if (sale.customerName != null)
                            Text('Customer: ${sale.customerName}'),
                          Text('Status: ${sale.status}'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          for (final i in sale.items)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${i.productName} × ${Formatters.quantity(i.quantity)}',
                                    ),
                                  ),
                                  MoneyText(i.totalPrice),
                                ],
                              ),
                            ),
                          const Divider(),
                          _row('Subtotal', sale.subtotal),
                          _row('Tax', sale.taxAmount),
                          if (sale.discountAmount > 0)
                            _row('Discount', -sale.discountAmount),
                          _row('Total', sale.totalAmount, emphasize: true),
                          const SizedBox(height: 6),
                          _row('Paid', sale.paidAmount),
                          _row('Change', sale.changeAmount),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _busy ? null : () => _onPrint(sale),
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
                          icon: const Icon(Icons.share_outlined),
                          label: const Text('Share'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: sale.id != null
                              ? () => context.push(
                                  '/sales/return?saleId=${sale.id}',
                                )
                              : null,
                          icon: const Icon(Icons.undo),
                          label: const Text('Refund'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
