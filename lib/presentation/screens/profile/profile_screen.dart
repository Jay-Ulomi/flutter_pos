import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/brand_colors.dart';
import '../../blocs/app_settings/app_settings_cubit.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/branch/branch_bloc.dart';
import '../../blocs/business/business_bloc.dart';
import '../../widgets/aduinola/ui.dart';
import '../../widgets/aduinola/app_page.dart';
import '../settings/billing_upgrade_dialog.dart';

/// "tenant_owner" -> "Tenant owner".
String _humanizeRole(String role) {
  final words = role.split('_').where((w) => w.isNotEmpty);
  return words.map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
}

/// Profile tab: who is signed in, business/branch, subscription, and the
/// menu for everything else. Business settings used to be its own screen;
/// its content (user info, business/branch, subscription) duplicated what's
/// already here or on App Settings (theme), so it was folded in instead.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthBloc>().state;
    final user = auth.user;
    final business = context.watch<BusinessBloc>().state.selected;
    final branch = context.watch<BranchBloc>().state.selected;
    final privacy = context.select<AppSettingsCubit, bool>((c) => c.state.privacyMode);

    Widget item(IconData icon, String label, VoidCallback onTap, {Key? key, Widget? trailingValue}) => SoftCard(
          key: key,
          padding: EdgeInsets.zero,
          onTap: onTap,
          child: ListTile(
            leading: Icon(icon),
            title: Text(label),
            trailing: trailingValue == null
                ? const Icon(Icons.chevron_right_rounded)
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [trailingValue, const Icon(Icons.chevron_right_rounded)],
                  ),
          ),
        );

    final menu = <Widget>[
      if (auth.can('view_reports'))
        item(Icons.bar_chart_rounded, context.tr('profile.reports'), () => context.push('/reports'),
            key: const ValueKey('menu-reports')),
      item(Icons.point_of_sale_outlined, context.tr('profile.shift'), () => context.push('/session/close')),
      item(Icons.sync_rounded, context.tr('profile.sync'), () => context.go('/sync')),
      item(
        Icons.business_outlined,
        'Switch business',
        () => context.go('/select-business'),
        trailingValue: Text(business?.name ?? '—', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
      ),
      item(
        Icons.store_mall_directory_outlined,
        'Switch branch',
        () => context.go('/select-branch'),
        trailingValue: Text(branch?.name ?? '—', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
      ),
      item(Icons.tune_rounded, context.tr('profile.app_settings'), () => context.push('/app-settings'),
          key: const ValueKey('menu-app-settings')),
      SoftCard(
        padding: EdgeInsets.zero,
        child: SwitchListTile(
          secondary: Icon(privacy ? Icons.visibility_off_outlined : Icons.visibility_outlined),
          title: Text(context.tr('settings.privacy_mode')),
          subtitle: Text(context.tr('settings.privacy_mode_sub')),
          value: privacy,
          onChanged: (_) => context.read<AppSettingsCubit>().togglePrivacy(),
        ),
      ),
    ];

    return AppPage(
      title: context.tr('profile.title'),
      padBody: false,
      body: ListView(
        padding: AppPage.insets(context, top: 4),
        children: [
          SoftCard(
            child: Row(
              children: [
                InitialsAvatar(user?.fullName ?? '?', radius: 30),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.fullName ?? '', style: theme.textTheme.titleLarge),
                      if (user?.email != null) Text(user!.email, style: theme.textTheme.bodySmall),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (business != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: StatusPill(business.name, tone: PillTone.paid),
                            ),
                          if (user?.role != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: StatusPill(_humanizeRole(user!.role), tone: PillTone.neutral),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: theme.colorScheme.error),
                  onPressed: () => context.read<AuthBloc>().add(const AuthLogoutRequested()),
                  icon: const Icon(Icons.logout_rounded),
                  label: Text(context.tr('profile.sign_out')),
                ),
              ],
            ),
          ),
          if (auth.isOnTrial || auth.isTrialExpired || auth.isPastDue) ...[
            const SizedBox(height: 12),
            _SubscriptionCard(auth: auth),
          ],
          const SizedBox(height: 16),
          // Menu: one column on phones, two from 900, three from 1280.
          LayoutBuilder(builder: (context, c) {
            final cols = responsiveColumns(c.maxWidth);
            final w = (c.maxWidth - 12 * (cols - 1)) / cols;
            return Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [for (final m in menu) SizedBox(width: w, child: m)],
            );
          }),
        ],
      ),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  final AuthState auth;
  const _SubscriptionCard({required this.auth});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final days = auth.trialDaysRemaining;
    final isExpired = auth.isTrialExpired;
    final isPastDue = auth.isPastDue;
    final graceDays = auth.gracePeriodDaysRemaining;

    Color bannerColor;
    Color textColor;
    IconData icon;
    String statusText;

    if (isExpired) {
      bannerColor = colors.errorContainer;
      textColor = colors.error;
      icon = Icons.hourglass_bottom_outlined;
      statusText = 'Trial ended — upgrade to continue';
    } else if (isPastDue) {
      bannerColor = BrandColors.secondary.withValues(alpha: 0.12);
      textColor = BrandColors.secondary;
      icon = Icons.warning_amber_outlined;
      statusText = graceDays != null
          ? 'Subscription past due — $graceDays day${graceDays == 1 ? '' : 's'} left'
          : 'Subscription past due';
    } else if (days != null && days <= 3) {
      bannerColor = BrandColors.secondary.withValues(alpha: 0.12);
      textColor = BrandColors.secondary;
      icon = Icons.warning_amber_outlined;
      statusText = days == 0 ? 'Trial ends today!' : 'Trial ends in $days day${days == 1 ? '' : 's'}';
    } else {
      bannerColor = BrandColors.primaryContainer;
      textColor = BrandColors.primary;
      icon = Icons.timer_outlined;
      statusText = '$days days remaining in trial';
    }

    return SoftCard(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: bannerColor, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: textColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: textColor),
                ),
                if (auth.isOnTrial && auth.trialEndsAt != null)
                  Text(
                    isExpired ? 'Expired on ${_fmt(auth.trialEndsAt!)}' : 'Expires on ${_fmt(auth.trialEndsAt!)}',
                    style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                  )
                else if (isPastDue && auth.gracePeriodEndsAt != null)
                  Text(
                    'Grace period ends ${_fmt(auth.gracePeriodEndsAt!)}',
                    style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                  ),
              ],
            ),
          ),
          if (isExpired || isPastDue || (days != null && days <= 7))
            TextButton(
              onPressed: () => showBillingUpgradeDialog(context),
              style: TextButton.styleFrom(foregroundColor: BrandColors.secondary, padding: EdgeInsets.zero),
              child: const Text('Upgrade'),
            ),
        ],
      ),
    );
  }

  String _fmt(DateTime dt) {
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${m[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}
