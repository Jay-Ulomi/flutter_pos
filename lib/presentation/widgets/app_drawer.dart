import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../blocs/auth/auth_bloc.dart';
import '../blocs/business/business_bloc.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final businessState = context.watch<BusinessBloc>().state;
    final user = authState.user;
    final theme = Theme.of(context);
    final businessType =
        businessState.selected?.type ?? authState.selectedBusinessType ?? '';
    final isLaundry = businessType.trim().toUpperCase() == 'LAUNDRY';

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: theme.colorScheme.primary),
              accountName: Text(user?.fullName ?? 'Unknown user'),
              accountEmail: Text(user?.email ?? ''),
              currentAccountPicture: CircleAvatar(
                backgroundColor: theme.colorScheme.secondary,
                child: Text(
                  user != null && user.firstName.isNotEmpty
                      ? user.firstName[0].toUpperCase()
                      : 'U',
                  style: TextStyle(color: theme.colorScheme.onSecondary),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _item(context, Icons.point_of_sale, 'POS', '/pos'),
                  _item(
                    context,
                    Icons.inventory_2_outlined,
                    'Products',
                    '/products',
                  ),
                  _item(
                    context,
                    Icons.receipt_long,
                    isLaundry ? 'Tickets' : 'Sales',
                    '/sales',
                  ),
                  _item(
                    context,
                    Icons.people_outline,
                    'Customers',
                    '/customers',
                  ),
                  _item(context, Icons.sync, 'Sync', '/sync'),
                  const Divider(),
                  _item(
                    context,
                    Icons.settings_outlined,
                    'Settings',
                    '/settings',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(BuildContext context, IconData icon, String label, String path) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: () {
        Navigator.of(context).pop();
        context.go(path);
      },
    );
  }
}
