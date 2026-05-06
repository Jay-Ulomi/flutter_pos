import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/sale_models.dart';
import '../../blocs/sale/sale_bloc.dart';
import '../../blocs/sale/sale_event.dart';
import '../../blocs/sale/sale_state.dart';
import '../../widgets/money_text.dart';

class ReturnScreen extends StatefulWidget {
  final Sale sale;
  const ReturnScreen({super.key, required this.sale});

  @override
  State<ReturnScreen> createState() => _ReturnScreenState();
}

class _ReturnScreenState extends State<ReturnScreen> {
  late final Map<int, double> _returnQtys;
  final _reasonCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _returnQtys = {for (var i = 0; i < widget.sale.items.length; i++) i: 0};
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  bool get _hasSelection => _returnQtys.values.any((q) => q > 0);

  double get _returnTotal {
    double total = 0;
    _returnQtys.forEach((i, qty) {
      if (qty > 0) {
        final item = widget.sale.items[i];
        total += item.unitPrice * qty;
      }
    });
    return total;
  }

  void _submit() {
    if (!_hasSelection) return;
    if (_reasonCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a reason for the return')),
      );
      return;
    }

    final returnItems = <Map<String, dynamic>>[];
    _returnQtys.forEach((i, qty) {
      if (qty > 0) {
        final item = widget.sale.items[i];
        returnItems.add({
          'productId': item.productId,
          'quantity': qty,
          'unitPrice': item.unitPrice,
        });
      }
    });

    context.read<SaleBloc>().add(
      SaleReturnRequested(
        saleId: widget.sale.id!,
        returnItems: returnItems,
        reason: _reasonCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Process Return')),
      body: BlocListener<SaleBloc, SaleState>(
        listener: (context, state) {
          if (state.status == SaleStatus.returned) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Return processed successfully')),
            );
            context.go('/sales');
          } else if (state.status == SaleStatus.error &&
              state.errorMessage != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
          }
        },
        child: BlocBuilder<SaleBloc, SaleState>(
          builder: (context, saleState) {
            final processing = saleState.status == SaleStatus.returning;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Original Sale: ${widget.sale.saleNumber ?? '#${widget.sale.id}'}',
                          style: theme.textTheme.titleMedium,
                        ),
                        if (widget.sale.customerName != null)
                          Text('Customer: ${widget.sale.customerName}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Select items to return',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      for (var i = 0; i < widget.sale.items.length; i++)
                        _itemRow(i, widget.sale.items[i], theme),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (_hasSelection) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer.withValues(
                        alpha: 0.4,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Refund amount',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        MoneyText(
                          _returnTotal,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: _reasonCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Reason for return',
                    hintText: 'e.g. Defective product, wrong item',
                    prefixIcon: Icon(Icons.note_alt_outlined),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: (processing || !_hasSelection) ? null : _submit,
                  icon: processing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.undo),
                  label: const Text('Process Return'),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.error,
                    foregroundColor: theme.colorScheme.onError,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _itemRow(int index, SaleItem item, ThemeData theme) {
    final qty = _returnQtys[index] ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Sold: ${item.quantity.toStringAsFixed(item.quantity == item.quantity.floor() ? 0 : 2)} × ',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          MoneyText(item.unitPrice, style: theme.textTheme.bodySmall),
          const SizedBox(width: 8),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: qty > 0
                ? () => setState(() => _returnQtys[index] = qty - 1)
                : null,
            icon: const Icon(Icons.remove_circle_outline),
          ),
          SizedBox(
            width: 28,
            child: Text(
              qty.toStringAsFixed(qty == qty.floor() ? 0 : 2),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall,
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: qty < item.quantity
                ? () => setState(() => _returnQtys[index] = qty + 1)
                : null,
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }
}
