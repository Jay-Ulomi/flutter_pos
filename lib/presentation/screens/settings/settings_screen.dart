import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/branch/branch_bloc.dart';
import '../../blocs/session/session_bloc.dart';
import '../../blocs/session/session_state.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/brand_colors.dart';
import '../../widgets/responsive_shell.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthBloc>().state;
    final branch = context.watch<BranchBloc>().state.selected;
    final session = context.watch<SessionBloc>().state;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return ResponsiveShell(
      appBar: AppBar(title: const Text('Settings')),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── User ──
              _sectionLabel(context, 'User'),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: colors.primaryContainer,
                        child: Text(
                          auth.user?.firstName.isNotEmpty == true
                              ? auth.user!.firstName[0].toUpperCase()
                              : 'U',
                          style: TextStyle(
                            color: colors.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      title: Text(
                        auth.user?.fullName ?? 'Unknown',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(auth.user?.email ?? ''),
                    ),
                    Divider(height: 1, color: colors.outlineVariant),
                    ListTile(
                      leading: const Icon(Icons.badge_outlined),
                      title: Text(auth.user?.role ?? '\u2014'),
                      subtitle: const Text('Role'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Business & Branch ──
              _sectionLabel(context, 'Business & Branch'),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.business_outlined),
                      title: const Text('Switch Business'),
                      subtitle: const Text('Change active business'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.go('/select-business'),
                    ),
                    Divider(height: 1, color: colors.outlineVariant),
                    ListTile(
                      leading: const Icon(Icons.store_mall_directory_outlined),
                      title: Text(
                        branch?.name ?? auth.branchId ?? 'Not selected',
                      ),
                      subtitle: branch?.address != null
                          ? Text(branch!.address!)
                          : null,
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.go('/select-branch'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Session ──
              _sectionLabel(context, 'Session'),
              Card(
                child: ListTile(
                  leading: Icon(
                    session.status == SessionStatus.open
                        ? Icons.lock_open
                        : Icons.lock_outline,
                    color: session.status == SessionStatus.open
                        ? colors.primary
                        : colors.onSurfaceVariant,
                  ),
                  title: Text(
                    session.status == SessionStatus.open
                        ? 'Session is open'
                        : 'No open session',
                  ),
                  subtitle: session.current != null
                      ? Text('Opened: ${session.current!.openedAt}')
                      : null,
                  trailing: session.status == SessionStatus.open
                      ? FilledButton.tonal(
                          onPressed: () => context.go('/session/close'),
                          child: const Text('Close'),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 16),

              // ── Appearance ──
              _sectionLabel(context, 'Appearance'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.light_mode),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Theme', style: theme.textTheme.bodyLarge),
                            Text(
                              'Light — dark mode coming soon',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Subscription / Trial ──
              if (auth.isOnTrial || auth.isTrialExpired) ...[
                _sectionLabel(context, 'Subscription'),
                _TrialCard(auth: auth),
                const SizedBox(height: 16),
              ],

              // ── Account ──
              _sectionLabel(context, 'Account'),
              Card(
                child: ListTile(
                  leading: Icon(Icons.logout, color: colors.error),
                  title: Text('Logout', style: TextStyle(color: colors.error)),
                  onTap: () {
                    context.read<AuthBloc>().add(const AuthLogoutRequested());
                  },
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _TrialCard extends StatelessWidget {
  final dynamic auth; // AuthState
  const _TrialCard({required this.auth});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final days = auth.trialDaysRemaining as int?;
    final isExpired = auth.isTrialExpired as bool;

    Color bannerColor;
    Color textColor;
    IconData icon;
    String statusText;

    if (isExpired) {
      bannerColor = colors.errorContainer;
      textColor = colors.error;
      icon = Icons.hourglass_bottom_outlined;
      statusText = 'Trial ended — upgrade to continue';
    } else if (days != null && days <= 3) {
      bannerColor = BrandColors.secondary.withValues(alpha: 0.12);
      textColor = BrandColors.secondary;
      icon = Icons.warning_amber_outlined;
      statusText = days == 0 ? 'Trial ends today!' : 'Trial ends in $days day${days == 1 ? '' : 's'}';
    } else if (days != null) {
      bannerColor = BrandColors.primaryContainer;
      textColor = BrandColors.primary;
      icon = Icons.timer_outlined;
      statusText = '$days days remaining in trial';
    } else {
      bannerColor = BrandColors.primaryContainer;
      textColor = BrandColors.primary;
      icon = Icons.check_circle_outline;
      statusText = auth.subscriptionStatus ?? 'Active';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: bannerColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: textColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusText,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  if (auth.trialEndsAt != null)
                    Text(
                      isExpired
                          ? 'Expired on ${_fmt(auth.trialEndsAt!)}'
                          : 'Expires on ${_fmt(auth.trialEndsAt!)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            if (isExpired || (days != null && days <= 7))
              TextButton(
                onPressed: () => _showUpgradeDialog(context),
                style: TextButton.styleFrom(
                  foregroundColor: BrandColors.secondary,
                  padding: EdgeInsets.zero,
                ),
                child: const Text('Upgrade'),
              ),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime dt) {
    const m = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${m[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  void _showUpgradeDialog(BuildContext context) {
    final url = '${ApiConstants.businessAdminUrl}/billing';
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final colors = theme.colorScheme;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Manage Subscription'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Visit the billing portal to upgrade or renew your plan:',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.outlineVariant),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        url,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: BrandColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: url));
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Link copied to clipboard'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 18),
                      tooltip: 'Copy link',
                      color: BrandColors.primary,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
