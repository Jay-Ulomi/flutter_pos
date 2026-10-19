import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../blocs/app_settings/app_settings_cubit.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/business/business_bloc.dart';
import '../../widgets/aduinola/ui.dart';
import '../../widgets/responsive_shell.dart';

/// Profile tab: who is signed in, and the menu for everything else.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthBloc>().state;
    final user = auth.user;
    final business = context.watch<BusinessBloc>().state.selected;
    final privacy = context.select<AppSettingsCubit, bool>((c) => c.state.privacyMode);

    Widget item(IconData icon, String label, VoidCallback onTap, {Key? key}) => SoftCard(
          key: key,
          padding: EdgeInsets.zero,
          onTap: onTap,
          child: ListTile(
            leading: Icon(icon),
            title: Text(label),
            trailing: const Icon(Icons.chevron_right_rounded),
          ),
        );

    return ResponsiveShell(
      appBar: AppBar(title: Text(context.tr('profile.title'))),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
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
                      if (business != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: StatusPill(business.name, tone: PillTone.paid),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (auth.can('view_reports')) ...[
            item(Icons.bar_chart_rounded, context.tr('profile.reports'), () => context.push('/reports'),
                key: const ValueKey('menu-reports')),
            const SizedBox(height: 8),
          ],
          item(Icons.point_of_sale_outlined, context.tr('profile.shift'), () => context.push('/session/close')),
          const SizedBox(height: 8),
          item(Icons.sync_rounded, context.tr('profile.sync'), () => context.go('/sync')),
          const SizedBox(height: 8),
          item(Icons.storefront_outlined, context.tr('profile.business_settings'), () => context.go('/settings')),
          const SizedBox(height: 8),
          item(Icons.tune_rounded, context.tr('profile.app_settings'), () => context.push('/app-settings'),
              key: const ValueKey('menu-app-settings')),
          const SizedBox(height: 8),
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
          const SizedBox(height: 24),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: theme.colorScheme.error),
            onPressed: () => context.read<AuthBloc>().add(const AuthLogoutRequested()),
            icon: const Icon(Icons.logout_rounded),
            label: Text(context.tr('profile.sign_out')),
          ),
        ],
      ),
    );
  }
}
