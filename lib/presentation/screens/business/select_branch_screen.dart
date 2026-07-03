import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/branch/branch_bloc.dart';
import '../../blocs/branch/branch_event.dart';
import '../../blocs/branch/branch_state.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_indicator.dart';

class SelectBranchScreen extends StatefulWidget {
  const SelectBranchScreen({super.key});

  @override
  State<SelectBranchScreen> createState() => _SelectBranchScreenState();
}

class _SelectBranchScreenState extends State<SelectBranchScreen> {
  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthBloc>().state;
    final bizId = auth.businessId;
    if (bizId != null) {
      context.read<BranchBloc>().add(BranchLoadRequested(bizId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Branch'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () {
              context.read<AuthBloc>().add(const AuthLogoutRequested());
            },
          ),
        ],
      ),
      body: BlocBuilder<BranchBloc, BranchState>(
        builder: (context, state) {
          if (state.status == BranchStatus.loading) {
            return const LoadingIndicator(message: 'Loading branches...');
          }
          if (state.status == BranchStatus.error) {
            return ErrorView(
              message: state.errorMessage ?? 'Failed to load branches',
              onRetry: () {
                final bizId = context.read<AuthBloc>().state.businessId;
                if (bizId != null) {
                  context.read<BranchBloc>().add(BranchLoadRequested(bizId));
                }
              },
            );
          }
          if (state.branches.isEmpty) {
            return const EmptyState(
              title: 'No branches found',
              subtitle: 'Contact your administrator.',
              icon: Icons.store_mall_directory_outlined,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: state.branches.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final b = state.branches[i];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.store_mall_directory_outlined),
                  title: Text(b.name),
                  subtitle: b.address != null ? Text(b.address!) : null,
                  trailing: const Icon(Icons.chevron_right),
                  enabled: b.isActive,
                  onTap: () {
                    context.read<BranchBloc>().add(BranchSelected(b.id));
                    context.read<AuthBloc>().add(
                      AuthSelectBranch(branchId: b.id),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
