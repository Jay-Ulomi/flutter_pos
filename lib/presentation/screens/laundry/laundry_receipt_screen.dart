import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/laundry_receipt_pdf.dart';
import '../../../data/models/business_models.dart';
import '../../../data/models/laundry_models.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/business/business_bloc.dart';
import '../../widgets/money_text.dart';

class LaundryReceiptScreen extends StatefulWidget {
  const LaundryReceiptScreen({super.key, required this.order});

  final LaundryOrder order;

  @override
  State<LaundryReceiptScreen> createState() => _LaundryReceiptScreenState();
}

class _LaundryReceiptScreenState extends State<LaundryReceiptScreen> {
  bool _busy = false;

  String? get _cashierName {
    final user = context.read<AuthBloc>().state.user;
    if (user == null) return null;
    final full = '${user.firstName} ${user.lastName}'.trim();
    return full.isEmpty ? user.email : full;
  }

  Future<Uint8List> _buildPdfBytes(LaundryOrder order) async {
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

    return buildLaundryReceiptPdf(
      order,
      businessName: business?.name,
      branchName: branch?.name,
      businessAddress: business?.address,
      businessPhone: business?.phone,
      tinNumber: business?.tinNumber,
      cashierName: _cashierName,
    );
  }

  Future<void> _onPrint(LaundryOrder order) async {
    setState(() => _busy = true);
    try {
      await Printing.layoutPdf(
        onLayout: (_) async => _buildPdfBytes(order),
        name: 'laundry-${order.ticketNumber}',
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

  Future<void> _onShare(LaundryOrder order) async {
    setState(() => _busy = true);
    try {
      final bytes = await _buildPdfBytes(order);
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'laundry-${order.ticketNumber}.pdf',
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
    final order = widget.order;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Laundry Receipt')),
      body: Column(
        children: [
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
                      Text('Ticket Created', style: theme.textTheme.titleLarge),
                      Text(
                        order.ticketNumber,
                        style: theme.textTheme.bodyMedium,
                      ),
                      if (order.createdAt != null)
                        Text(
                          Formatters.dateTime(order.createdAt!),
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
                        for (final item in order.items)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${item.itemName} × ${Formatters.quantity(item.quantity)}',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                MoneyText(item.lineTotal),
                              ],
                            ),
                          ),
                        const Divider(),
                        _row('Total', order.totalAmount, emphasize: true),
                        _row('Paid', order.paidAmount),
                        _row('Balance', order.balanceAmount),
                        if ((order.customerName ?? '').isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.person_outline, size: 16),
                              const SizedBox(width: 6),
                              Expanded(child: Text(order.customerName!)),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _busy ? null : () => _onPrint(order),
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
                        onPressed: _busy ? null : () => _onShare(order),
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
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: () => context.go('/pos'),
              icon: const Icon(Icons.add),
              label: const Text('New Ticket'),
            ),
          ),
        ],
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
