import 'package:flutter/material.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/offline_banner.dart';
import '../../../smart_command/presentation/widgets/smart_command_sheet.dart';
import 'package:go_router/go_router.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('بقالة الأمل'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {},
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.workspace_premium, color: Colors.orange),
            onPressed: () {
              context.push('/checkout', extra: {'planCode': 'pro', 'planPrice': 15000.0});
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const OfflineBanner(isOffline: true), // Simulation for now
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  _buildDailyProfitCard(context),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryBox(
                          context,
                          title: 'الصندوق',
                          amount: '85,000',
                          icon: '💰',
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _buildSummaryBox(
                          context,
                          title: 'لي عند الناس',
                          amount: '120,000',
                          icon: '👥',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Text(
                    'أكثر العمليات استخداماً',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildQuickActionsGrid(context),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 0,
        selectedItemColor: ColorTokens.neutralInfo,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 1) context.push('/contacts');
          if (index == 2) context.push('/inventory');
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'الرئيسية'),
          BottomNavigationBarItem(icon: Icon(Icons.contacts), label: 'جهات'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'مخزن'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'تقارير'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'إعدادات'),
        ],
      ),
      // AI Command Bar Placeholder
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => SmartCommandSheet.show(context),
        icon: const Icon(Icons.mic),
        label: const Text('اكتب أو تكلّم...'),
        backgroundColor: ColorTokens.neutralInfo,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildDailyProfitCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ربحك اليوم',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: AppSpacing.unit),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '+12,500',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: ColorTokens.positive,
                    ),
              ),
              const SizedBox(width: AppSpacing.unit),
              Text(
                'ريال',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: ColorTokens.positive,
                    ),
              ),
              const Spacer(),
              const Icon(Icons.trending_up, color: ColorTokens.positive),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'المبيعات 45,000 · المصروف 3,500 · التكلفة 29,000',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBox(BuildContext context, {required String title, required String amount, required String icon}) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(title, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            amount,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    final actions = [
      {'label': 'بعت', 'icon': '🛒', 'color': ColorTokens.positive},
      {'label': 'اشتريت', 'icon': '💵', 'color': ColorTokens.negative},
      {'label': 'تحصيل', 'icon': '📥', 'color': ColorTokens.neutralInfo},
      {'label': 'سداد', 'icon': '📤', 'color': ColorTokens.warning},
      {'label': 'تالف', 'icon': '🗑️', 'color': Colors.grey},
      {'label': 'مصروف', 'icon': '🧾', 'color': Colors.deepOrange},
      {'label': 'المزيد', 'icon': '➕', 'color': Colors.grey.shade700},
      {'label': 'سجل', 'icon': '📋', 'color': Colors.blueGrey},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (context, index) {
        final action = actions[index];
        return InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: (action['color'] as Color).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(action['icon'] as String, style: const TextStyle(fontSize: 28)),
                const SizedBox(height: 4),
                Text(
                  action['label'] as String,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
