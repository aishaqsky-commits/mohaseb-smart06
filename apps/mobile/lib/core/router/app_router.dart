import 'package:go_router/go_router.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/contacts/presentation/screens/contacts_hub_screen.dart';
import '../../features/inventory/presentation/screens/inventory_list_screen.dart';
import '../../features/inventory/presentation/screens/inventory_check_screen.dart';
import '../../features/subscriptions/presentation/screens/checkout_screen.dart';
// import '../../features/journal/presentation/screens/journal_entry_screen.dart';

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
      path: '/checkout',
      builder: (context, state) {
        final Map<String, dynamic> args = state.extra as Map<String, dynamic>? ?? {};
        return CheckoutScreen(
          planCode: args['planCode'] ?? 'pro',
          planPrice: args['planPrice'] ?? 15000.0,
        );
      },
    ),
  ],
);
