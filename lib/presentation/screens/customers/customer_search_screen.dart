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
import '../../widgets/empty_state.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/responsive_shell.dart';
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

    return ResponsiveShell(
      appBar: AppBar(
        title: const Text('Customers'),
        actions: [
          TextButton.icon(
            onPressed: () => context.go('/customers/groups'),
            icon: const Icon(Icons.group_work_outlined),
            label: const Text('Manage Groups'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        icon: const Icon(Icons.person_add),
        label: const Text('New'),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: state.customers.length,
                  itemBuilder: (_, i) =>
                      _CustomerCard(customer: state.customers[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final Customer customer;
  const _CustomerCard({required this.customer});

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

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => context.go('/customers/${c.id}'),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: colors.primaryContainer,
                    child: Text(
                      c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: colors.onPrimaryContainer,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.name,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [
                            if (c.phone != null && c.phone!.isNotEmpty)
                              c.phone!,
                            if (c.email != null && c.email!.isNotEmpty)
                              c.email!,
                          ].join(' \u00B7 '),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (groupName != null) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colors.secondaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              groupName,
                              style: TextStyle(
                                fontSize: 11,
                                color: colors.onSecondaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Balance & points
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (c.currentBalance != 0)
                        Text(
                          'Bal: ${c.currentBalance.toStringAsFixed(0)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: c.currentBalance > 0
                                ? colors.error
                                : colors.primary,
                          ),
                        ),
                      if (c.loyaltyPoints > 0)
                        Text(
                          '${c.loyaltyPoints} pts',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: colors.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
