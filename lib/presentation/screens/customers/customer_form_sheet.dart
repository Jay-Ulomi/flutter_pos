import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/customer_models.dart';
import '../../blocs/customer_group/customer_group_bloc.dart';
import '../../blocs/customer_group/customer_group_event.dart';
import '../../blocs/customer_group/customer_group_state.dart';

/// Bottom sheet used for creating and editing customers. Pops with the
/// populated [Customer] when submitted. When [existing] is non-null the
/// fields are pre-filled and the returned customer carries its id.
Future<Customer?> showCustomerFormSheet(
  BuildContext context, {
  Customer? existing,
}) {
  return showModalBottomSheet<Customer>(
    context: context,
    isScrollControlled: true,
    builder: (_) => CustomerFormSheet(existing: existing),
  );
}

class CustomerFormSheet extends StatefulWidget {
  final Customer? existing;
  const CustomerFormSheet({super.key, this.existing});

  @override
  State<CustomerFormSheet> createState() => _CustomerFormSheetState();
}

class _CustomerFormSheetState extends State<CustomerFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _address;
  late final TextEditingController _tin;
  late String _customerType;
  String? _customerGroupId;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    final c = widget.existing;
    _name = TextEditingController(text: c?.name ?? '');
    _phone = TextEditingController(text: c?.phone ?? '');
    _email = TextEditingController(text: c?.email ?? '');
    _address = TextEditingController(text: c?.address ?? '');
    _tin = TextEditingController(text: c?.tinNumber ?? '');
    _customerType = c?.customerType ?? 'INDIVIDUAL';
    _customerGroupId = c?.customerGroupId;
    _isActive = c?.isActive ?? true;

    // Populate the group list if it hasn't been loaded yet.
    final gState = context.read<CustomerGroupBloc>().state;
    if (gState.groups.isEmpty && gState.status != CustomerGroupStatus.loading) {
      context.read<CustomerGroupBloc>().add(
        const CustomerGroupsLoadRequested(),
      );
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _address.dispose();
    _tin.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final existing = widget.existing;
    final result = Customer(
      id: existing?.id ?? '',
      code: existing?.code,
      name: _name.text.trim(),
      phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      email: _email.text.trim().isEmpty ? null : _email.text.trim(),
      address: _address.text.trim().isEmpty ? null : _address.text.trim(),
      tinNumber: _tin.text.trim().isEmpty ? null : _tin.text.trim(),
      customerType: _customerType,
      customerGroupId: _customerGroupId,
      currentBalance: existing?.currentBalance ?? 0,
      loyaltyPoints: existing?.loyaltyPoints ?? 0,
      isActive: _isActive,
      updatedAt: existing?.updatedAt,
    );
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isEdit = widget.existing != null;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
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
                      isEdit ? 'Edit customer' : 'New customer',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
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
                  controller: _phone,
                  decoration: const InputDecoration(labelText: 'Phone'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _email,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    final t = v?.trim() ?? '';
                    if (t.isEmpty) return null;
                    if (!t.contains('@') || !t.contains('.')) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _address,
                  decoration: const InputDecoration(labelText: 'Address'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _tin,
                  decoration: const InputDecoration(labelText: 'TIN number'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _customerType,
                  decoration: const InputDecoration(labelText: 'Customer type'),
                  items: const [
                    DropdownMenuItem(
                      value: 'INDIVIDUAL',
                      child: Text('Individual'),
                    ),
                    DropdownMenuItem(
                      value: 'BUSINESS',
                      child: Text('Business'),
                    ),
                  ],
                  onChanged: (v) =>
                      setState(() => _customerType = v ?? 'INDIVIDUAL'),
                ),
                const SizedBox(height: 12),
                BlocBuilder<CustomerGroupBloc, CustomerGroupState>(
                  builder: (context, state) {
                    final items = <DropdownMenuItem<String?>>[
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('No group'),
                      ),
                      for (final g in state.groups)
                        DropdownMenuItem<String?>(
                          value: g.id,
                          child: Text(g.name),
                        ),
                    ];
                    // Ensure the current selection exists in the list — this
                    // can happen if the cached customer references a group
                    // that we haven't loaded yet.
                    final knownIds = state.groups.map((g) => g.id).toSet();
                    if (_customerGroupId != null &&
                        !knownIds.contains(_customerGroupId)) {
                      items.add(
                        DropdownMenuItem<String?>(
                          value: _customerGroupId,
                          child: Text('Group ${_customerGroupId!}'),
                        ),
                      );
                    }
                    return DropdownButtonFormField<String?>(
                      initialValue: _customerGroupId,
                      decoration: InputDecoration(
                        labelText: 'Customer group',
                        suffixIcon: state.status == CustomerGroupStatus.loading
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      items: items,
                      onChanged: (v) => setState(() => _customerGroupId = v),
                    );
                  },
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                  title: const Text('Active'),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.check),
                  label: Text(isEdit ? 'Save changes' : 'Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
