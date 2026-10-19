import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/customer_models.dart';
import '../../blocs/customer/customer_bloc.dart';
import '../../blocs/customer/customer_event.dart';
import '../../blocs/customer/customer_state.dart';
import '../../blocs/customer_group/customer_group_bloc.dart';
import '../../blocs/customer_group/customer_group_event.dart';
import '../../blocs/customer_group/customer_group_state.dart';
import '../../widgets/aduinola/app_page.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/money_text.dart';
import 'customer_form_sheet.dart';

class CustomerSearchScreen extends StatefulWidget {
  const CustomerSearchScreen({super.key});

  @override
  State<CustomerSearchScreen> createState() => _CustomerSearchScreenState();
}

class _CustomerSearchScreenState extends State<CustomerSearchScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<CustomerBloc>().add(const CustomerLoadRequested());
    final gState = context.read<CustomerGroupBloc>().state;
    if (gState.groups.isEmpty) {
      context.read<CustomerGroupBloc>().add(
        const CustomerGroupsLoadRequested(),
      );
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _openCreate() async {
    final c = await showCustomerFormSheet(context);
    if (c != null && mounted) {
      context.read<CustomerBloc>().add(CustomerCreateRequested(c));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return AppPage(
      title: 'Customers',
      actions: [
        TextButton.icon(
          onPressed: () => context.go('/customers/groups'),
          icon: const Icon(Icons.group_work_outlined),
          label: const Text('Manage Groups'),
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        icon: const Icon(Icons.person_add),
        label: const Text('New'),
      ),
      padBody: false,
      body: Column(
        children: [
          Padding(
            padding: AppPage.insets(context, top: 12, bottom: 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                hintText: 'Search name, phone, email',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) =>
                  context.read<CustomerBloc>().add(CustomerSearchChanged(v)),
            ),
          ),
          // Customer count
          BlocSelector<CustomerBloc, CustomerState, int>(
            selector: (state) => state.customers.length,
            builder: (context, count) {
              if (count == 0) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '$count customers',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            },
          ),
          Expanded(
            child: BlocBuilder<CustomerBloc, CustomerState>(
              builder: (context, state) {
                if (state.status == CustomerStatus.loading &&
                    state.customers.isEmpty) {
                  return const LoadingIndicator();
                }
                if (state.customers.isEmpty) {
                  return const EmptyState(
                    title: 'No customers yet',
                    subtitle: 'Tap New to add one',
                    icon: Icons.people_outline,
                  );
                }
                final list = state.customers;
                final padding = EdgeInsets.symmetric(
                  horizontal: AppPage.gutterOf(context),
                );
                // Same flat list-with-divider style as TransactionTile.
                return ListView.separated(
                  padding: padding,
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) => _CustomerTile(customer: list[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// One row: same shape as [TransactionTile] in the Transactions feed \u2014 a
/// "Customer" label line, the name, then phone/email/group on the left;
/// balance and loyalty points on the right.
class _CustomerTile extends StatelessWidget {
  final Customer customer;
  const _CustomerTile({required this.customer});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final c = customer;

    return BlocBuilder<CustomerGroupBloc, CustomerGroupState>(
      buildWhen: (prev, curr) => prev.groups != curr.groups,
      builder: (context, groupState) {
        String? groupName;
        if (c.customerGroupId != null) {
          for (final g in groupState.groups) {
            if (g.id == c.customerGroupId) {
              groupName = g.name;
              break;
            }
          }
        }
        final subtitle = [
          if (c.phone != null && c.phone!.isNotEmpty) c.phone!,
          if (c.email != null && c.email!.isNotEmpty) c.email!,
          ?groupName,
        ].join(' \u00B7 ');

        return InkWell(
          onTap: () => context.go('/customers/${c.id}'),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Customer', style: theme.textTheme.labelSmall?.copyWith(color: colors.primary)),
                      const SizedBox(height: 2),
                      Text(c.name, style: theme.textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                      if (subtitle.isNotEmpty)
                        Text(subtitle, style: theme.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (c.currentBalance != 0)
                      MoneyText(
                        c.currentBalance.abs(),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: c.currentBalance > 0 ? colors.error : colors.primary,
                        ),
                      ),
                    if (c.loyaltyPoints > 0)
                      Text(
                        '${c.loyaltyPoints} pts',
                        style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
