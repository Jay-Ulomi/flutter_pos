import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/session/session_bloc.dart';
import '../../blocs/session/session_event.dart';
import '../../blocs/session/session_state.dart';

class OpenSessionScreen extends StatefulWidget {
  const OpenSessionScreen({super.key});

  @override
  State<OpenSessionScreen> createState() => _OpenSessionScreenState();
}

class _OpenSessionScreenState extends State<OpenSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cashCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<SessionBloc>().add(const SessionLoadRequested());
  }

  @override
  void dispose() {
    _cashCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    final amount = double.tryParse(_cashCtrl.text) ?? 0;
    context.read<SessionBloc>().add(
      SessionOpenRequested(
        openingCash: amount,
        notes: _notesCtrl.text.isEmpty ? null : _notesCtrl.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Open Session')),
      body: BlocConsumer<SessionBloc, SessionState>(
        listener: (context, state) {
          if (state.status == SessionStatus.error &&
              state.errorMessage != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
          }
        },
        builder: (context, state) {
          final loading = state.status == SessionStatus.loading;
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Enter the opening cash float to start your shift.',
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _cashCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Opening cash',
                      hintText: '0.00',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return null; // empty = 0, allowed
                      final n = double.tryParse(v);
                      if (n == null || n < 0) return 'Invalid amount';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _notesCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                      prefixIcon: Icon(Icons.note_outlined),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: loading ? null : _submit,
                    icon: loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.play_arrow),
                    label: const Text('Open Session'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
