import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/customer_models.dart';
import '../../blocs/customer/customer_bloc.dart';
import '../../blocs/customer/customer_event.dart';
import '../../blocs/customer/customer_state.dart';
import '../../blocs/customer_group/customer_group_bloc.dart';
import '../../blocs/customer_group/customer_group_event.dart';
import '../../blocs/customer_group/customer_group_state.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/money_text.dart';
import '../../widgets/responsive_shell.dart';
import 'customer_form_sheet.dart';

class CustomerDetailScreen extends StatefulWidget {
  final String customerId;
  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  @override
  void initState() {
    super.initState();
    context.read<CustomerBloc>().add(CustomerByIdRequested(widget.customerId));
    final gState = context.read<CustomerGroupBloc>().state;
    if (gState.groups.isEmpty) {
      context.read<CustomerGroupBloc>().add(
        const CustomerGroupsLoadRequested(),
      );
    }
  }

  Future<void> _onEdit(Customer c) async {
    final updated = await showCustomerFormSheet(context, existing: c);
    if (updated == null || !mounted) return;
    context.read<CustomerBloc>().add(CustomerUpdateRequested(c.id, updated));
  }

  Future<void> _onAdjustLoyalty(Customer c) async {
    final result = await showModalBottomSheet<_AdjustResult<int>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AdjustSheet<int>(
        title: 'Adjust loyalty points',
        label: 'Points',
        allowNegative: true,
        integerOnly: true,
        hint: 'e.g. 50 or -10',
      ),
    );
    if (result == null || !mounted) return;
    context.read<CustomerBloc>().add(
      CustomerLoyaltyAdjusted(c.id, result.delta),
    );
  }

  Future<void> _onAdjustBalance(Customer c) async {
    final result = await showModalBottomSheet<_AdjustResult<double>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AdjustSheet<double>(
        title: 'Adjust balance',
        label: 'Amount',
        allowNegative: true,
        integerOnly: false,
        hint: 'Positive = owes more, negative = credit',
      ),
    );
    if (result == null || !mounted) return;
    context.read<CustomerBloc>().add(
      CustomerBalanceAdjusted(c.id, result.delta),
    );
  }

  Future<void> _onDeactivate(Customer c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deactivate customer?'),
        content: Text('${c.name} will be marked inactive.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    context.read<CustomerBloc>().add(
      CustomerUpdateRequested(c.id, c.copyWith(isActive: false)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveShell(
      appBar: AppBar(title: const Text('Customer')),
      child: BlocConsumer<CustomerBloc, CustomerState>(
        listenWhen: (prev, curr) =>
            prev.errorMessage != curr.errorMessage && curr.errorMessage != null,
        listener: (context, state) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage ?? 'Error')),
          );
        },
        builder: (context, state) {
          final c = state.selected;
          if (state.status == CustomerStatus.loading && c == null) {
            return const LoadingIndicator();
          }
          if (state.status == CustomerStatus.error && c == null) {
            return ErrorView(
              message: state.errorMessage ?? 'Failed to load customer',
              onRetry: () => context.read<CustomerBloc>().add(
                CustomerByIdRequested(widget.customerId),
              ),
            );
          }
          if (c == null || c.id != widget.customerId) {
            return const EmptyState(
              title: 'Customer not found',
              icon: Icons.person_off_outlined,
            );
          }
          final busy = state.status == CustomerStatus.updating;
          return Stack(
            children: [
              _DetailBody(
                customer: c,
                onEdit: () => _onEdit(c),
                onAdjustLoyalty: () => _onAdjustLoyalty(c),
                onAdjustBalance: () => _onAdjustBalance(c),
                onDeactivate: c.isActive ? () => _onDeactivate(c) : null,
              ),
              if (busy)
                const Positioned.fill(
                  child: ColoredBox(
                    color: Color(0x22000000),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  final Customer customer;
  final VoidCallback onEdit;
  final VoidCallback onAdjustLoyalty;
  final VoidCallback onAdjustBalance;
  final VoidCallback? onDeactivate;

  const _DetailBody({
    required this.customer,
    required this.onEdit,
    required this.onAdjustLoyalty,
    required this.onAdjustBalance,
    this.onDeactivate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = customer;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 28,
              child: Text(
                c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                style: theme.textTheme.titleLarge,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.name, style: theme.textTheme.titleLarge),
                  if (c.code != null && c.code!.isNotEmpty)
                    Text(c.code!, style: theme.textTheme.bodySmall),
                  Row(
                    children: [
                      Chip(
                        label: Text(c.isActive ? 'Active' : 'Inactive'),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: c.isActive
                            ? theme.colorScheme.primaryContainer
                            : theme.colorScheme.errorContainer,
                      ),
                      if (c.customerType != null) ...[
                        const SizedBox(width: 6),
                        Chip(
                          label: Text(c.customerType!),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Balance',
                value: MoneyText(
                  c.currentBalance,
                  style: theme.textTheme.titleLarge,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Loyalty points',
                value: Text(
                  '${c.loyaltyPoints}',
                  style: theme.textTheme.titleLarge,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              _field(context, 'Phone', c.phone ?? '—'),
              _field(context, 'Email', c.email ?? '—'),
              _field(context, 'Address', c.address ?? '—'),
              _field(context, 'TIN number', c.tinNumber ?? '—'),
              _GroupField(groupId: c.customerGroupId),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit'),
            ),
            OutlinedButton.icon(
              onPressed: onAdjustLoyalty,
              icon: const Icon(Icons.star_outline),
              label: const Text('Adjust loyalty'),
            ),
            OutlinedButton.icon(
              onPressed: onAdjustBalance,
              icon: const Icon(Icons.account_balance_wallet_outlined),
              label: const Text('Adjust balance'),
            ),
            if (onDeactivate != null)
              OutlinedButton.icon(
                onPressed: onDeactivate,
                icon: const Icon(Icons.block),
                label: const Text('Deactivate'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _field(BuildContext context, String label, String value) {
    return ListTile(
      dense: true,
      title: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      subtitle: Text(value),
    );
  }
}

class _GroupField extends StatelessWidget {
  final String? groupId;
  const _GroupField({required this.groupId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CustomerGroupBloc, CustomerGroupState>(
      builder: (context, state) {
        String value = '—';
        if (groupId != null) {
          final g = state.groups.firstWhere(
            (g) => g.id == groupId,
            orElse: () => const CustomerGroup(id: '', name: ''),
          );
          value = g.name.isNotEmpty ? g.name : 'Group $groupId';
        }
        return ListTile(
          dense: true,
          title: const Text(
            'Group',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          subtitle: Text(value),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final Widget value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            value,
          ],
        ),
      ),
    );
  }
}

class _AdjustResult<T extends num> {
  final T delta;
  final String? note;
  _AdjustResult(this.delta, this.note);
}

class _AdjustSheet<T extends num> extends StatefulWidget {
  final String title;
  final String label;
  final String? hint;
  final bool allowNegative;
  final bool integerOnly;

  const _AdjustSheet({
    required this.title,
    required this.label,
    this.hint,
    required this.allowNegative,
    required this.integerOnly,
  });

  @override
  State<_AdjustSheet<T>> createState() => _AdjustSheetState<T>();
}

class _AdjustSheetState<T extends num> extends State<_AdjustSheet<T>> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  int _sign = 1;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final raw = _amount.text.trim();
    T value;
    if (widget.integerOnly) {
      value = (int.parse(raw) * _sign) as T;
    } else {
      value = (double.parse(raw) * _sign) as T;
    }
    Navigator.of(context).pop(
      _AdjustResult<T>(
        value,
        _note.text.trim().isEmpty ? null : _note.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (widget.allowNegative)
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 1, label: Text('Add (+)')),
                      ButtonSegment(value: -1, label: Text('Subtract (-)')),
                    ],
                    selected: {_sign},
                    onSelectionChanged: (s) => setState(() => _sign = s.first),
                  ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _amount,
                  keyboardType: TextInputType.numberWithOptions(
                    decimal: !widget.integerOnly,
                  ),
                  decoration: InputDecoration(
                    labelText: widget.label,
                    hintText: widget.hint,
                  ),
                  validator: (v) {
                    final t = v?.trim() ?? '';
                    if (t.isEmpty) return 'Required';
                    if (widget.integerOnly) {
                      final n = int.tryParse(t);
                      if (n == null) return 'Enter a whole number';
                      if (n <= 0) return 'Enter a positive value';
                    } else {
                      final n = double.tryParse(t);
                      if (n == null) return 'Enter a number';
                      if (n <= 0) return 'Enter a positive value';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _note,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.check),
                  label: const Text('Apply'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
