import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/l10n/app_strings.dart';
import '../../blocs/auth/auth_bloc.dart';

/// One tile of the "+" hub.
class HubAction {
  const HubAction(this.labelKey, this.icon, {this.route, this.adminPath, this.permission});
  final String labelKey;
  final IconData icon;

  /// In-app route, when this flow exists in the POS.
  final String? route;

  /// Business Admin path otherwise.
  final String? adminPath;

  /// Hidden for users without this permission.
  final String? permission;
}

const hubSections = <(String, List<HubAction>)>[
  ('Sales Transactions', [
    HubAction('tx.sale', Icons.sell_outlined, route: '/pos'),
    HubAction('tx.payment_in', Icons.move_to_inbox_outlined, route: '/payment-in', permission: 'manage_accounting'),
    HubAction('tx.sale_return', Icons.assignment_return_outlined, route: '/sales'),
    HubAction('tx.quotation', Icons.request_quote_outlined, adminPath: '/quotations'),
  ]),
  ('Purchase Transactions', [
    HubAction('tx.purchase', Icons.shopping_cart_outlined, adminPath: '/purchases'),
    HubAction('tx.payment_out', Icons.outbox_outlined, adminPath: '/payables'),
    HubAction('tx.debit_note', Icons.receipt_outlined, adminPath: '/purchases/returns'),
  ]),
  ('Other Transactions', [
    HubAction('tx.expense', Icons.account_balance_wallet_outlined, adminPath: '/expenses'),
    HubAction('tx.party_transfer', Icons.swap_horiz_rounded, route: '/party-transfer', permission: 'manage_accounting'),
  ]),
];

/// Opens the transaction hub sheet (the round "+" in the action bar).
Future<void> showTransactionHub(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const TransactionHubSheet(),
  );
}

class TransactionHubSheet extends StatelessWidget {
  const TransactionHubSheet({super.key});

  void _open(BuildContext context, HubAction a) {
    Navigator.of(context).pop();
    if (a.route != null) {
      // /pos is a tab root; the forms are pushed so Back returns here.
      a.route == '/pos' ? context.go(a.route!) : context.push(a.route!);
    } else {
      showAdminLink(context, a.adminPath!, title: context.tr(a.labelKey));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final auth = context.read<AuthBloc>().state;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (title, all) in hubSections)
              if (all.where((a) => a.permission == null || auth.can(a.permission!)).toList()
                  case final actions when actions.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 12),
                child: Text(title, style: theme.textTheme.titleMedium),
              ),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.92,
                children: [
                  for (final a in actions)
                    Material(
                      color: cs.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: cs.outlineVariant),
                      ),
                      child: InkWell(
                        key: ValueKey('hub-${a.labelKey}'),
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _open(context, a),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: cs.primaryContainer,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(a.icon, color: cs.primary),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                context.tr(a.labelKey),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelMedium,
                              ),
                              if (a.route == null)
                                Icon(Icons.open_in_new_rounded, size: 12, color: cs.onSurfaceVariant),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Explains that a flow lives in Business Admin and offers the link
/// (copy / share — the POS has no in-app browser).
Future<void> showAdminLink(BuildContext context, String path, {required String title}) {
  final url = '${ApiConstants.businessAdminUrl}$path';
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(ctx.tr('common.open_admin')),
          const SizedBox(height: 12),
          SelectableText(url, style: TextStyle(color: Theme.of(ctx).colorScheme.primary)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: url));
            if (ctx.mounted) Navigator.pop(ctx);
          },
          child: const Text('Copy link'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(ctx);
            Share.shareUri(Uri.parse(url));
          },
          child: const Text('Open'),
        ),
      ],
    ),
  );
}
