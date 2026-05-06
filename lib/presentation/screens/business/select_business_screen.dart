import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/business/business_bloc.dart';
import '../../blocs/business/business_event.dart';
import '../../blocs/business/business_state.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_indicator.dart';

class SelectBusinessScreen extends StatefulWidget {
  const SelectBusinessScreen({super.key});

  @override
  State<SelectBusinessScreen> createState() => _SelectBusinessScreenState();
}

class _SelectBusinessScreenState extends State<SelectBusinessScreen> {
  @override
  void initState() {
    super.initState();
    context.read<BusinessBloc>().add(const BusinessLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Business'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthBloc>().add(const AuthLogoutRequested());
            },
          ),
        ],
      ),
      body: BlocBuilder<BusinessBloc, BusinessState>(
        builder: (context, state) {
          if (state.status == BusinessStatus.loading) {
            return const LoadingIndicator(message: 'Loading businesses...');
          }
          if (state.status == BusinessStatus.error) {
            return ErrorView(
              message: state.errorMessage ?? 'Failed to load businesses',
              onRetry: () => context.read<BusinessBloc>().add(
                const BusinessLoadRequested(),
              ),
            );
          }
          if (state.businesses.isEmpty) {
            return const EmptyState(
              title: 'No businesses found',
              subtitle: 'Contact your administrator to get access.',
              icon: Icons.business_outlined,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: state.businesses.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final b = state.businesses[i];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      b.name.isNotEmpty ? b.name[0].toUpperCase() : '?',
                    ),
                  ),
                  title: Text(b.name),
                  subtitle: b.address != null ? Text(b.address!) : null,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    context.read<BusinessBloc>().add(BusinessSelected(b.id));
                    context.read<AuthBloc>().add(
                      AuthSelectBusiness(
                        businessId: b.id,
                        businessType: b.type,
                      ),
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
