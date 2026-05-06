import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/token_manager.dart';
import '../../../di/injection.dart';
import '../../blocs/sync/sync_bloc.dart';
import '../../blocs/sync/sync_event.dart';
import '../../blocs/sync/sync_state.dart';
import '../../widgets/responsive_shell.dart';

class SyncStatusScreen extends StatefulWidget {
  const SyncStatusScreen({super.key});

  @override
  State<SyncStatusScreen> createState() => _SyncStatusScreenState();
}

class _SyncStatusScreenState extends State<SyncStatusScreen> {
  String? _branchId;

  @override
  void initState() {
    super.initState();
    context.read<SyncBloc>().add(const SyncStatusRequested());
    sl<TokenManager>().getBranchId().then((v) {
      if (mounted) setState(() => _branchId = v);
    });
  }

  Future<void> _confirmFullSync(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Full sync?'),
        content: const Text(
          'This replaces all local cached products, categories, and '
          'customers with a fresh copy from the server. Pending queued '
          'actions (sales/laundry) are not affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Full sync'),
          ),
        ],
      ),
    );
    if (confirmed == true && _branchId != null && mounted) {
      if (!context.mounted) return;
      context.read<SyncBloc>().add(SyncBootstrapRequested(_branchId!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return ResponsiveShell(
      appBar: AppBar(title: const Text('Sync')),
      child: BlocConsumer<SyncBloc, SyncBlocState>(
        listener: (context, state) {
          if (state.phase == SyncPhase.error && state.errorMessage != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
          }
        },
        builder: (context, state) {
          final syncing = state.phase == SyncPhase.syncing;
          final hasBranch = _branchId != null;
          final isOnline = state.status.isOnline;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Connection status ──
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: (isOnline ? colors.primary : colors.error)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: (isOnline ? colors.primary : colors.error)
                            .withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isOnline
                                ? colors.primaryContainer
                                : colors.errorContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isOnline ? Icons.cloud_done : Icons.cloud_off,
                            color: isOnline
                                ? colors.onPrimaryContainer
                                : colors.onErrorContainer,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isOnline ? 'Online' : 'Offline',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (state.status.lastSyncTime != null)
                                Text(
                                  'Last sync: ${Formatters.dateTime(state.status.lastSyncTime!)}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                                )
                              else
                                Text(
                                  'Never synced',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (syncing)
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Sales queue stats ──
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sales Queue',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _statTile(
                                context,
                                state.status.pendingSalesCount,
                                'Pending',
                                colors.secondary,
                              ),
                              _statTile(
                                context,
                                state.status.failedSalesCount,
                                'Failed',
                                colors.error,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Laundry queue stats ──
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Laundry Queue',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _statTile(
                                context,
                                state.status.pendingLaundryCount,
                                'Pending',
                                colors.secondary,
                              ),
                              _statTile(
                                context,
                                state.status.failedLaundryCount,
                                'Failed',
                                colors.error,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Combined queue stats ──
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Combined Queue',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _statTile(
                                context,
                                state.status.pendingCount,
                                'Pending',
                                colors.secondary,
                              ),
                              _statTile(
                                context,
                                state.status.syncingCount,
                                'Syncing',
                                colors.primary,
                              ),
                              _statTile(
                                context,
                                state.status.failedCount,
                                'Failed',
                                colors.error,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Last push result ──
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Last Push Result',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _statTile(
                                context,
                                state.status.lastAcceptedCount,
                                'Accepted',
                                colors.primary,
                              ),
                              _statTile(
                                context,
                                state.status.lastRejectedCount,
                                'Rejected',
                                colors.error,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Actions ──
                  Row(
                    children: [
                      Expanded(
                        child: _actionButton(
                          icon: Icons.cloud_download,
                          label: 'Full Sync',
                          onPressed: (syncing || !hasBranch)
                              ? null
                              : () => _confirmFullSync(context),
                          filled: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _actionButton(
                          icon: Icons.sync,
                          label: 'Sync Changes',
                          onPressed: (syncing || !hasBranch)
                              ? null
                              : () => context.read<SyncBloc>().add(
                                  SyncDeltaRequested(_branchId!),
                                ),
                          filled: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _actionButton(
                          icon: Icons.upload,
                          label: 'Push Queue',
                          onPressed: syncing
                              ? null
                              : () => context.read<SyncBloc>().add(
                                  const SyncPushRequested(),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _actionButton(
                          icon: Icons.flash_on,
                          label: 'Quick Sync',
                          onPressed: syncing
                              ? null
                              : () => context.read<SyncBloc>().add(
                                  const SyncTriggered(),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _statTile(BuildContext context, int value, String label, Color color) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Text(
            '$value',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: value > 0 ? color : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    bool filled = false,
  }) {
    if (filled) {
      return SizedBox(
        height: 48,
        child: FilledButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 20),
          label: Text(label),
        ),
      );
    }
    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label),
      ),
    );
  }
}
