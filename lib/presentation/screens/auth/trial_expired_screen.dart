import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/theme/brand_colors.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';

class TrialExpiredScreen extends StatelessWidget {
  const TrialExpiredScreen({super.key});

  static String get _upgradeUrl => '${ApiConstants.businessAdminUrl}/billing';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final auth = context.watch<AuthBloc>().state;

    final isExpiredByDate =
        auth.trialEndsAt != null &&
        DateTime.now().isAfter(auth.trialEndsAt!);
    final isSuspended = auth.subscriptionStatus == 'suspended';

    final title = isSuspended ? 'Account Suspended' : 'Trial Ended';
    final subtitle = isSuspended
        ? 'Your account has been suspended. Please contact support or upgrade your plan to restore access.'
        : 'Your 14-day free trial has ended. Upgrade to a paid plan to continue using the POS.';

    return Scaffold(
      backgroundColor: BrandColors.backgroundLight,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: colors.errorContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSuspended
                        ? Icons.block_outlined
                        : Icons.hourglass_bottom_outlined,
                    size: 40,
                    color: colors.error,
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                if (isExpiredByDate && auth.trialEndsAt != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: colors.errorContainer.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: colors.error.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 14,
                          color: colors.error,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Trial ended on ${_formatDate(auth.trialEndsAt!)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // Upgrade URL card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: BrandColors.primaryLight.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: BrandColors.primaryLight.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Visit to upgrade your plan:',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              _upgradeUrl,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: BrandColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: _upgradeUrl),
                              );
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
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Logout
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      context.read<AuthBloc>().add(const AuthLogoutRequested());
                    },
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('Sign out'),
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'Need help? Contact support@yourpos.com',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}
