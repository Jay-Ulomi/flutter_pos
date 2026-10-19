import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/business/business_bloc.dart';
import '../blocs/sync/sync_bloc.dart';
import '../blocs/sync/sync_state.dart';
import 'aduinola/ui.dart';

/// A navigation destination.
class _NavDest {
  const _NavDest(
    this.icon,
    this.selectedIcon,
    this.labelKey,
    this.path, {
    this.also = const [],
  });
  final IconData icon;
  final IconData selectedIcon;

  /// AppStrings key, or a literal label when it has no dot.
  final String labelKey;
  final String path;

  /// Other route prefixes that highlight this tab.
  final List<String> also;

  String label(BuildContext context) =>
      labelKey.contains('.') ? context.tr(labelKey) : labelKey;

  bool matches(String location) =>
      location.startsWith(path) || also.any(location.startsWith);
}

/// The five bottom tabs of the redesign.
const _tabs = <_NavDest>[
  _NavDest(Icons.home_outlined, Icons.home_rounded, 'nav.home', '/pos'),
  _NavDest(
    Icons.payments_outlined,
    Icons.payments_rounded,
    'nav.transactions',
    '/transactions',
    also: ['/payment-in', '/party-transfer', '/sales'],
  ),
  _NavDest(
    Icons.groups_outlined,
    Icons.groups_rounded,
    'nav.parties',
    '/parties',
    also: ['/customers'],
  ),
  _NavDest(
    Icons.inventory_2_outlined,
    Icons.inventory_2_rounded,
    'nav.inventory',
    '/products',
  ),
  _NavDest(
    Icons.person_outline_rounded,
    Icons.person_rounded,
    'nav.profile',
    '/profile',
    also: ['/app-settings', '/settings', '/reports', '/sync'],
  ),
];

/// Extra routes reachable from the drawer (mobile) and rail (desktop).
List<_NavDest> _extras({required bool isLaundry}) => [
  _NavDest(
    Icons.receipt_long_outlined,
    Icons.receipt_long,
    isLaundry ? 'Tickets' : 'Sales history',
    '/sales',
  ),
  const _NavDest(Icons.people_outline, Icons.people, 'Customers', '/customers'),
  const _NavDest(
    Icons.bar_chart_outlined,
    Icons.bar_chart,
    'report.title',
    '/reports',
  ),
  const _NavDest(Icons.sync_outlined, Icons.sync, 'profile.sync', '/sync'),
  const _NavDest(
    Icons.storefront_outlined,
    Icons.storefront,
    'profile.business_settings',
    '/settings',
  ),
  const _NavDest(
    Icons.tune_outlined,
    Icons.tune,
    'profile.app_settings',
    '/app-settings',
  ),
];

int _tabIndex(String location) {
  for (var i = 0; i < _tabs.length; i++) {
    if (_tabs[i].matches(location)) return i;
  }
  return -1;
}

class _PastDueBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isPastDue = context.select<AuthBloc, bool>((b) => b.state.isPastDue);
    if (!isPastDue) return const SizedBox.shrink();
    final daysLeft = context.select<AuthBloc, int?>(
      (b) => b.state.gracePeriodDaysRemaining,
    );
    final message = daysLeft != null
        ? '⚠️  Subscription past due — $daysLeft day${daysLeft == 1 ? '' : 's'} left to restore access before service is suspended.'
        : '⚠️  Subscription past due — contact your administrator to restore full access.';
    return Container(
      width: double.infinity,
      // amber-700 for legible white-on-amber contrast (amber-500 failed WCAG).
      color: const Color(0xFFB45309),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        message,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// A responsive navigation shell on the brand gradient.
///
/// - Mobile (width < 720): bottom pill navigation (Home, Transactions,
///   Parties, Inventory, Profile) plus a drawer for the remaining routes.
///   [actionBar] (e.g. the two-action "New Sale  +  Purchase" bar) sits
///   above the navigation.
/// - Desktop (width >= 720): a [NavigationRail] on the left.
class ResponsiveShell extends StatelessWidget {
  const ResponsiveShell({
    super.key,
    required this.child,
    this.appBar,
    this.floatingActionButton,
    this.actionBar,
    this.showBottomNav = true,
  });

  final Widget child;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final Widget? actionBar;
  final bool showBottomNav;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthBloc>().state;
    final business = context.watch<BusinessBloc>().state.selected;
    final businessType = business?.type ?? auth.selectedBusinessType ?? '';
    final isLaundry = businessType.trim().toUpperCase() == 'LAUNDRY';
    final extras = _extras(isLaundry: isLaundry);
    final isDesktop = MediaQuery.sizeOf(context).width >= 720;
    final location = GoRouterState.of(context).matchedLocation;

    if (isDesktop) {
      return _DesktopShell(
        destinations: [..._tabs.take(4), ...extras, _tabs[4]],
        location: location,
        appBar: appBar,
        floatingActionButton: floatingActionButton,
        actionBar: actionBar,
        child: child,
      );
    }

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: appBar,
        drawer: _ShellDrawer(destinations: extras),
        floatingActionButton: floatingActionButton,
        body: Column(
          children: [
            _PastDueBanner(),
            Expanded(child: child),
          ],
        ),
        bottomNavigationBar: !showBottomNav && actionBar == null
            ? null
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (actionBar != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                      child: actionBar,
                    ),
                  if (showBottomNav)
                    PillBottomNav(
                      selectedIndex: _tabIndex(location),
                      onSelected: (i) => context.go(_tabs[i].path),
                    ),
                ],
              ),
      ),
    );
  }
}

