import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/customer_models.dart';
import '../../blocs/customer_group/customer_group_bloc.dart';
import '../../blocs/customer_group/customer_group_event.dart';
import '../../blocs/customer_group/customer_group_state.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/responsive_shell.dart';

class CustomerGroupsScreen extends StatefulWidget {
  const CustomerGroupsScreen({super.key});

  @override
  State<CustomerGroupsScreen> createState() => _CustomerGroupsScreenState();
}

class _CustomerGroupsScreenState extends State<CustomerGroupsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<CustomerGroupBloc>().add(const CustomerGroupsLoadRequested());
  }

  Future<void> _openEditor({CustomerGroup? existing}) async {
    final result = await showModalBottomSheet<CustomerGroup>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _GroupFormSheet(existing: existing),
    );
    if (result == null || !mounted) return;
    final bloc = context.read<CustomerGroupBloc>();
    if (existing == null) {
      bloc.add(CustomerGroupCreateRequested(result));
    } else {
      bloc.add(CustomerGroupUpdateRequested(existing.id, result));
    }
  }

  Future<void> _confirmDelete(CustomerGroup group) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete group?'),
        content: Text('Are you sure you want to delete "${group.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      context.read<CustomerGroupBloc>().add(
        CustomerGroupDeleteRequested(group.id),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveShell(
      appBar: AppBar(title: const Text('Customer Groups')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add),
        label: const Text('New group'),
      ),
      child: BlocConsumer<CustomerGroupBloc, CustomerGroupState>(
        listenWhen: (prev, curr) =>
            prev.errorMessage != curr.errorMessage && curr.errorMessage != null,
        listener: (context, state) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage ?? 'Error')),
          );
        },
        builder: (context, state) {
          if (state.status == CustomerGroupStatus.loading &&
              state.groups.isEmpty) {
            return const LoadingIndicator();
          }
          if (state.groups.isEmpty) {
            return const EmptyState(
              title: 'No customer groups',
              subtitle: 'Tap "New group" to create one.',
              icon: Icons.group_outlined,
            );
          }
          return RefreshIndicator(
            onRefresh: () async => context.read<CustomerGroupBloc>().add(
              const CustomerGroupsLoadRequested(),
            ),
            child: ListView.separated(
              itemCount: state.groups.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final g = state.groups[i];
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      g.name.isNotEmpty ? g.name[0].toUpperCase() : '?',
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(child: Text(g.name)),
                      if (!g.isActive)
                        const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Chip(
                            label: Text('Inactive'),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                    ],
                  ),
                  subtitle: Text(
                    [
                      if (g.description != null && g.description!.isNotEmpty)
                        g.description!,
                      if (g.discountPercent != null)
                        'Discount ${g.discountPercent!.toStringAsFixed(1)}%',
                    ].join(' · '),
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'edit') {
                        _openEditor(existing: g);
                      } else if (v == 'delete') {
                        _confirmDelete(g);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                  onTap: () => _openEditor(existing: g),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _GroupFormSheet extends StatefulWidget {
  final CustomerGroup? existing;
  const _GroupFormSheet({this.existing});

  @override
  State<_GroupFormSheet> createState() => _GroupFormSheetState();
}

class _GroupFormSheetState extends State<_GroupFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _discount;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _description = TextEditingController(text: e?.description ?? '');
    _discount = TextEditingController(
      text: e?.discountPercent != null
          ? e!.discountPercent!.toStringAsFixed(2)
          : '',
    );
    _isActive = e?.isActive ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _discount.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final discountText = _discount.text.trim();
    final group = CustomerGroup(
      id: widget.existing?.id ?? '',
      name: _name.text.trim(),
      description: _description.text.trim().isEmpty
          ? null
          : _description.text.trim(),
      discountPercent: discountText.isEmpty ? null : double.parse(discountText),
      isActive: _isActive,
    );
    Navigator.of(context).pop(group);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isEdit = widget.existing != null;
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
                      isEdit ? 'Edit group' : 'New group',
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
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _description,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _discount,
                  decoration: const InputDecoration(
                    labelText: 'Discount percent',
                    suffixText: '%',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (v) {
                    final t = v?.trim() ?? '';
                    if (t.isEmpty) return null;
                    final n = double.tryParse(t);
                    if (n == null) return 'Enter a valid number';
                    if (n < 0 || n > 100) return 'Must be between 0 and 100';
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                  title: const Text('Active'),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.check),
                  label: Text(isEdit ? 'Save changes' : 'Create'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
