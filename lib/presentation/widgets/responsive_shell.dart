import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../blocs/auth/auth_bloc.dart';
import '../blocs/business/business_bloc.dart';
import '../blocs/sync/sync_bloc.dart';
import '../blocs/sync/sync_state.dart';

/// Navigation destinations shown in the shell.
class _NavDest {
  const _NavDest(this.icon, this.selectedIcon, this.label, this.path);
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String path;
}

List<_NavDest> _buildDestinations({required String salesLabel}) {
  final list = <_NavDest>[
    const _NavDest(
      Icons.point_of_sale_outlined,
      Icons.point_of_sale,
      'POS',
      '/pos',
    ),
    const _NavDest(
      Icons.inventory_2_outlined,
      Icons.inventory_2,
      'Products',
      '/products',
    ),
    _NavDest(
      Icons.receipt_long_outlined,
      Icons.receipt_long,
      salesLabel,
      '/sales',
    ),
    const _NavDest(
      Icons.people_outline,
      Icons.people,
      'Customers',
      '/customers',
    ),
    const _NavDest(Icons.sync_outlined, Icons.sync, 'Sync', '/sync'),
  ];
  list.add(
    const _NavDest(
      Icons.settings_outlined,
      Icons.settings,
      'Settings',
      '/settings',
    ),
  );
  return list;
}

/// Returns the index in [_kDests] whose path matches [location], or -1.
int _destIndex(String location, List<_NavDest> dests) {
  for (var i = 0; i < dests.length; i++) {
    if (location.startsWith(dests[i].path)) return i;
  }
  return -1;
}

class _PastDueBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isPastDue =
        context.select<AuthBloc, bool>((b) => b.state.isPastDue);
    if (!isPastDue) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      // amber-700 for legible white-on-amber contrast (amber-500 failed WCAG).
      color: const Color(0xFFB45309),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: const Text(
        '⚠️  Subscription past due — contact your administrator to restore full access.',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// A responsive navigation shell.
///
/// - Mobile (width < 720): [Scaffold] with a [Drawer] (current behavior).
/// - Desktop (width >= 720): [Scaffold] with a [NavigationRail] on the left
///   and the body on the right. No drawer is shown.
class ResponsiveShell extends StatelessWidget {
  const ResponsiveShell({
    super.key,
    required this.child,
    this.appBar,
    this.floatingActionButton,
  });

  final Widget child;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthBloc>().state;
    final business = context.watch<BusinessBloc>().state.selected;
    final businessType = business?.type ?? auth.selectedBusinessType ?? '';
    final isLaundry = businessType.trim().toUpperCase() == 'LAUNDRY';
    final destinations = _buildDestinations(
      salesLabel: isLaundry ? 'Tickets' : 'Sales',
    );
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 720;

    if (isDesktop) {
      return _DesktopShell(
        destinations: destinations,
        appBar: appBar,
        floatingActionButton: floatingActionButton,
        child: child,
      );
    }

    return Scaffold(
      appBar: appBar,
      drawer: _AppDrawerWidget(destinations: destinations),
      floatingActionButton: floatingActionButton,
      body: Column(
        children: [
          _PastDueBanner(),
          Expanded(child: child),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Desktop layout
// ---------------------------------------------------------------------------

class _DesktopShell extends StatelessWidget {
  const _DesktopShell({
    required this.destinations,
    required this.child,
    this.appBar,
    this.floatingActionButton,
  });

  final List<_NavDest> destinations;
  final Widget child;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final selectedIndex = _destIndex(location, destinations);

    return Scaffold(
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      body: Column(
        children: [
          _PastDueBanner(),
          Expanded(
            child: Row(
              children: [
                BlocSelector<SyncBloc, SyncBlocState, ({int pending, int failed})>(
                  selector: (s) => (
                    pending: s.status.pendingCount,
                    failed: s.status.failedCount,
                  ),
                  builder: (context, sync) {
                    final colors = Theme.of(context).colorScheme;
                    return NavigationRail(
                      selectedIndex: selectedIndex < 0 ? null : selectedIndex,
                      onDestinationSelected: (i) =>
                          context.go(destinations[i].path),
                      labelType: NavigationRailLabelType.all,
                      backgroundColor: colors.surfaceContainerLow,
                      indicatorColor: colors.primary.withValues(alpha: 0.18),
                      leading: _RailHeader(),
                      destinations: destinations.map((d) {
                        final isSync = d.path == '/sync';
                        Widget icon = Icon(d.icon);
                        Widget selectedIcon = Icon(
                          d.selectedIcon,
                          color: colors.primary,
                        );
                        if (isSync && (sync.pending > 0 || sync.failed > 0)) {
                          final badgeColor = sync.failed > 0
                              ? colors.error
                              : colors.secondary;
                          final label = sync.failed > 0
                              ? '${sync.failed}'
                              : '${sync.pending}';
                          icon = Badge(
                            backgroundColor: badgeColor,
                            label: Text(label),
                            child: icon,
                          );
                          selectedIcon = Badge(
                            backgroundColor: badgeColor,
                            label: Text(label),
                            child: selectedIcon,
                          );
                        }
                        return NavigationRailDestination(
                          icon: icon,
                          selectedIcon: selectedIcon,
                          label: Text(d.label),
                        );
                      }).toList(),
                    );
                  },
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RailHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final user = authState.user;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.primary,
            child: Text(
              user != null && user.firstName.isNotEmpty
                  ? user.firstName[0].toUpperCase()
                  : 'U',
              style: TextStyle(color: theme.colorScheme.onPrimary),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user?.firstName ?? '',
            style: theme.textTheme.labelSmall,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mobile drawer (keeps existing AppDrawer look)
// ---------------------------------------------------------------------------

class _AppDrawerWidget extends StatelessWidget {
  const _AppDrawerWidget({required this.destinations});

  final List<_NavDest> destinations;

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final user = authState.user;
    final theme = Theme.of(context);

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
                children: destinations.map((d) => _item(context, d)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(BuildContext context, _NavDest d) {
    if (d.path == '/sync') {
      return BlocSelector<SyncBloc, SyncBlocState, ({int pending, int failed})>(
        selector: (s) => (
          pending: s.status.pendingCount,
          failed: s.status.failedCount,
        ),
        builder: (context, sync) {
          final colors = Theme.of(context).colorScheme;
          final hasActivity = sync.pending > 0 || sync.failed > 0;
          final badgeColor =
              sync.failed > 0 ? colors.error : colors.secondary;
          final label =
              sync.failed > 0 ? '${sync.failed}' : '${sync.pending}';
          return ListTile(
            leading: hasActivity
                ? Badge(
                    backgroundColor: badgeColor,
                    label: Text(label),
                    child: Icon(d.icon),
                  )
                : Icon(d.icon),
            title: Text(d.label),
            onTap: () {
              Navigator.of(context).pop();
              context.go(d.path);
            },
          );
        },
      );
    }
    return ListTile(
      leading: Icon(d.icon),
      title: Text(d.label),
      onTap: () {
        Navigator.of(context).pop();
        context.go(d.path);
      },
    );
  }
}