/// Bottom navigation: round icon buttons, the active one expands into a
/// primary pill with its label.
class PillBottomNav extends StatelessWidget {
  const PillBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surface,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLg),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < _tabs.length; i++)
                // The active pill may shrink (label ellipsis) on narrow phones.
                Flexible(
                  flex: i == selectedIndex ? 1 : 0,
                  child: _PillTab(
                    dest: _tabs[i],
                    selected: i == selectedIndex,
                    onTap: () => onSelected(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PillTab extends StatelessWidget {
  const _PillTab({
    required this.dest,
    required this.selected,
    required this.onTap,
  });
  final _NavDest dest;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final label = dest.label(context);
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      child: InkWell(
        key: ValueKey('tab-${dest.path}'),
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          height: 48,
          padding: EdgeInsets.only(left: 4, right: selected ? 14 : 4),
          decoration: BoxDecoration(
            color: selected ? cs.primaryContainer : cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: selected ? cs.primary : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  selected ? dest.selectedIcon : dest.icon,
                  size: 22,
                  color: selected ? cs.onPrimary : cs.onSurfaceVariant,
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 6),
                Flexible(
                  child: ExcludeSemantics(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: cs.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The two-action bar from the design: outlined/filled primary action, a
/// round "+" (opens the transaction hub) and a secondary (orange) action.
class TwoActionBar extends StatelessWidget {
  const TwoActionBar({
    super.key,
    required this.leftLabel,
    required this.leftIcon,
    required this.onLeft,
    required this.rightLabel,
    required this.rightIcon,
    required this.onRight,
    required this.onPlus,
    this.rightIsSecondary = false,
  });

  final String leftLabel;
  final IconData leftIcon;
  final VoidCallback? onLeft;
  final String rightLabel;
  final IconData rightIcon;
  final VoidCallback? onRight;
  final VoidCallback onPlus;

  /// Paint the right button orange (e.g. "Purchase").
  final bool rightIsSecondary;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: onLeft,
            icon: Icon(leftIcon, size: 20),
            label: Text(leftLabel, overflow: TextOverflow.ellipsis),
          ),
        ),
        const SizedBox(width: 10),
        RoundIconButton(
          icon: Icons.add_rounded,
          tooltip: context.tr('tx.new'),
          onPressed: onPlus,
          size: 48,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton.icon(
            onPressed: onRight,
            style: rightIsSecondary
                ? FilledButton.styleFrom(
                    backgroundColor: cs.secondary,
                    foregroundColor: cs.onSecondary,
                  )
                : null,
            icon: Icon(rightIcon, size: 20),
            label: Text(rightLabel, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Desktop layout
// ---------------------------------------------------------------------------

class _DesktopShell extends StatelessWidget {
  const _DesktopShell({
    required this.destinations,
    required this.location,
    required this.child,
    this.appBar,
    this.floatingActionButton,
    this.actionBar,
  });

  final List<_NavDest> destinations;
  final String location;
  final Widget child;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final Widget? actionBar;

  @override
  Widget build(BuildContext context) {
    // Most specific match wins (e.g. /sales → "Sales history", not Transactions).
    var selectedIndex = destinations.indexWhere(
      (d) => location.startsWith(d.path),
    );
    if (selectedIndex < 0) {
      selectedIndex = destinations.indexWhere((d) => d.matches(location));
    }

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: appBar,
        floatingActionButton: floatingActionButton,
        body: Column(
          children: [
            _PastDueBanner(),
            Expanded(
              child: Row(
                children: [
                  BlocSelector<
                    SyncBloc,
                    SyncBlocState,
                    ({int pending, int failed})
                  >(
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
                        leading: _RailHeader(),
                        destinations: destinations.map((d) {
                          Widget icon = Icon(d.icon);
                          Widget selectedIcon = Icon(d.selectedIcon);
                          if (d.path == '/sync' &&
                              (sync.pending > 0 || sync.failed > 0)) {
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
                            label: Text(d.label(context)),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const VerticalDivider(thickness: 1, width: 1),
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(child: child),
                        if (actionBar != null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 560),
                              child: actionBar,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RailHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthBloc>().state.user;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          InitialsAvatar(user?.fullName ?? 'U', radius: 20),
          const SizedBox(height: 4),
          Text(
            user?.firstName ?? '',
            style: Theme.of(context).textTheme.labelSmall,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mobile drawer: the routes that are not bottom tabs
// ---------------------------------------------------------------------------

class _ShellDrawer extends StatelessWidget {
  const _ShellDrawer({required this.destinations});

  final List<_NavDest> destinations;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthBloc>().state.user;
    final theme = Theme.of(context);

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  InitialsAvatar(user?.fullName ?? 'U'),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName ?? 'Unknown user',
                          style: theme.textTheme.titleMedium,
                        ),
                        Text(
                          user?.email ?? '',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(8),
                children: destinations.map((d) => _item(context, d)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(BuildContext context, _NavDest d) {
    void go() {
      Navigator.of(context).pop();
      context.go(d.path);
    }

    if (d.path == '/sync') {
      return BlocSelector<SyncBloc, SyncBlocState, ({int pending, int failed})>(
        selector: (s) =>
            (pending: s.status.pendingCount, failed: s.status.failedCount),
        builder: (context, sync) {
          final colors = Theme.of(context).colorScheme;
          final hasActivity = sync.pending > 0 || sync.failed > 0;
          final badgeColor = sync.failed > 0 ? colors.error : colors.secondary;
          final label = sync.failed > 0 ? '${sync.failed}' : '${sync.pending}';
          return ListTile(
            leading: hasActivity
                ? Badge(
                    backgroundColor: badgeColor,
                    label: Text(label),
                    child: Icon(d.icon),
                  )
                : Icon(d.icon),
            title: Text(d.label(context)),
            onTap: go,
          );
        },
      );
    }
    return ListTile(
      leading: Icon(d.icon),
      title: Text(d.label(context)),
      onTap: go,
    );
  }
}
