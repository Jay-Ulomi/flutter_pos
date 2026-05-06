import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/customer_models.dart';
import '../blocs/customer/customer_bloc.dart';
import '../blocs/customer/customer_event.dart';
import '../blocs/customer/customer_state.dart';

/// Result of the picker: `null` means "keep as-is"; a [PickedCustomer]
/// indicates the user chose someone or explicitly cleared selection.
class PickedCustomer {
  final Customer? customer;
  const PickedCustomer(this.customer);

  /// "Walk-in (no customer)" sentinel.
  bool get isWalkIn => customer == null;
}

/// Shows the customer picker bottom sheet.
/// Returns `null` if dismissed.
Future<PickedCustomer?> showCustomerPickerSheet(BuildContext context) {
  return showModalBottomSheet<PickedCustomer>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => const CustomerPickerSheet(),
  );
}

class CustomerPickerSheet extends StatefulWidget {
  const CustomerPickerSheet({super.key});

  @override
  State<CustomerPickerSheet> createState() => _CustomerPickerSheetState();
}

class _CustomerPickerSheetState extends State<CustomerPickerSheet> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<CustomerBloc>().add(const CustomerLoadRequested());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FractionallySizedBox(
      heightFactor: 0.85,
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Text('Select customer', style: theme.textTheme.titleLarge),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
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
            ListTile(
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.secondaryContainer,
                child: const Icon(Icons.person_outline),
              ),
              title: const Text('Walk-in (no customer)'),
              subtitle: const Text('Sale not attached to any customer'),
              onTap: () =>
                  Navigator.of(context).pop(const PickedCustomer(null)),
            ),
            const Divider(height: 1),
            Expanded(
              child: BlocBuilder<CustomerBloc, CustomerState>(
                builder: (context, state) {
                  if (state.status == CustomerStatus.loading &&
                      state.customers.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state.status == CustomerStatus.error &&
                      state.customers.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          state.errorMessage ?? 'Failed to load customers',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  if (state.customers.isEmpty) {
                    return const Center(child: Text('No customers found'));
                  }
                  return ListView.separated(
                    itemCount: state.customers.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final c = state.customers[i];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                          ),
                        ),
                        title: Text(c.name),
                        subtitle: Text(
                          [c.phone, c.email]
                              .whereType<String>()
                              .where((e) => e.isNotEmpty)
                              .join(' · '),
                        ),
                        trailing: c.currentBalance != 0
                            ? Text(
                                'Bal: ${c.currentBalance.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: c.currentBalance > 0
                                      ? theme.colorScheme.error
                                      : theme.colorScheme.primary,
                                ),
                              )
                            : null,
                        onTap: () =>
                            Navigator.of(context).pop(PickedCustomer(c)),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
