import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/exceptions.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/datasources/remote/feed_remote.dart';
import '../../../data/models/feed_models.dart';
import '../../../di/injection.dart';
import '../../blocs/feeds/feed_cubits.dart';
import '../../widgets/aduinola/ui.dart';
import '../../widgets/money_text.dart';
import '../../widgets/aduinola/app_page.dart';

/// Customers and suppliers in one list with what each owes / is owed.
class PartiesScreen extends StatelessWidget {
  const PartiesScreen({super.key, this.cubit});

  final PartiesCubit? cubit;

  @override
  Widget build(BuildContext context) {
    final c = cubit;
    if (c != null) return BlocProvider.value(value: c..refresh(), child: const _PartiesView());
    return BlocProvider(
      create: (_) => PartiesCubit(sl<FeedRemoteDataSource>())..refresh(),
      child: const _PartiesView(),
    );
  }
}

class _PartiesView extends StatefulWidget {
  const _PartiesView();

  @override
  State<_PartiesView> createState() => _PartiesViewState();
}

enum _PartyFilter { all, customers, suppliers }

class _PartiesViewState extends State<_PartiesView> {
  Timer? _debounce;
  _PartyFilter _filter = _PartyFilter.all;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  PartiesCubit get _cubit => context.read<PartiesCubit>();

  Future<void> _newParty() async {
    final created = await showNewPartySheet(context);
    if (created == true && mounted) _cubit.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final labels = {
      _PartyFilter.all: context.tr('common.all'),
      _PartyFilter.customers: context.tr('party.customers'),
      _PartyFilter.suppliers: context.tr('party.suppliers'),
    };
    return AppPage(
      title: context.tr('party.title'),
      padBody: false,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'new-party',
        onPressed: _newParty,
        shape: const StadiumBorder(),
        icon: const Icon(Icons.person_add_alt_1_outlined),
        label: Text(context.tr('party.new')),
      ),
      body: BlocBuilder<PartiesCubit, FeedState<PartySummary>>(
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: _cubit.refresh,
            child: NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (n.metrics.pixels > n.metrics.maxScrollExtent - 300) _cubit.loadMore();
                return false;
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: AppPage.insets(context, top: 4, bottom: 12),
                    sliver: SliverToBoxAdapter(
                      child: SearchPill(
                        hint: context.tr('common.search'),
                        onChanged: (v) {
                          _debounce?.cancel();
                          _debounce = Timer(const Duration(milliseconds: 350), () => _cubit.setSearch(v));
                        },
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: PillChips<_PartyFilter>(
                      padding: EdgeInsets.symmetric(horizontal: AppPage.gutterOf(context)),
                      items: _PartyFilter.values,
                      selected: _filter,
                      labelOf: (f) => labels[f]!,
                      onSelected: (f) {
                        setState(() => _filter = f);
                        _cubit.setType(switch (f) {
                          _PartyFilter.all => null,
                          _PartyFilter.customers => PartyType.customer,
                          _PartyFilter.suppliers => PartyType.supplier,
                        });
                      },
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                  if (state.loading && state.items.isEmpty)
                    const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
                  else if (state.error != null && state.items.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: MessageView(
                        icon: Icons.cloud_off_rounded,
                        message: state.error!,
                        onRetry: _cubit.refresh,
                      ),
                    )
                  else if (state.items.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: MessageView(
                        icon: Icons.groups_outlined,
                        message: context.tr('common.nothing_here'),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: AppPage.insets(context, top: 0, bottom: 96),
                      // More columns on wide screens instead of side gutters.
                      sliver: SliverGrid.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: responsiveColumns(MediaQuery.sizeOf(context).width),
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 12,
                          mainAxisExtent: 84,
                        ),
                        itemCount: state.items.length,
                        itemBuilder: (context, i) => PartyTile(party: state.items[i]),
                      ),
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

class PartyTile extends StatelessWidget {
  const PartyTile({super.key, required this.party, this.onTap});
  final PartySummary party;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    // `balance` is always positive; direction carries the sign.
    final (label, color) = switch (party.direction) {
      BalanceDirection.receivable => (context.tr('party.to_receive'), cs.primary),
      BalanceDirection.payable => (context.tr('party.to_pay'), cs.secondary),
      BalanceDirection.settled => (context.tr('party.settled'), cs.onSurfaceVariant),
    };
    final subtitle = [
      party.type == PartyType.customer ? context.tr('party.customer') : context.tr('party.supplier'),
      if (party.phone?.isNotEmpty == true) party.phone!,
    ].join('  ·  ');
    return SoftCard(
      padding: const EdgeInsets.all(12),
      onTap: onTap ??
          (party.type == PartyType.customer ? () => context.push('/customers/${party.id}') : null),
      child: Row(
        children: [
          InitialsAvatar(party.name),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(party.name, style: theme.textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(subtitle, style: theme.textTheme.bodySmall),
                if (party.lastActivityAt != null)
                  Text(Formatters.date(party.lastActivityAt!), style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (party.direction != BalanceDirection.settled)
                MoneyText(party.balance, style: theme.textTheme.titleMedium?.copyWith(color: color)),
              Text(label, style: theme.textTheme.bodySmall?.copyWith(color: color)),
            ],
          ),
        ],
      ),
    );
  }
}

/// New customer or supplier. Returns true when saved.
Future<bool?> showNewPartySheet(BuildContext context, {FeedRemoteDataSource? remote}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _NewPartySheet(remote: remote ?? sl<FeedRemoteDataSource>()),
  );
}

class _NewPartySheet extends StatefulWidget {
  const _NewPartySheet({required this.remote});
  final FeedRemoteDataSource remote;

  @override
  State<_NewPartySheet> createState() => _NewPartySheetState();
}

class _NewPartySheetState extends State<_NewPartySheet> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  PartyType _type = PartyType.customer;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_form.currentState?.validate() != true) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.remote.createParty(
        type: _type,
        name: _name.text,
        phone: _phone.text,
        email: _email.text,
      );
      if (mounted) Navigator.pop(context, true);
    } on ServerException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = context.tr('common.load_failed'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(context.tr('party.new'), style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                SegmentedButton<PartyType>(
                  segments: [
                    ButtonSegment(value: PartyType.customer, label: Text(context.tr('party.customer'))),
                    ButtonSegment(value: PartyType.supplier, label: Text(context.tr('party.supplier'))),
                  ],
                  selected: {_type},
                  onSelectionChanged: (s) => setState(() => _type = s.first),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const ValueKey('party-name'),
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(hintText: context.tr('party.name')),
                  validator: (v) => v == null || v.trim().isEmpty ? context.tr('party.name') : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(hintText: context.tr('party.phone')),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(hintText: context.tr('auth.email')),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(_error!, style: TextStyle(color: cs.error)),
                  ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : Text(context.tr('common.save')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
