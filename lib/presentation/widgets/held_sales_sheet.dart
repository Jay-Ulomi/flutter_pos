import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../blocs/cart/cart_bloc.dart';
import '../blocs/cart/cart_event.dart';
import '../blocs/held_sales/held_sales_cubit.dart';
import 'aduinola/ui.dart';
import 'money_text.dart';

Future<void> showHeldSalesSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => BlocProvider.value(
      value: context.read<HeldSalesCubit>(),
      child: const _HeldSalesSheet(),
    ),
  );
}

class _HeldSalesSheet extends StatelessWidget {
  const _HeldSalesSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<HeldSalesCubit, List<HeldSale>>(
      builder: (context, held) {
        return FractionallySizedBox(
          heightFactor: 0.5,
          child: Column(
            children: [
              SheetHeader(
                title: 'Held Sales (${held.length})',
                icon: Icons.pause_circle_outline,
              ),
              Expanded(
                child: held.isEmpty
                    ? const Center(child: Text('No held sales'))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemCount: held.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final sale = held[i];
                          final time = DateFormat.jm().format(sale.heldAt);
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: theme.colorScheme.primaryContainer,
                              foregroundColor: theme.colorScheme.primary,
                              child: Text('${sale.itemCount}'),
                            ),
                            title: Text(sale.label),
                            subtitle: Text(
                              sale.customerName != null
                                  ? '${sale.customerName} \u00B7 $time'
                                  : 'Walk-in \u00B7 $time',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                MoneyText(
                                  sale.total,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  tooltip: 'Remove',
                                  icon: Icon(
                                    Icons.delete_outline,
                                    color: theme.colorScheme.error,
                                  ),
                                  onPressed: () => context
                                      .read<HeldSalesCubit>()
                                      .remove(sale.id),
                                ),
                              ],
                            ),
                            onTap: () {
                              context.read<CartBloc>().add(
                                CartRestored(
                                  lines: sale.lines,
                                  discount: sale.discount,
                                  customerId: sale.customerId,
                                  customerName: sale.customerName,
                                  charges: sale.charges,
                                ),
                              );
                              context.read<HeldSalesCubit>().remove(sale.id);
                              Navigator.of(context).pop();
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
