import 'package:flutter/material.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/offline_banner.dart';
import '../../../smart_command/presentation/widgets/smart_command_sheet.dart';
import '../../../operations/presentation/widgets/quick_operation_picker.dart';
import 'package:go_router/go_router.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildAppDrawer(context),
      appBar: AppBar(
        title: const Text('بقالة الأمل'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.point_of_sale, color: ColorTokens.positive),
            tooltip: 'نقطة البيع (POS)',
            onPressed: () => context.push('/pos'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'الإعدادات',
            onPressed: () => context.push('/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.workspace_premium, color: Colors.orange),
            tooltip: 'الباقة والترقية',
            onPressed: () {
              context.push('/checkout', extra: {'planCode': 'pro', 'planPrice': 15000.0});
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const OfflineBanner(isOffline: true),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'العمليات السريعة',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      TextButton.icon(
                        onPressed: () => context.push('/operations'),
                        icon: const Icon(Icons.apps, size: 18),
                        label: const Text('كافة العمليات (20+)'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildQuickActionsGrid(context),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentNavIndex,
        selectedItemColor: ColorTokens.neutralInfo,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() => _currentNavIndex = index);
          if (index == 0) {
            // Already on Dashboard
          } else if (index == 1) {
            context.push('/contacts');
          } else if (index == 2) {
            context.push('/inventory');
          } else if (index == 3) {
            context.push('/reports');
          } else if (index == 4) {
            context.push('/settings');
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'الرئيسية'),
          BottomNavigationBarItem(icon: Icon(Icons.contacts), label: 'جهات'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'مخزن'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'تقارير'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'إعدادات'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => SmartCommandSheet.show(context),
        icon: const Icon(Icons.mic),
        label: const Text('اكتب أو تكلّم... (أمر ذكي)'),
        backgroundColor: ColorTokens.neutralInfo,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildAppDrawer(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              color: ColorTokens.neutralInfo.withValues(alpha: 0.08),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: ColorTokens.neutralInfo,
                        foregroundColor: Colors.white,
                        child: const Text('👑', style: TextStyle(fontSize: 20)),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('بقالة الأمل', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('أبو صالح (التاجر المالك)', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: const Text(
                      '🟢 نمط العمل دون اتصال (Local-First جاهز)',
                      style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ListTile(
                    leading: const Icon(Icons.home, color: ColorTokens.neutralInfo),
                    title: const Text('الرئيسية'),
                    onTap: () => Navigator.pop(context),
                  ),
                  ListTile(
                    leading: const Icon(Icons.point_of_sale, color: ColorTokens.positive),
                    title: const Text('نقطة البيع السريعة (POS)'),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/pos');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.apps, color: Colors.indigo),
                    title: const Text('دليل كافة العمليات (20+ عملية)'),
                    subtitle: const Text('بيع، شراء، تحصيل، سداد، تالف، مصروفات...'),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/operations');
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.contacts, color: ColorTokens.neutralInfo),
                    title: const Text('دليل جهات الاتصال'),
                    subtitle: const Text('عملاء، موردون، موظفون'),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/contacts');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.inventory_2, color: Colors.teal),
                    title: const Text('إدارة المخزون والأصناف'),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/inventory');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.warehouse, color: Colors.deepOrange),
                    title: const Text('الفروع والمستودعات والتحويلات'),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/inventory/warehouses');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.credit_card, color: Colors.deepPurple),
                    title: const Text('إدارة الشيكات البنكية'),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/checks');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.currency_exchange, color: Colors.teal),
                    title: const Text('العملات وأسعار الصرف'),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/currencies');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.bar_chart, color: ColorTokens.positive),
                    title: const Text('التقارير المالية وقائمة الدخل'),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/reports');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.api, color: Colors.blueGrey),
                    title: const Text('مفاتيح الربط الخارجي API'),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/api-keys');
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.settings, color: Colors.grey),
                    title: const Text('الإعدادات والصلاحيات والذكاء الاصطناعي'),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/settings');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
      {
        'label': 'بعت',
        'icon': '🛒',
        'color': ColorTokens.positive,
        'action': () => QuickOperationPicker.show(context, category: 'sale'),
      },
      {
        'label': 'اشتريت',
        'icon': '💵',
        'color': ColorTokens.negative,
        'action': () => QuickOperationPicker.show(context, category: 'purchase'),
      },
      {
        'label': 'تحصيل',
        'icon': '📥',
        'color': ColorTokens.neutralInfo,
        'action': () => QuickOperationPicker.show(context, category: 'settlement'),
      },
      {
        'label': 'سداد',
        'icon': '📤',
        'color': ColorTokens.warning,
        'action': () => QuickOperationPicker.show(context, category: 'settlement'),
      },
      {
        'label': 'تالف',
        'icon': '🗑️',
        'color': Colors.brown,
        'action': () => QuickOperationPicker.show(context, category: 'damage'),
      },
      {
        'label': 'مصروف',
        'icon': '🧾',
        'color': Colors.deepOrange,
        'action': () => QuickOperationPicker.show(context, category: 'expense'),
      },
      {
        'label': 'شيكات',
        'icon': '💳',
        'color': Colors.deepPurple,
        'action': () => context.push('/checks'),
      },
      {
        'label': 'العملات',
        'icon': '💱',
        'color': Colors.teal,
        'action': () => context.push('/currencies'),
      },
      {
        'label': 'المالك',
        'icon': '💼',
        'color': Colors.blueGrey,
        'action': () => QuickOperationPicker.show(context, category: 'owner'),
      },
      {
        'label': 'المزيد ➕',
        'icon': '📋',
        'color': Colors.indigo,
        'action': () => context.push('/operations'),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: AppSpacing.xs,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: 0.82,
      ),
      itemBuilder: (context, index) {
        final action = actions[index];
        return InkWell(
          onTap: action['action'] as VoidCallback,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: (action['color'] as Color).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(action['icon'] as String, style: const TextStyle(fontSize: 24)),
                const SizedBox(height: 4),
                Text(
                  action['label'] as String,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
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
