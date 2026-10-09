import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/color_tokens.dart';

class IncomeStatementScreen extends StatefulWidget {
  const IncomeStatementScreen({super.key});

  @override
  State<IncomeStatementScreen> createState() => _IncomeStatementScreenState();
}

class _IncomeStatementScreenState extends State<IncomeStatementScreen> {
  // Mock Data mimicking FinancialReportingEngine output
  final double totalRevenue = 150000.0;
  final double totalExpenses = 45000.0;
  
  final List<Map<String, dynamic>> revenues = [
    {'name': 'مبيعات نقدية', 'amount': 100000.0},
    {'name': 'مبيعات آجلة', 'amount': 50000.0},
  ];

  final List<Map<String, dynamic>> expenses = [
    {'name': 'إيجار المحل', 'amount': 20000.0},
    {'name': 'رواتب الموظفين', 'amount': 25000.0},
  ];

  @override
  Widget build(BuildContext context) {
    final double netProfit = totalRevenue - totalExpenses;

    return Scaffold(
      appBar: AppBar(
        title: const Text('قائمة الدخل'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () {},
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _buildSummaryCard(netProfit),
          const SizedBox(height: AppSpacing.xl),
          _buildSection('الإيرادات', revenues, totalRevenue, ColorTokens.positive),
          const SizedBox(height: AppSpacing.xl),
          _buildSection('المصروفات', expenses, totalExpenses, ColorTokens.negative),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(double netProfit) {
    final bool isProfit = netProfit >= 0;
    
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isProfit
              ? [ColorTokens.positive, ColorTokens.positive.withValues(alpha: 0.8)]
              : [ColorTokens.negative, ColorTokens.negative.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            isProfit ? 'صافي الربح' : 'صافي الخسارة',
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${netProfit.abs().toStringAsFixed(0)} ريال',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Map<String, dynamic>> items, double total, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              ...items.map((item) => ListTile(
                    title: Text(item['name']),
                    trailing: Text(
                      item['amount'].toStringAsFixed(0),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  )),
              const Divider(height: 1),
              ListTile(
                title: const Text('الإجمالي', style: TextStyle(fontWeight: FontWeight.bold)),
                trailing: Text(
                  '${total.toStringAsFixed(0)}',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
