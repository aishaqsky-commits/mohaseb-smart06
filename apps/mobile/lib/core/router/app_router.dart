import 'package:go_router/go_router.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/contacts/presentation/screens/contacts_hub_screen.dart';
import '../../features/inventory/presentation/screens/inventory_list_screen.dart';
import '../../features/inventory/presentation/screens/inventory_check_screen.dart';
import '../../features/subscriptions/presentation/screens/checkout_screen.dart';
import '../../features/reports/presentation/screens/reports_dashboard_screen.dart';
import '../../features/reports/presentation/screens/income_statement_screen.dart';
import '../../features/pos/presentation/screens/pos_screen.dart';
import '../../features/inventory/presentation/screens/warehouse_list_screen.dart';
import '../../features/inventory/presentation/screens/warehouse_transfer_screen.dart';
import '../../features/checks/presentation/screens/checks_list_screen.dart';
import '../../features/checks/presentation/screens/check_details_screen.dart';
import '../../features/currencies/presentation/screens/currencies_list_screen.dart';
import '../../features/api_integration/presentation/screens/api_keys_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/operations/presentation/screens/operations_hub_screen.dart';
import '../../features/operations/presentation/screens/operation_form_screen.dart';
import '../../features/operations/presentation/screens/operation_summary_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/contacts',
      builder: (context, state) => const ContactsHubScreen(),
    ),
    GoRoute(
      path: '/inventory',
      builder: (context, state) => const InventoryListScreen(),
    ),
    GoRoute(
      path: '/inventory-check',
      builder: (context, state) => const InventoryCheckScreen(),
    ),
    GoRoute(
      path: '/inventory/warehouses',
      builder: (context, state) => const WarehouseListScreen(),
    ),
    GoRoute(
      path: '/inventory/transfer',
      builder: (context, state) {
        final Map<String, dynamic> args = state.extra as Map<String, dynamic>? ?? {};
        return WarehouseTransferScreen(initialFromWarehouseId: args['from_warehouse_id']);
      },
    ),
    GoRoute(
      path: '/pos',
      builder: (context, state) => const POSScreen(),
    ),
    GoRoute(
      path: '/checks',
      builder: (context, state) => const ChecksListScreen(),
    ),
    GoRoute(
      path: '/checks/details',
      builder: (context, state) {
        final Map<String, dynamic> args = state.extra as Map<String, dynamic>;
        return CheckDetailsScreen(checkData: args);
      },
    ),
    GoRoute(
      path: '/currencies',
      builder: (context, state) => const CurrenciesListScreen(),
    ),
    GoRoute(
      path: '/api-keys',
      builder: (context, state) => const ApiKeysScreen(),
    ),
    GoRoute(
      path: '/reports',
      builder: (context, state) => const ReportsDashboardScreen(),
    ),
    GoRoute(
      path: '/reports/income-statement',
      builder: (context, state) => const IncomeStatementScreen(),
    ),
    GoRoute(
      path: '/checkout',
      builder: (context, state) {
        final Map<String, dynamic> args = state.extra as Map<String, dynamic>? ?? {};
        return CheckoutScreen(
          planCode: args['planCode'] ?? 'pro',
          planPrice: args['planPrice'] ?? 15000.0,
        );
      },
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/operations',
      builder: (context, state) => const OperationsHubScreen(),
    ),
    GoRoute(
      path: '/operations/form',
      builder: (context, state) {
        final Map<String, dynamic> args = state.extra as Map<String, dynamic>? ?? {};
        return OperationFormScreen(
          templateCode: args['templateCode'] ?? 'sale_cash',
        );
      },
    ),
    GoRoute(
      path: '/operations/summary',
      builder: (context, state) {
        final Map<String, dynamic> args = state.extra as Map<String, dynamic>? ?? {};
        return OperationSummaryScreen(summaryData: args);
      },
    ),
  ],
);
