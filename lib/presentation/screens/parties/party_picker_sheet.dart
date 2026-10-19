import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../data/datasources/remote/feed_remote.dart';
import '../../../data/models/feed_models.dart';
import '../../widgets/aduinola/ui.dart';
import 'parties_screen.dart';

/// Searchable party list in a sheet. [type] limits it to customers or
/// suppliers; [where] filters further (e.g. only parties that owe us).
Future<PartySummary?> showPartyPicker(
  BuildContext context, {
  required FeedRemoteDataSource remote,
  PartyType? type,
  bool Function(PartySummary)? where,
}) {
  return showModalBottomSheet<PartySummary>(
    context: context,
    isScrollControlled: true,
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.85,
      child: _PartyPicker(remote: remote, type: type, where: where),
    ),
  );
}

class _PartyPicker extends StatefulWidget {
  const _PartyPicker({required this.remote, this.type, this.where});
  final FeedRemoteDataSource remote;
  final PartyType? type;
  final bool Function(PartySummary)? where;

  @override
  State<_PartyPicker> createState() => _PartyPickerState();
}

class _PartyPickerState extends State<_PartyPicker> {
  Timer? _debounce;
  List<PartySummary> _items = const [];
  bool _loading = true;
  String? _error;
  int _gen = 0;

  @override
  void initState() {
    super.initState();
    _load('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _load(String search) async {
    final gen = ++_gen;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await widget.remote.getParties(type: widget.type, search: search, size: 50);
      if (!mounted || gen != _gen) return;
      setState(() {
        _items = widget.where == null ? page.items : page.items.where(widget.where!).toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted || gen != _gen) return;
      setState(() {
        _loading = false;
        _error = context.tr('common.load_failed');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr('party.select'), style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                SearchPill(
                  autofocus: false,
                  onChanged: (v) {
                    _debounce?.cancel();
                    _debounce = Timer(const Duration(milliseconds: 300), () => _load(v));
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? MessageView(icon: Icons.cloud_off_rounded, message: _error!, onRetry: () => _load(''))
                    : _items.isEmpty
                        ? MessageView(icon: Icons.groups_outlined, message: context.tr('common.nothing_here'))
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: _items.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 8),
                            itemBuilder: (context, i) => PartyTile(
                              party: _items[i],
                              onTap: () => Navigator.pop(context, _items[i]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
