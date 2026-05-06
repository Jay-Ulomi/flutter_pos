import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/sale_models.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/business/business_bloc.dart';
import '../blocs/sale/sale_bloc.dart';
import '../blocs/auth/auth_state.dart';
import '../blocs/session/session_bloc.dart';
import '../blocs/session/session_state.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/trial_expired_screen.dart';
import '../screens/business/select_branch_screen.dart';
import '../screens/business/select_business_screen.dart';
import '../screens/customers/customer_detail_screen.dart';
import '../screens/customers/customer_groups_screen.dart';
import '../screens/customers/customer_search_screen.dart';
import '../screens/laundry/laundry_receipt_screen.dart';
import '../screens/pos/checkout_screen.dart';
import '../screens/pos/pos_screen.dart';
import '../screens/pos/receipt_screen.dart';
import '../screens/products/product_list_screen.dart';
import '../screens/sales/return_screen.dart';
import '../screens/sales/sale_detail_screen.dart';
import '../screens/sales/sales_history_screen.dart';
import '../screens/session/close_session_screen.dart';
import '../screens/session/open_session_screen.dart';
import '../screens/session/shift_report_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/sync/sync_status_screen.dart';
import '../widgets/error_view.dart';
import '../widgets/responsive_shell.dart';
import '../../data/models/laundry_models.dart';

class AppRouter {
  AppRouter._();

  static GoRouter build({
    required AuthBloc authBloc,
    required BusinessBloc businessBloc,
    required SessionBloc sessionBloc,
  }) {
    return GoRouter(
      initialLocation: '/login',
      refreshListenable: _BlocRefresh([
        authBloc.stream,
        businessBloc.stream,
        sessionBloc.stream,
      ]),
      errorBuilder: (context, state) {
        final auth = authBloc.state;
        final isAuthed = auth.status == AuthStatus.authenticated;
        final fallbackPath = isAuthed ? '/pos' : '/login';
        return Scaffold(
          appBar: AppBar(title: const Text('Page Not Found')),
          body: ErrorView(
            icon: Icons.search_off,
            message:
                'The page "${state.uri}" was not found.\nPlease use the app menu to continue.',
            onRetry: () => context.go(fallbackPath),
          ),
        );
      },
      redirect: (context, goState) {
        final auth = authBloc.state;
        final session = sessionBloc.state;
        final loc = goState.matchedLocation;

        // Allow unknown → let app bootstrap
        if (auth.status == AuthStatus.unknown ||
            auth.status == AuthStatus.loading) {
          return null;
        }

        final atLogin = loc == '/login';
        final atBiz = loc == '/select-business';
        final atBranch = loc == '/select-branch';
        final atSessionOpen = loc == '/session/open';
        final atSessionReport = loc == '/session/report';

        if (auth.status == AuthStatus.unauthenticated) {
          return atLogin ? null : '/login';
        }

        if (auth.status == AuthStatus.businessRequired ||
            auth.businessId == null) {
          return atBiz ? null : '/select-business';
        }

        if (auth.status == AuthStatus.branchRequired || auth.branchId == null) {
          return atBranch ? null : '/select-branch';
        }

        // Trial / subscription expired — block before session check
        final atTrialExpired = loc == '/trial-expired';
        if (auth.isTrialExpired) {
          return atTrialExpired ? null : '/trial-expired';
        }
        // Don't allow accessing the expired screen when not expired
        if (atTrialExpired) return '/pos';

        // Authenticated: check session
        if (session.status != SessionStatus.open) {
          // Allow viewing Z-report for closed shifts.
          if (atSessionReport) return null;
          return atSessionOpen ? null : '/session/open';
        }

        // If on an auth/setup screen but fully logged in → go to POS
        if (atLogin || atBiz || atBranch || atSessionOpen) {
          return '/pos';
        }
        return null;
      },
      routes: [
        GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
        GoRoute(
          path: '/trial-expired',
          builder: (_, _) => const TrialExpiredScreen(),
        ),
        GoRoute(
          path: '/select-business',
          builder: (_, _) => const SelectBusinessScreen(),
        ),
        GoRoute(
          path: '/select-branch',
          builder: (_, _) => const SelectBranchScreen(),
        ),
        GoRoute(
          path: '/session/open',
          builder: (_, _) => const OpenSessionScreen(),
        ),
        GoRoute(
          path: '/session/close',
          builder: (_, _) => const CloseSessionScreen(),
        ),
        GoRoute(
          path: '/session/report',
          builder: (_, s) {
            final sessionId = s.uri.queryParameters['sessionId'];
            return ShiftReportScreen(sessionId: sessionId);
          },
        ),
        GoRoute(path: '/pos', builder: (_, _) => const PosScreen()),
        GoRoute(path: '/checkout', builder: (_, _) => const CheckoutScreen()),
        GoRoute(path: '/receipt', builder: (_, _) => const ReceiptScreen()),
        GoRoute(
          path: '/laundry/receipt',
          builder: (_, s) {
            final order = s.extra;
            if (order is! LaundryOrder) {
              return ResponsiveShell(
                appBar: AppBar(title: const Text('Laundry Receipt')),
                child: const ErrorView(
                  icon: Icons.receipt_long_outlined,
                  message: 'No laundry receipt found. Create a new ticket.',
                ),
              );
            }
            return LaundryReceiptScreen(order: order);
          },
        ),
        GoRoute(
          path: '/products',
          builder: (_, _) => const ProductListScreen(),
        ),
        GoRoute(path: '/sales', builder: (_, _) => const SalesHistoryScreen()),
        GoRoute(
          path: '/sales/detail',
          builder: (c, s) {
            final saleId = s.uri.queryParameters['saleId'];
            return SaleDetailScreen(saleId: saleId);
          },
        ),
        GoRoute(
          path: '/sales/return',
          builder: (context, s) {
            final saleId = s.uri.queryParameters['saleId'];
            final saleState = context.read<SaleBloc>().state;
            Sale? sale;
            for (final r in saleState.recent) {
              if (r.id == saleId || r.saleNumber == saleId) {
                sale = r;
                break;
              }
            }
            sale ??= saleState.lastSale;
            if (sale == null) {
              return ResponsiveShell(
                appBar: AppBar(title: const Text('Return Sale')),
                child: ErrorView(
                  icon: Icons.receipt_long_outlined,
                  message:
                      'Sale not found. Please open the sale from Sales History.',
                  onRetry: () => context.go('/sales'),
                ),
              );
            }
            return ReturnScreen(sale: sale);
          },
        ),
        GoRoute(path: '/sync', builder: (_, _) => const SyncStatusScreen()),
        GoRoute(
          path: '/customers',
          builder: (_, _) => const CustomerSearchScreen(),
        ),
        GoRoute(
          path: '/customers/groups',
          builder: (_, _) => const CustomerGroupsScreen(),
        ),
        GoRoute(
          path: '/customers/:id',
          builder: (_, s) => CustomerDetailScreen(customerId: s.pathParameters['id']!),
        ),
        GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
      ],
    );
  }
}

class _BlocRefresh extends ChangeNotifier {
  _BlocRefresh(List<Stream<dynamic>> streams) {
    for (final s in streams) {
      _subs.add(s.listen((_) => notifyListeners()));
    }
  }

  final List<dynamic> _subs = [];

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }
}
