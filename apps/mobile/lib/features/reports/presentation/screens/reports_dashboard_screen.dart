import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/color_tokens.dart';
import 'package:go_router/go_router.dart';

class ReportsDashboardScreen extends StatelessWidget {
  const ReportsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('التقارير المالية والذمم'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _buildReportSection(
            context,
            'التقارير المالية الأساسية',
            [
              _ReportItem(title: 'قائمة الدخل (الأرباح والخسائر)', icon: Icons.trending_up, route: '/reports/income-statement'),
              _ReportItem(title: 'ميزان المراجعة', icon: Icons.account_balance, route: '/reports/trial-balance'),
              _ReportItem(title: 'الميزانية العمومية', icon: Icons.pie_chart, route: '/reports/balance-sheet'),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          _buildReportSection(
            context,
            'تقارير الذمم (AR/AP)',
            [
              _ReportItem(title: 'أرصدة العملاء والموردين', icon: Icons.people, route: '/reports/contact-balances'),
              _ReportItem(title: 'أعمار الديون (Aging)', icon: Icons.access_time, route: '/reports/aging'),
              _ReportItem(title: 'كشف حساب تفصيلي', icon: Icons.receipt_long, route: '/reports/statement'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReportSection(BuildContext context, String title, List<_ReportItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: ColorTokens.neutralInfo,
              ),
        ),
        const SizedBox(height: AppSpacing.md),
        ...items.map((item) => Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: ListTile(
                leading: Icon(item.icon, color: ColorTokens.neutralInfo),
                title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.chevron_left),
                onTap: () {
                  if (item.route == '/reports/income-statement') {
                    context.push(item.route);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('شاشة ${item.title} تحت التطوير')),
                    );
                  }
                },
              ),
            )),
      ],
    );
  }
}

class _ReportItem {
  final String title;
  final IconData icon;
  final String route;

  _ReportItem({required this.title, required this.icon, required this.route});
}
