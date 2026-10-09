import 'package:flutter/material.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/app_spacing.dart';
import 'package:go_router/go_router.dart';

class OperationsHubScreen extends StatefulWidget {
  const OperationsHubScreen({super.key});

  @override
  State<OperationsHubScreen> createState() => _OperationsHubScreenState();
}

class _OperationsHubScreenState extends State<OperationsHubScreen> {
  String _searchQuery = '';

  final List<Map<String, dynamic>> _allOperations = [
    // Sales
    {
      'title': 'بيع نقدي',
      'category': 'المبيعات والعملاء',
      'icon': '🛒',
      'desc': 'استلام نقد فوري في الصندوق مقابل بضاعة',
      'color': ColorTokens.positive,
      'code': 'sale_cash',
    },
    {
      'title': 'بيع آجل (على الحساب)',
      'category': 'المبيعات والعملاء',
      'icon': '📋',
      'desc': 'تسجيل دين مستحق على العميل مع إضافة سريعة',
      'color': ColorTokens.positive,
      'code': 'sale_credit',
    },
    {
      'title': 'بيع جزئي (دفعة مقدمة)',
      'category': 'المبيعات والعملاء',
      'icon': '⚖️',
      'desc': 'استلام دفعة نقدية وتسجيل المتبقي كدين',
      'color': ColorTokens.positive,
      'code': 'sale_partial',
    },
    {
      'title': 'مرتجع مبيعات',
      'category': 'المبيعات والعملاء',
      'icon': '🔄',
      'desc': 'إرجاع بضاعة مباعة للعميل ورد النقد أو تخفيض دينه',
      'color': Colors.deepOrange,
      'code': 'sales_return',
    },
    // Purchases
    {
      'title': 'شراء نقدي',
      'category': 'المشتريات والموردين',
      'icon': '💵',
      'desc': 'شراء بضاعة ودفع قيمتها نقداً من الصندوق',
      'color': ColorTokens.negative,
      'code': 'purchase_cash',
    },
    {
      'title': 'شراء آجل',
      'category': 'المشتريات والموردين',
      'icon': '📦',
      'desc': 'شراء بضاعة بالآجل وصار للمورد دين علينا',
      'color': ColorTokens.negative,
      'code': 'purchase_credit',
    },
    {
      'title': 'شراء جزئي',
      'category': 'المشتريات والموردين',
      'icon': '💸',
      'desc': 'دفع جزء نقداً وتسجيل الباقي كدين للمورد',
      'color': ColorTokens.negative,
      'code': 'purchase_partial',
    },
    {
      'title': 'مرتجع مشتريات',
      'category': 'المشتريات والموردين',
      'icon': '↩️',
      'desc': 'إرجاع بضاعة لمورد واسترداد النقد أو خصم الحساب',
      'color': Colors.deepOrange,
      'code': 'purchase_return',
    },
    // Settlements
    {
      'title': 'تحصيل دين من عميل',
      'category': 'التحصيل والسداد',
      'icon': '📥',
      'desc': 'قبض دفعة من عميل لتخفيض حسابه',
      'color': ColorTokens.neutralInfo,
      'code': 'customer_collection',
    },
    {
      'title': 'سداد دفعة لمورد',
      'category': 'التحصيل والسداد',
      'icon': '📤',
      'desc': 'دفع مبلغ لمورد لتخفيض دينه',
      'color': ColorTokens.warning,
      'code': 'supplier_payment',
    },
    // Expenses
    {
      'title': 'مصروف يومي مباشر',
      'category': 'المصروفات والتكاليف',
      'icon': '🧾',
      'desc': 'أجور يومية، كهرباء، نظافة، نثريات (يخصم من ربح اليوم)',
      'color': Colors.amber.shade800,
      'code': 'expense_daily',
    },
    {
      'title': 'مصروف دوري (إيجار موزع)',
      'category': 'المصروفات والتكاليف',
      'icon': '📅',
      'desc': 'إيجار شهر يوزع على الأيام لحساب ربح اليوم بدقة',
      'color': Colors.deepOrange,
      'code': 'expense_period',
    },
    {
      'title': 'إثبات مصروف مستحق',
      'category': 'المصروفات والتكاليف',
      'icon': '⏳',
      'desc': 'تسجيل التزام مصروف لم يدفع بعد',
      'color': Colors.purple,
      'code': 'expense_accrued',
    },
    {
      'title': 'سداد مصروف مستحق',
      'category': 'المصروفات والتكاليف',
      'icon': '✅',
      'desc': 'دفع قيمة مصروف مستحق مسجل سابقاً',
      'color': ColorTokens.positive,
      'code': 'accrued_expense_payment',
    },
    // Damage & Inventory
    {
      'title': 'إتلاف بضاعة هالكة',
      'category': 'المخازن والتالف',
      'icon': '🗑️',
      'desc': 'إثبات هالك أو منتهي مع تحديد جهة التحمل (محل/مورد)',
      'color': Colors.brown,
      'code': 'inventory_damage',
    },
    {
      'title': 'تحويل بين المخازن',
      'category': 'المخازن والتالف',
      'icon': '🔁',
      'desc': 'نقل أصناف بين الفروع والمستودعات',
      'color': Colors.teal,
      'route': '/inventory/transfer',
    },
    // Owner & Capital
    {
      'title': 'إيداع رأس مال للمالك',
      'category': 'المالك والشركاء',
      'icon': '💼',
      'desc': 'ضخ سيولة نقدية في صندوق النشاط',
      'color': ColorTokens.positive,
      'code': 'owner_deposit',
    },
    {
      'title': 'مسحوبات شخصية للمالك',
      'category': 'المالك والشركاء',
      'icon': '👜',
      'desc': 'سحب مبالغ للاستخدام الشخصي خارج مصاريف المحل',
      'color': Colors.redAccent,
      'code': 'owner_withdrawal',
    },
    {
      'title': 'معالج الرصيد الافتتاحي',
      'category': 'المالك والشركاء',
      'icon': '⚖️',
      'desc': 'تسجيل الأرصدة الافتتاحية للمخازن والصناديق والديون',
      'color': Colors.deepPurple,
      'code': 'opening_balance_wizard',
    },
    // Services
    {
      'title': 'فتح أمر شغل / خدمة',
      'category': 'الخدمات وأوامر الشغل',
      'icon': '🛠️',
      'desc': 'تسجيل طلب صيانة أو خدمة جديدة لعميل',
      'color': Colors.blueGrey,
      'code': 'job_open',
    },
    {
      'title': 'أتعاب خدمة نقدية',
      'category': 'الخدمات وأوامر الشغل',
      'icon': '💵',
      'desc': 'تحصيل أتعاب استشارة أو صيانة نقداً',
      'color': ColorTokens.positive,
      'code': 'service_revenue_cash',
    },
    {
      'title': 'مصروف بالنيابة عن عميل',
      'category': 'الخدمات وأوامر الشغل',
      'icon': '📑',
      'desc': 'دفع رسوم حكومية أو قطع غيار بالنيابة واستردادها لاحقاً',
      'color': Colors.deepOrange,
      'code': 'job_expense_on_behalf',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filteredOps = _allOperations.where((op) {
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return (op['title'] as String).toLowerCase().contains(q) ||
          (op['desc'] as String).toLowerCase().contains(q) ||
          (op['category'] as String).toLowerCase().contains(q);
    }).toList();

    // Group by category
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var op in filteredOps) {
      final cat = op['category'] as String;
      grouped.putIfAbsent(cat, () => []).add(op);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('دليل العمليات المحاسبية الشامل'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'ابحث عن عملية (بيع، شراء، إيجار، سداد، تالف...)...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                children: grouped.entries.map((entry) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          entry.key,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: ColorTokens.neutralInfo,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      ...entry.value.map((op) => Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: ListTile(
                              leading: Text(op['icon'] as String, style: const TextStyle(fontSize: 26)),
                              title: Text(op['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              subtitle: Text(op['desc'] as String, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                              onTap: () {
                                if (op.containsKey('route')) {
                                  context.push(op['route'] as String);
                                } else {
                                  context.push('/operations/form', extra: {'templateCode': op['code']});
                                }
                              },
                            ),
                          )),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
