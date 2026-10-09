import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const PlaceholderDashboard(),
    ),
  ],
);

class PlaceholderDashboard extends StatelessWidget {
  const PlaceholderDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المحاسب الذكي - الرئيسية')),
      body: Center(
        child: Text(
          'أهلاً بك في منصة المحاسب الذكي',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}
